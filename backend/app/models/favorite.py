from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class FavoriteCreate(BaseModel):
    translation_id: str
    note: Optional[str] = None


class FavoriteResponse(BaseModel):
    id: str
    user_id: str
    translation_id: str
    original_text: str
    translated_text: str
    source_lang: str
    target_lang: str
    note: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class FavoriteListResponse(BaseModel):
    success: bool = True
    data: list[FavoriteResponse] = []
    total: int = 0
    page: int = 1
    page_size: int = 20
    has_more: bool = False
