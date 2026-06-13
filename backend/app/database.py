"""Supabase database client initialization."""

from supabase import create_client, Client
from app.config import settings

supabase: Client | None = None


def get_supabase() -> Client:
    """Get the initialized Supabase client."""
    global supabase
    if supabase is None:
        supabase = create_client(
            settings.supabase_url,
            settings.supabase_anon_key,
        )
    return supabase


def get_service_client() -> Client:
    """Get Supabase client with service role for admin operations."""
    if not settings.supabase_service_role_key or \
       settings.supabase_service_role_key == "your-service-role-key":
        return get_supabase()
    return create_client(
        settings.supabase_url,
        settings.supabase_service_role_key,
    )
