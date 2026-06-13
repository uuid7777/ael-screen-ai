from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class SubscriptionCreate(BaseModel):
    """Create a subscription (called by payment webhook)."""
    user_id: str
    plan_type: str = "monthly"  # monthly, yearly
    payment_provider: str = "apple"  # apple, google
    receipt_data: Optional[str] = None


class SubscriptionResponse(BaseModel):
    id: str
    user_id: str
    plan_type: str
    status: str  # active, expired, cancelled
    start_date: datetime
    end_date: datetime
    auto_renew: bool = True
    payment_provider: str

    class Config:
        from_attributes = True


class SubscriptionStatusResponse(BaseModel):
    is_premium: bool = False
    subscription: Optional[SubscriptionResponse] = None
    trial_available: bool = True
    trial_days_remaining: int = 0
