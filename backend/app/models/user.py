from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime

class UserBase(BaseModel):
    username: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserInDB(UserBase):
    id: str = Field(alias="_id")
    hashed_password: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

class UserResponse(UserBase):
    id: str
    created_at: datetime

# Future Models to be populated:
class StudySession(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    user_id: str
    duration_minutes: int
    focus_score: int
    created_at: datetime = Field(default_factory=datetime.utcnow)
