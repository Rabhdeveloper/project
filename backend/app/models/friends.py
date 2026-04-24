from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class FriendRequestCreate(BaseModel):
    to_user_id: str = Field(..., description="ID of the user to send request to")


class FriendRequest(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    from_user_id: str
    to_user_id: str
    status: str = "pending"  # "pending" | "accepted" | "rejected"
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True


class FriendRequestResponse(BaseModel):
    id: str
    from_user_id: str
    from_username: str = ""
    to_user_id: str
    to_username: str = ""
    status: str
    created_at: datetime


class FriendResponse(BaseModel):
    user_id: str
    username: str
    email: str
    current_streak: int = 0
    total_sessions: int = 0
    since: datetime  # when friendship was accepted
