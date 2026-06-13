from typing import Any, Generic, TypeVar
from pydantic import BaseModel

T = TypeVar("T")


class StandardResponse(BaseModel):
    """Standard API response wrapper."""
    success: bool = True
    message: str = ""
    data: Any = None


class PaginatedResponse(BaseModel):
    """Paginated list response."""
    success: bool = True
    data: list = []
    total: int = 0
    page: int = 1
    page_size: int = 20
    has_more: bool = False


class ErrorResponse(BaseModel):
    """Error response."""
    success: bool = False
    error_code: str = "UNKNOWN_ERROR"
    message: str = "An unknown error occurred"
    detail: Any = None
