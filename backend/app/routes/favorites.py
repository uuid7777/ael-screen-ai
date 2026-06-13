"""Favorites routes."""

from fastapi import APIRouter, Depends, HTTPException, Header, Query
from app.models.favorite import FavoriteCreate, FavoriteResponse, FavoriteListResponse
from app.models.request_response import StandardResponse
from app.services.auth_service import get_current_user
from app.database import get_supabase

router = APIRouter(prefix="/favorites", tags=["Favorites"])


async def _require_user(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    user = await get_current_user(token)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    return user


@router.get("/", response_model=FavoriteListResponse)
async def get_favorites(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user=Depends(_require_user),
):
    """Get user's favorite translations."""
    client = get_supabase()
    offset = (page - 1) * page_size

    resp = client.table("favorites") \
        .select("*, translations(*)") \
        .eq("user_id", user.id) \
        .order("created_at", desc=True) \
        .range(offset, offset + page_size - 1) \
        .execute()

    items = []
    for fav in (resp.data or []):
        t = fav.get("translations", {}) or {}
        items.append(FavoriteResponse(
            id=fav["id"],
            user_id=fav["user_id"],
            translation_id=fav["translation_id"],
            original_text=t.get("original_text", ""),
            translated_text=t.get("translated_text", ""),
            source_lang=t.get("source_lang", ""),
            target_lang=t.get("target_lang", ""),
            note=fav.get("note"),
            created_at=fav.get("created_at"),
        ))

    total = len(items)
    return FavoriteListResponse(
        data=items,
        total=total,
        page=page,
        page_size=page_size,
        has_more=(offset + page_size) < total,
    )


@router.post("/", response_model=StandardResponse)
async def add_favorite(body: FavoriteCreate, user=Depends(_require_user)):
    """Add a translation to favorites."""
    try:
        client = get_supabase()
        resp = client.table("favorites").insert({
            "user_id": user.id,
            "translation_id": body.translation_id,
            "note": body.note,
        }).execute()
        return StandardResponse(success=True, message="Added to favorites", data=resp.data[0] if resp.data else None)
    except Exception as e:
        if "duplicate" in str(e).lower():
            raise HTTPException(status_code=409, detail="Already in favorites")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{favorite_id}", response_model=StandardResponse)
async def remove_favorite(favorite_id: str, user=Depends(_require_user)):
    """Remove a favorite."""
    client = get_supabase()
    client.table("favorites") \
        .delete() \
        .eq("id", favorite_id) \
        .eq("user_id", user.id) \
        .execute()
    return StandardResponse(success=True, message="Removed from favorites")


@router.delete("/by-translation/{translation_id}", response_model=StandardResponse)
async def remove_favorite_by_translation(translation_id: str, user=Depends(_require_user)):
    """Remove a favorite by translation ID."""
    client = get_supabase()
    client.table("favorites") \
        .delete() \
        .eq("translation_id", translation_id) \
        .eq("user_id", user.id) \
        .execute()
    return StandardResponse(success=True, message="Removed from favorites")
