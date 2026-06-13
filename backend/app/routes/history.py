"""Translation history routes."""

from fastapi import APIRouter, Depends, HTTPException, Header, Query
from app.models.translation import HistoryItem, HistoryListResponse
from app.models.request_response import StandardResponse
from app.services.auth_service import get_current_user
from app.database import get_supabase

router = APIRouter(prefix="/history", tags=["History"])


async def _require_user(authorization: str = Header(...)):
    """Dependency to require authentication."""
    token = authorization.replace("Bearer ", "")
    user = await get_current_user(token)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    return user


@router.get("/", response_model=HistoryListResponse)
async def get_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user=Depends(_require_user),
):
    """Get translation history."""
    client = get_supabase()
    offset = (page - 1) * page_size

    resp = client.table("translations") \
        .select("*", count="exact") \
        .eq("user_id", user.id) \
        .order("created_at", desc=True) \
        .range(offset, offset + page_size - 1) \
        .execute()

    items = [HistoryItem(**item) for item in (resp.data or [])]
    total = resp.count if hasattr(resp, 'count') else len(items)

    return HistoryListResponse(
        data=items,
        total=total,
        page=page,
        page_size=page_size,
        has_more=(offset + page_size) < total,
    )


@router.delete("/{translation_id}", response_model=StandardResponse)
async def delete_history_item(translation_id: str, user=Depends(_require_user)):
    """Delete a history item."""
    client = get_supabase()
    client.table("translations") \
        .delete() \
        .eq("id", translation_id) \
        .eq("user_id", user.id) \
        .execute()
    return StandardResponse(success=True, message="Deleted")


@router.delete("/", response_model=StandardResponse)
async def clear_history(user=Depends(_require_user)):
    """Clear all translation history."""
    client = get_supabase()
    client.table("translations") \
        .delete() \
        .eq("user_id", user.id) \
        .execute()
    return StandardResponse(success=True, message="History cleared")
