"""AI translation service using Alibaba Cloud (Tongyi Qianwen) API."""

import time
from typing import Optional
import httpx
from app.config import settings


QWEN_API_URL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"


async def translate_text(
    text: str,
    source_lang: str = "auto",
    target_lang: str = "zh-CN",
) -> tuple[str, str, int]:
    """
    Translate text using Tongyi Qianwen (通义千问) API.
    Returns (translated_text, detected_source_lang, processing_time_ms).
    """
    start = time.time()

    lang_map = {
        "zh-CN": "Chinese",
        "en": "English",
        "ja": "Japanese",
        "ko": "Korean",
        "fr": "French",
        "de": "German",
        "es": "Spanish",
        "pt": "Portuguese",
        "ru": "Russian",
        "th": "Thai",
        "vi": "Vietnamese",
        "ar": "Arabic",
        "auto": "auto-detect",
    }

    source_name = lang_map.get(source_lang, source_lang)
    target_name = lang_map.get(target_lang, target_lang)

    if source_lang == "auto":
        prompt = (
            f"Please translate the following text to {target_name}. "
            f"First detect the source language, then provide the translation. "
            f"Respond in format:\n[detected_language]: <language>\n[translation]: <translated text>\n\n"
            f"Text: {text}"
        )
    else:
        prompt = (
            f"Please translate the following text from {source_name} to {target_name}. "
            f"Respond in format:\n[detected_language]: {source_name}\n[translation]: <translated text>\n\n"
            f"Text: {text}"
        )

    headers = {
        "Authorization": f"Bearer {settings.dashscope_api_key}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": settings.qwen_model,
        "messages": [
            {"role": "system", "content": "You are a professional translator. Translate accurately and naturally."},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.3,
        "max_tokens": 4096,
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.post(QWEN_API_URL, json=payload, headers=headers)
        resp.raise_for_status()
        result = resp.json()

    elapsed = int((time.time() - start) * 1000)

    content = result["choices"][0]["message"]["content"]

    # Parse response
    detected_lang = source_lang if source_lang != "auto" else "unknown"
    translated = content

    for line in content.split("\n"):
        line = line.strip()
        if line.startswith("[detected_language]:"):
            detected_lang = line.split(":", 1)[1].strip()
        elif line.startswith("[translation]:"):
            translated = line.split(":", 1)[1].strip()

    return translated, detected_lang, elapsed


async def translate_batch(
    texts: list[str],
    source_lang: str = "auto",
    target_lang: str = "zh-CN",
) -> list[dict]:
    """Translate multiple texts in one API call."""
    combined = "\n---\n".join(texts)
    translated, detected, elapsed = await translate_text(combined, source_lang, target_lang)
    parts = translated.split("\n---\n")
    results = []
    for i, part in enumerate(parts):
        results.append({
            "index": i,
            "original": texts[i] if i < len(texts) else "",
            "translated": part.strip(),
            "source_lang": detected,
        })
    return results
