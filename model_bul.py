from google import genai

MY_API_KEY = "AIzaSyBL2WKoeXQG_Bi3Nrnik0enGr3mBVIqvqY"

try:
    client = genai.Client(api_key=MY_API_KEY)
    print("--- SENİN İÇİN AÇIK OLAN MODELLER ---")
    
    # Hiçbir filtre yapmadan direkt isimleri basıyoruz
    for m in client.models.list():
        print(f"- {m.name}")
            
    print("-------------------------------------")

except Exception as e:
    print(f"Hata: {e}")