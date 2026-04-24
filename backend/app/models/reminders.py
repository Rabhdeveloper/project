from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class ReminderCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=100)
    time: str = Field(..., pattern=r"^\d{2}:\d{2}$", description="Time in HH:MM format")
    days: List[str] = Field(
        ...,
        description="Days of the week: mon, tue, wed, thu, fri, sat, sun",
    )
    enabled: bool = True


class ReminderUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=100)
    time: Optional[str] = Field(None, pattern=r"^\d{2}:\d{2}$")
    days: Optional[List[str]] = None
    enabled: Optional[bool] = None


class ReminderResponse(BaseModel):
    id: str
    title: str
    time: str
    days: List[str]
    enabled: bool
    created_at: datetime
