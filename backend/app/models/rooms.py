from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from bson import ObjectId

class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid objectid")
        return ObjectId(v)

    @classmethod
    def __modify_schema__(cls, field_schema):
        field_schema.update(type="string")

class RoomParticipant(BaseModel):
    user_id: str
    username: str
    status: str = "idle"  # idle, focusing, break
    joined_at: datetime = Field(default_factory=datetime.utcnow)

class StudyRoomBase(BaseModel):
    name: str
    is_private: bool = False

class StudyRoomCreate(StudyRoomBase):
    pass

class StudyRoomUpdate(BaseModel):
    name: Optional[str] = None
    is_private: Optional[bool] = None
    current_status: Optional[str] = None

class StudyRoomResponse(StudyRoomBase):
    id: str = Field(alias="_id")
    host_id: str
    current_status: str = "idle" # idle, focusing, break
    participants: List[RoomParticipant] = []
    created_at: datetime
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}
