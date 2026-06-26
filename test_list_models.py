from google import genai
import os

MY_API_KEY = "AIzaSyBL2WKoeXQG_Bi3Nrnik0enGr3mBVIqvqY"

try:
    client = genai.Client(api_key=MY_API_KEY)
    print("Modeller listeleniyor...")
    print("Methods:", dir(client.models))
    # Trying .list() just in case
    for model in client.models.list():
        print(f"Model: {model.name}")
except Exception as e:
    print("HATA:", e)
