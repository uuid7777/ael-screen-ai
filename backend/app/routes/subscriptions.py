"""Subscription routes."""

from fastapi import APIRouter, Depends, HTTPException, Header
from app.models.subscription import SubscriptionCreate, SubscriptionStatusResponse
from app.models.request_response import StandardResponse
from app.services.auth_service import get_current_user
from app.services import subscription_service

router = APIRouter(prefix="/subscriptions", tags=["Subscriptions"])


async def _require_user(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    user = await get_current_user(token)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    return user


@router.get("/status", response_model=StandardResponse)
async def get_status(user=Depends(_require_user)):
    """Get current subscription status."""
    status = await subscription_service.get_subscription_status(user.id)
    return StandardResponse(success=True, data=status.model_dump())


@router.post("/create", response_model=StandardResponse)
async def create_subscription(body: SubscriptionCreate, user=Depends(_require_user)):
    """Create a subscription (typically called by payment webhook)."""
    body.user_id = user.id
    sub = await subscription_service.create_subscription(body)
    if not sub:
        raise HTTPException(status_code=500, detail="Failed to create subscription")
    return StandardResponse(success=True, message="Subscription created", data=sub.model_dump())


@router.post("/cancel", response_model=StandardResponse)
async def cancel_subscription(user=Depends(_require_user)):
    """Cancel subscription auto-renewal."""
    result = await subscription_service.cancel_subscription(user.id)
    return StandardResponse(success=True, message="Subscription cancelled" if result else "No active subscription")


@router.post("/webhook", response_model=StandardResponse)
async def payment_webhook(body: dict):
    """Handle payment provider webhook (Apple / Google)."""
    # Parse webhook payload based on provider
    provider = body.get("provider", "unknown")
    event_type = body.get("type", "")

    if event_type == "INITIAL_BUY" or event_type == "RENEWAL":
        user_id = body.get("user_id", "")
        plan_type = body.get("plan_type", "monthly")
        sub = await subscription_service.create_subscription(
            SubscriptionCreate(user_id=user_id, plan_type=plan_type, payment_provider=provider)
        )
        if sub:
            return StandardResponse(success=True, message="Subscription activated")

    elif event_type == "CANCELLATION":
        user_id = body.get("user_id", "")
        await subscription_service.cancel_subscription(user_id)
        return StandardResponse(success=True, message="Subscription cancelled")

    return StandardResponse(success=False, message="Unhandled event type")
