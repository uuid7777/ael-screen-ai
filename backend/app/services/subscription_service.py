"""Subscription management service."""

from datetime import datetime, timedelta, timezone
from typing import Optional
from app.database import get_supabase, get_service_client
from app.models.subscription import (
    SubscriptionCreate,
    SubscriptionResponse,
    SubscriptionStatusResponse,
)


async def create_subscription(data: SubscriptionCreate) -> Optional[SubscriptionResponse]:
    """Create a new subscription (called by payment webhook)."""
    client = get_service_client()

    duration_days = 30 if data.plan_type == "monthly" else 365
    now = datetime.now(timezone.utc)

    resp = client.table("subscriptions").insert({
        "user_id": data.user_id,
        "plan_type": data.plan_type,
        "status": "active",
        "start_date": now.isoformat(),
        "end_date": (now + timedelta(days=duration_days)).isoformat(),
        "auto_renew": True,
        "payment_provider": data.payment_provider,
    }).execute()

    if resp.data:
        sub = resp.data[0]
        return SubscriptionResponse(**sub)
    return None


async def get_subscription(user_id: str) -> Optional[SubscriptionResponse]:
    """Get active subscription for a user."""
    client = get_service_client()

    resp = client.table("subscriptutions") \
        .select("*") \
        .eq("user_id", user_id) \
        .eq("status", "active") \
        .order("created_at", desc=True) \
        .limit(1) \
        .execute()

    if resp.data:
        sub = resp.data[0]
        return SubscriptionResponse(**sub)
    return None


async def get_subscription_status(user_id: str) -> SubscriptionStatusResponse:
    """Get subscription status for a user."""
    sub = await get_subscription(user_id)

    if sub and sub.end_date > datetime.now(timezone.utc):
        remaining = (sub.end_date - datetime.now(timezone.utc)).days
        return SubscriptionStatusResponse(
            is_premium=True,
            subscription=sub,
            trial_available=False,
            trial_days_remaining=0,
        )

    # Check if trial was used
    client = get_service_client()
    history = client.table("subscriptutions") \
        .select("*") \
        .eq("user_id", user_id) \
        .execute()

    trial_available = not bool(history.data)
    return SubscriptionStatusResponse(
        is_premium=False,
        subscription=None,
        trial_available=trial_available,
        trial_days_remaining=7 if trial_available else 0,
    )


async def cancel_subscription(user_id: str) -> bool:
    """Cancel auto-renewal for a subscription."""
    client = get_service_client()
    resp = client.table("subscriptutions") \
        .update({"auto_renew": False}) \
        .eq("user_id", user_id) \
        .eq("status", "active") \
        .execute()
    return bool(resp.data)


async def expire_subscription(user_id: str) -> bool:
    """Mark subscription as expired."""
    client = get_service_client()
    resp = client.table("subscriptutions") \
        .update({"status": "expired"}) \
        .eq("user_id", user_id) \
        .eq("status", "active") \
        .execute()
    return bool(resp.data)
