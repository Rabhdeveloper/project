from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


class UserBase(BaseModel):
    username: str
    email: EmailStr


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    username: Optional[str] = None


class UserInDB(UserBase):
    id: str = Field(alias="_id")
    hashed_password: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True


class UserResponse(UserBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True


# ─── Study Session Model (for future use) ────────────────────────────────────

class StudySession(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    user_id: str
    duration_minutes: int
    focus_score: int
    created_at: datetime = Field(default_factory=datetime.utcnow)


# ─── Typing Result Model (for future use) ────────────────────────────────────

class TypingResult(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    user_id: str
    wpm: int
    accuracy: float
    created_at: datetime = Field(default_factory=datetime.utcnow)
