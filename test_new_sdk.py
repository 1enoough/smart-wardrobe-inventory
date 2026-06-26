from google import genai
import os

MY_API_KEY = "AIzaSyBL2WKoeXQG_Bi3Nrnik0enGr3mBVIqvqY"

try:
    client = genai.Client(api_key=MY_API_KEY)
    response = client.models.generate_content(
        model="gemini-1.5-flash",
        contents="Merhaba, bu yeni SDK testi."
    )
    print("Başarılı! Cevap:", response.text)
except Exception as e:
    print("HATA OLUŞTU:", e)
