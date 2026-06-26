import os
import uuid
import io
import time
import json
import numpy as np
import re

from typing import List, Annotated
from fastapi import FastAPI, UploadFile, File, Depends, Form
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from PIL import Image

from sklearn.cluster import KMeans
from rembg import remove

from kombin_backend import models, database, schemas

# ================== GEMINI ==================
from google import genai
import google.genai.types

MY_API_KEY = "AIzaSyDsDrs9zw776Xu5aa7qxojVC0b4BQbUFPU"
client = genai.Client(api_key=MY_API_KEY)

MODEL_NAME = "gemini-2.5-flash-lite"
# ============================================

# --- APP ---
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.mount("/static", StaticFiles(directory=UPLOAD_FOLDER), name="static")

database.Base.metadata.create_all(bind=database.engine)

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ---------- RENK ----------
def get_dominant_color_kmeans(image: Image.Image) -> str:
    image = image.resize((150, 150)).convert("RGBA")
    data = np.array(image)
    pixels = data.reshape(-1, 4)
    pixels = pixels[pixels[:, 3] > 50][:, :3]

    if len(pixels) == 0:
        return "[128, 128, 128]"

    kmeans = KMeans(n_clusters=1, n_init=10)
    kmeans.fit(pixels)
    color = kmeans.cluster_centers_[0]
    return str([int(c) for c in color])

# ---------- ROOT ----------
@app.get("/")
def root():
    return {"status": "API çalışıyor"}

# ---------- UPLOAD ----------
@app.post("/upload_clothes/")
async def upload_clothes(
    category: Annotated[str, Form()] = "Otomatik",
    season: Annotated[str, Form()] = "Otomatik",
    formality: Annotated[str, Form()] = "Otomatik",
    files: List[UploadFile] = File(...),
    db: Session = Depends(get_db),
):
    last_color = "[128, 128, 128]"
    last_category = category
    last_season = season
    last_formality = formality

    # model = genai.GenerativeModel(MODEL_NAME) -> Eski SDK, gerek yok artık

    for file in files:
        filename = f"{uuid.uuid4()}.png"
        path = os.path.join(UPLOAD_FOLDER, filename)

        contents = await file.read()
        image = Image.open(io.BytesIO(contents))

        # --- Background Remove ---
        no_bg = remove(image).convert("RGBA")
        no_bg.save(path)

        last_color = get_dominant_color_kmeans(no_bg)

        # --- GEMINI ---
        prompt = """
        Bu kıyafeti analiz et ve SADECE JSON döndür.

        {
          "kategori": "Tişört | Gömlek | Pantolon | Ayakkabı",
          "mevsim": "Yaz | Kış | Dört Mevsim",
          "resmiyet": "Günlük | Spor | İş"
        }
        """

        # Retry logic: 3 deneme
        max_retries = 3
        for attempt in range(max_retries):
            try:
                response = client.models.generate_content(
                    model=MODEL_NAME,
                    contents=[prompt, no_bg]
                )
                text = response.text

                match = re.search(r"\{.*\}", text, re.DOTALL)
                if match:
                    data = json.loads(match.group())
                    last_category = data.get("kategori", category)
                    last_season = data.get("mevsim", season)
                    last_formality = data.get("resmiyet", formality)
                
                # Başarılı olduysa döngüyü kır
                break
            
            except Exception as e:
                # Eğer "429" hatasıysa (Resource Exhausted) bekle ve tekrar dene
                err_str = str(e)
                if "429" in err_str or "RESOURCE_EXHAUSTED" in err_str:
                    print(f"⚠️ Kota dolu ({attempt+1}/{max_retries}). 5 saniye bekleniyor...")
                    time.sleep(5)
                else:
                    print("❌ Gemini Hatası:", e)
                    break 

        db.add(models.Clothes(
            filename=filename,
            dominant_color=last_color,
            category=last_category,
            season=last_season,
            formality=last_formality
        ))
        db.commit()

    return JSONResponse({
        "status": "success",
        "detected_color": last_color,
        "detected_category": last_category,
        "detected_season": last_season,
        "detected_formality": last_formality,
    })

# ---------- LIST ----------
@app.get("/images_colors/", response_model=List[schemas.Clothes])
def images_colors(db: Session = Depends(get_db)):
    return db.query(models.Clothes).all()


# ---------- DELETE ----------
@app.delete("/delete_clothes/{item_id}")
def delete_clothes(item_id: int, db: Session = Depends(get_db)):
    item = db.query(models.Clothes).filter(models.Clothes.id == item_id).first()
    if item:
        try:
            os.remove(os.path.join(UPLOAD_FOLDER, item.filename))
        except:
            pass
        db.delete(item)
        db.commit()
    return {"message": "Silindi"}
