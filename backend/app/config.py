"""Application configuration loaded from environment variables."""

import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Supabase
    supabase_url: str = "https://your-project.supabase.co"
    supabase_anon_key: str = "your-anon-key"
    supabase_service_role_key: str = "your-service-role-key"

    # Alibaba Cloud (Tongyi Qianwen)
    dashscope_api_key: str = "your-dashscope-api-key"
    qwen_model: str = "qwen-plus"

    # JWT
    jwt_secret: str = "your-jwt-secret-change-in-production"

    # App
    app_name: str = "AEL Screen AI"
    app_version: str = "1.0.0"
    debug: bool = True
    host: str = "0.0.0.0"
    port: int = 8000

    # CORS
    cors_origins: str = "*"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
