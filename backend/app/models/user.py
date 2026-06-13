from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    email: str
    password: str
    display_name: Optional[str] = None


class UserLogin(BaseModel):
    email: str
    password: str


class AppleLoginRequest(BaseModel):
    identity_token: str
    authorization_code: str
    user_id: str
    email: Optional[str] = None
    display_name: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    email: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    created_at: Optional[datetime] = None
    is_premium: bool = False
    subscription_expires: Optional[datetime] = None

    class Config:
        from_attributes = True


class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
    refresh_token: Optional[str] = None
