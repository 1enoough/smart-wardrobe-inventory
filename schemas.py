# kombin_backend/schemas.py
from pydantic import BaseModel
from typing import List, Optional

class ClothesCreate(BaseModel):
    category: str
    season: str
    formality: str
    
    class Config:
        from_attributes = True

class Clothes(ClothesCreate):
    id: int
    filename: str
    dominant_color: Optional[str] 
    
    class Config:
        from_attributes = True