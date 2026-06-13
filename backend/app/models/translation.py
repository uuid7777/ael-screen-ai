from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class TranslationRequest(BaseModel):
    """Request body for translation."""
    text: str
    source_lang: str = "auto"
    target_lang: str = "zh-CN"


class OCRRequest(BaseModel):
    """Request body for OCR processing."""
    image_base64: str
    # Optional: if user wants to skip OCR and send text directly
    text: Optional[str] = None


class OCRResult(BaseModel):
    """OCRed text from image."""
    raw_text: str
    detected_language: Optional[str] = None
    confidence: float = 0.0
    blocks: list = []


class TranslateResponse(BaseModel):
    """Translation result."""
    original_text: str
    translated_text: str
    source_lang: str
    target_lang: str
    ocr_used: bool = False
    processing_time_ms: int = 0


class HistoryItem(BaseModel):
    """A single translation history entry."""
    id: str
    user_id: str
    original_text: str
    translated_text: str
    source_lang: str
    target_lang: str
    ocr_used: bool = False
    screenshot_url: Optional[str] = None
    is_favorite: bool = False
    created_at: datetime

    class Config:
        from_attributes = True


class HistoryListResponse(BaseModel):
    """Paginated history list."""
    success: bool = True
    data: list[HistoryItem] = []
    total: int = 0
    page: int = 1
    page_size: int = 20
    has_more: bool = False
