import requests
import json

API_KEY = "AIzaSyBL2WKoeXQG_Bi3Nrnik0enGr3mBVIqvqY"
URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={API_KEY}"

headers = {"Content-Type": "application/json"}
data = {
    "contents": [{
        "parts": [{"text": "Hello"}]
    }]
}

try:
    response = requests.post(URL, headers=headers, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
