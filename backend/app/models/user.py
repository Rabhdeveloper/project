from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime


class UserBase(BaseModel):
    username: str
    email: EmailStr


class UserCreate(UserBase):
    password: str

    @field_validator("username")
    @classmethod
    def username_min_length(cls, v: str) -> str:
        if len(v.strip()) < 3:
            raise ValueError("Username must be at least 3 characters")
        return v.strip()

    @field_validator("password")
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v


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


# ─── Study Session Models ─────────────────────────────────────────────────────

class StudySessionCreate(BaseModel):
    duration_minutes: int = Field(..., gt=0, description="Duration of the study session in minutes")
    session_type: str = Field(default="focus", description="Type of session: 'focus' or 'break'")
    subject_id: Optional[str] = Field(None, description="Optional subject ID to tag session")

    @field_validator("session_type")
    @classmethod
    def validate_session_type(cls, v: str) -> str:
        if v not in ("focus", "break"):
            raise ValueError("session_type must be 'focus' or 'break'")
        return v


class StudySession(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    user_id: str
    duration_minutes: int
    session_type: str = "focus"
    subject_id: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True


class StudySessionResponse(BaseModel):
    id: str
    duration_minutes: int
    session_type: str
    subject_id: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ─── Typing Result Models ─────────────────────────────────────────────────────

class TypingResultCreate(BaseModel):
    wpm: int = Field(..., gt=0, description="Words per minute")
    accuracy: float = Field(..., ge=0, le=100, description="Accuracy percentage")
    duration_seconds: int = Field(..., gt=0, description="Test duration in seconds")


class TypingResult(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    user_id: str
    wpm: int
    accuracy: float
    duration_seconds: int = 0
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True


class TypingResultResponse(BaseModel):
    id: str
    wpm: int
    accuracy: float
    duration_seconds: int
    created_at: datetime

    class Config:
        from_attributes = True
