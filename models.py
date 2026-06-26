# kombin_backend/models.py
from sqlalchemy import Column, Integer, String
# Mutlak import: database dosyasını çağırır
from kombin_backend.database import Base 

# Kıyafet Veritabanı Modeli
class Clothes(Base):
    __tablename__ = "clothes"

    id = Column(Integer, primary_key=True, index=True)
    
    filename = Column(String, unique=True, index=True, nullable=False) 
    dominant_color = Column(String, nullable=True) 
    
    category = Column(String, default="T-shirt")
    season = Column(String, default="Yaz")      
    formality = Column(String, default="Günlük") 
    
    def __repr__(self):
        return f"<Clothes(filename='{self.filename}', category='{self.category}')>"