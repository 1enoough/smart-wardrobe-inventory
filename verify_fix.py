from google import genai
from PIL import Image
import os

MY_API_KEY = "AIzaSyBL2WKoeXQG_Bi3Nrnik0enGr3mBVIqvqY"
client = genai.Client(api_key=MY_API_KEY)
MODEL_NAME = "models/gemini-1.5-flash"

try:
    path = os.path.join("uploads", "kiyafett.jpg")
    image = Image.open(path)
    
    prompt = """
    Bu kıyafeti analiz et ve SADECE JSON döndür.
    {
      "kategori": "Tişört | Gömlek | Pantolon | Ayakkabı",
      "mevsim": "Yaz | Kış | Dört Mevsim",
      "resmiyet": "Günlük | Spor | İş"
    }
    """
    
    print("İstek gönderiliyor...")
    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=[prompt, image]
    )
    print("Başarılı!")
    print("Cevap:", response.text)

except Exception as e:
    print("HATA:", e)
