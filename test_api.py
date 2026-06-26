# test_api.py
import os
from google import genai
from google.genai import types

# Senin anahtarın
MY_API_KEY = "AIzaSyBL2WKoeXQG_Bi3Nrnik0enGr3mBVIqvqY"

def test_gemini():
    print("1. Bağlantı kuruluyor...")
    try:
        client = genai.Client(api_key=MY_API_KEY)
        print("✅ İstemci oluşturuldu.")
    except Exception as e:
        print(f"❌ İstemci Hatası: {e}")
        return

    print("\n2. Basit metin testi yapılıyor...")
    try:
        response = client.models.generate_content(
            model='gemini-1.5-flash',
            contents='Bana sadece "Merhaba Dünya" yaz.'
        )
        print(f"✅ AI Cevabı: {response.text}")
    except Exception as e:
        print(f"❌ Test Başarısız: {e}")
        print("Olası sebepler: API Anahtarı yanlış, Fatura hesabı gerekli veya Model ismi hatalı.")

if __name__ == "__main__":
    test_gemini()