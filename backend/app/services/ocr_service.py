"""OCR service - processes images and extracts text."""

import base64
import io
from typing import Optional
from PIL import Image
from app.models.translation import OCRResult


async def process_ocr(image_base64: str) -> OCRResult:
    """
    Process OCR on a base64-encoded image.
    For now this is a server-side placeholder.
    The actual OCR runs on-device (Flutter ML Kit).
    If server-side OCR is needed later, integrate with:
      - Alibaba Cloud OCR API
      - PaddleOCR (self-hosted)
    """
    # Validate image
    try:
        image_data = base64.b64decode(image_base64)
        img = Image.open(io.BytesIO(image_data))
        w, h = img.size
    except Exception:
        return OCRResult(
            raw_text="",
            detected_language=None,
            confidence=0.0,
            blocks=[],
        )

    # Placeholder: On-device OCR is preferred.
    # Server-side OCR can be added by the user later.
    return OCRResult(
        raw_text="",
        detected_language=None,
        confidence=0.0,
        blocks=[{"x": 0, "y": 0, "w": w, "h": h, "text": "(on-device OCR)"}],
    )


async def process_ocr_sync(image_bytes: bytes) -> str:
    """Simple sync wrapper for OCR processing."""
    img = Image.open(io.BytesIO(image_bytes))
    return f"Image received: {img.size[0]}x{img.size[1]}, {len(image_bytes)} bytes"


def validate_image(image_base64: str) -> Optional[dict]:
    """Validate a base64 image and return metadata."""
    try:
        image_data = base64.b64decode(image_base64)
        img = Image.open(io.BytesIO(image_data))
        return {
            "valid": True,
            "width": img.size[0],
            "height": img.size[1],
            "format": img.format,
            "size_bytes": len(image_data),
        }
    except Exception as e:
        return {"valid": False, "error": str(e)}
