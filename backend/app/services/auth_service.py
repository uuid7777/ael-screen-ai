"""Authentication service: Supabase auth + Apple Sign-In + JWT."""

from typing import Optional
from app.database import get_supabase, get_service_client
from app.config import settings
from app.models.user import UserResponse, AuthTokenResponse


async def register_user(email: str, password: str, display_name: Optional[str] = None) -> AuthTokenResponse:
    """Register a new user via Supabase Auth."""
    client = get_supabase()
    resp = client.auth.sign_up({
        "email": email,
        "password": password,
        "options": {"data": {"display_name": display_name or email.split("@")[0]}},
    })
    user = resp.user
    session = resp.session
    return AuthTokenResponse(
        access_token=session.access_token if session else "",
        refresh_token=session.refresh_token if session else None,
        user=UserResponse(
            id=user.id,
            email=user.email,
            display_name=user.user_metadata.get("display_name") if user.user_metadata else None,
        ),
    )


async def login_user(email: str, password: str) -> AuthTokenResponse:
    """Login with email and password."""
    client = get_supabase()
    resp = client.auth.sign_in_with_password({"email": email, "password": password})
    user = resp.user
    session = resp.session
    return AuthTokenResponse(
        access_token=session.access_token if session else "",
        refresh_token=session.refresh_token if session else None,
        user=UserResponse(
            id=user.id,
            email=user.email,
            display_name=user.user_metadata.get("display_name") if user.user_metadata else None,
        ),
    )


async def apple_sign_in(
    identity_token: str,
    authorization_code: str,
    user_id: str,
    email: Optional[str] = None,
    display_name: Optional[str] = None,
) -> AuthTokenResponse:
    """Sign in with Apple via Supabase Auth."""
    client = get_supabase()
    resp = client.auth.sign_in_with_id_token({
        "provider": "apple",
        "id_token": identity_token,
        "nonce": authorization_code,
    })
    user = resp.user
    session = resp.session
    # Update display name if provided
    if display_name and user:
        get_service_client().auth.admin.update_user_by_id(
            user.id, {"user_metadata": {"display_name": display_name}}
        )
    return AuthTokenResponse(
        access_token=session.access_token if session else "",
        refresh_token=session.refresh_token if session else None,
        user=UserResponse(
            id=user.id if user else user_id,
            email=email or (user.email if user else None),
            display_name=display_name,
        ),
    )


async def get_current_user(access_token: str) -> Optional[UserResponse]:
    """Get current user from access token."""
    try:
        client = get_supabase()
        user = client.auth.get_user(access_token)
        if not user or not user.user:
            return None
        u = user.user
        sub_info = get_service_client().table("subscriptions").select("*").eq("user_id", u.id).eq("status", "active").maybe_single().execute()
        is_premium = bool(sub_info.data) if sub_info else False
        expires = None
        if sub_info and sub_info.data:
            expires = sub_info.data.get("end_date")
        return UserResponse(
            id=u.id,
            email=u.email,
            display_name=u.user_metadata.get("display_name") if u.user_metadata else None,
            avatar_url=u.user_metadata.get("avatar_url") if u.user_metadata else None,
            created_at=u.created_at,
            is_premium=is_premium,
            subscription_expires=expires,
        )
    except Exception:
        return None


async def logout_user(access_token: str) -> bool:
    """Logout user."""
    try:
        client = get_supabase()
        client.auth.sign_out()
        return True
    except Exception:
        return False
