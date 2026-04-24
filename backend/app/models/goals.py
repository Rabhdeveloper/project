from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class UserGoalUpdate(BaseModel):
    daily_target: int = Field(..., ge=1, le=10, description="Daily session target (1–10)")


class UserGoal(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    user_id: str
    daily_target: int = 4
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True


class GoalResponse(BaseModel):
    daily_target: int
    current_streak: int = 0


class TodayProgressResponse(BaseModel):
    sessions_done: int = 0
    daily_target: int = 4
    completed: bool = False
