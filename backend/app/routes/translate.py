"""Translation and OCR routes."""

import time
from fastapi import APIRouter, Depends, HTTPException, Header
from app.models.translation import (
    TranslationRequest, TranslateResponse,
    OCRRequest, OCRResult,
)
from app.models.request_response import StandardResponse
from app.services.translate_service import translate_text
from app.services.ocr_service import process_ocr
from app.services.auth_service import get_current_user
from app.database import get_supabase

router = APIRouter(prefix="/translate", tags=["Translation"])


@router.post("/", response_model=StandardResponse)
async def translate(body: TranslationRequest, authorization: str = Header("")):
    """Translate text from one language to another."""
    try:
        translated, detected_lang, elapsed = await translate_text(
            body.text, body.source_lang, body.target_lang
        )
        result = TranslateResponse(
            original_text=body.text,
            translated_text=translated,
            source_lang=detected_lang,
            target_lang=body.target_lang,
            ocr_used=False,
            processing_time_ms=elapsed,
        )
        # Save to history if user is authenticated
        token = authorization.replace("Bearer ", "")
        user = await get_current_user(token) if authorization else None
        if user:
            try:
                client = get_supabase()
                client.table("translations").insert({
                    "user_id": user.id,
                    "original_text": body.text,
                    "translated_text": translated,
                    "source_lang": detected_lang,
                    "target_lang": body.target_lang,
                    "ocr_used": False,
                    "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                }).execute()
            except Exception:
                pass
        return StandardResponse(success=True, data=result.model_dump())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Translation failed: {str(e)}")


@router.post("/ocr", response_model=StandardResponse)
async def ocr(body: OCRRequest, authorization: str = Header("")):
    """Process OCR on an image (optional server-side fallback)."""
    try:
        result = await process_ocr(body.image_base64)
        return StandardResponse(success=True, data=result.model_dump())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR failed: {str(e)}")


@router.post("/screen", response_model=StandardResponse)
async def translate_screen(body: OCRRequest, authorization: str = Header("")):
    """Full pipeline: OCR image -> translate text."""
    try:
        ocr_result = await process_ocr(body.image_base64)
        text = body.text or ocr_result.raw_text
        if not text:
            return StandardResponse(
                success=False,
                message="No text detected in the image. OCR should run on-device via ML Kit.",
                data={"ocr_empty": True},
            )
        translated, detected_lang, elapsed = await translate_text(text)
        result = TranslateResponse(
            original_text=text,
            translated_text=translated,
            source_lang=detected_lang,
            target_lang="zh-CN",
            ocr_used=True,
            processing_time_ms=elapsed,
        )
        return StandardResponse(success=True, data=result.model_dump())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Screen translation failed: {str(e)}")
