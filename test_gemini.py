import os
import google.generativeai as genai

# Kullanıcının app.py dosyasındaki key'i buraya kopyalıyorum (amaç test etmek)
MY_API_KEY = "AIzaSyBL2WKoeXQG_Bi3Nrnik0enGr3mBVIqvqY"

print(f"Key uzunluğu: {len(MY_API_KEY)}")
print(f"Key repr: {repr(MY_API_KEY)}")

try:
    genai.configure(api_key=MY_API_KEY)
    model = genai.GenerativeModel("models/gemini-1.5-flash")
    response = model.generate_content("Merhaba, test.")
    print("Başarılı! Cevap:", response.text)
except Exception as e:
    print("HATA OLUŞTU:")
    print(e)
