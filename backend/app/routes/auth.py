"""Authentication routes."""

from fastapi import APIRouter, Depends, HTTPException, Header
from app.models.user import (
    UserCreate, UserLogin, AppleLoginRequest,
    AuthTokenResponse, UserResponse,
)
from app.models.request_response import StandardResponse
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=StandardResponse)
async def register(body: UserCreate):
    """Register a new user."""
    try:
        result = await auth_service.register_user(body.email, body.password, body.display_name)
        return StandardResponse(success=True, message="Registration successful", data=result.model_dump())
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login", response_model=StandardResponse)
async def login(body: UserLogin):
    """Login with email and password."""
    try:
        result = await auth_service.login_user(body.email, body.password)
        return StandardResponse(success=True, message="Login successful", data=result.model_dump())
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post("/apple", response_model=StandardResponse)
async def apple_sign_in(body: AppleLoginRequest):
    """Sign in with Apple."""
    try:
        result = await auth_service.apple_sign_in(
            body.identity_token,
            body.authorization_code,
            body.user_id,
            body.email,
            body.display_name,
        )
        return StandardResponse(success=True, message="Apple sign-in successful", data=result.model_dump())
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.get("/me", response_model=StandardResponse)
async def get_profile(authorization: str = Header(...)):
    """Get current user profile."""
    token = authorization.replace("Bearer ", "")
    user = await auth_service.get_current_user(token)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return StandardResponse(success=True, data=user.model_dump())


@router.post("/logout", response_model=StandardResponse)
async def logout(authorization: str = Header("")):
    """Logout user."""
    token = authorization.replace("Bearer ", "") if authorization else ""
    await auth_service.logout_user(token)
    return StandardResponse(success=True, message="Logged out")
