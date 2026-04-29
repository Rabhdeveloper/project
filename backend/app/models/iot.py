from pydantic import BaseModel, Field
from typing import List, Optional, Dict
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


# ─── Smart Devices ────────────────────────────────────────────────────────────

class SmartDeviceBase(BaseModel):
    name: str
    device_type: str  # light, thermostat, speaker, lock, phone
    brand: str = ""   # e.g., "Philips Hue", "Nest", "Sonos"
    ip_address: str = ""
    is_online: bool = True

class SmartDeviceCreate(SmartDeviceBase):
    pass

class SmartDeviceResponse(SmartDeviceBase):
    id: str = Field(alias="_id")
    user_id: str
    registered_at: datetime
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# ─── Focus Protocol ──────────────────────────────────────────────────────────

class FocusProtocolConfig(BaseModel):
    light_color_temp: int = 5000  # Kelvin (cool white for alertness)
    light_brightness: int = 80   # Percent
    target_temp_celsius: float = 20.0  # Cooler = more alert
    lock_phone: bool = True
    mute_notifications: bool = True
    block_websites: List[str] = []

class FocusProtocolResponse(BaseModel):
    user_id: str
    is_active: bool
    config: FocusProtocolConfig
    activated_at: Optional[datetime] = None
    commands_sent: List[Dict] = []


# ─── User Context ─────────────────────────────────────────────────────────────

class UserContext(BaseModel):
    user_id: str
    location_state: str  # commuting, library, home_desk, bed, gym, unknown
    activity_type: str   # walking, sitting, lying_down, driving, unknown
    time_context: str    # morning, afternoon, evening, night
    suggested_action: str  # audio_flashcards, study_session, sleep_review, break, none
    confidence: float = 0.0
    computed_at: datetime


# ─── AI Avatar Conversation ──────────────────────────────────────────────────

class AvatarMessage(BaseModel):
    role: str  # user, assistant
    content: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class AvatarConversationRequest(BaseModel):
    message: str
    context: str = ""  # Optional context (current subject, active session, etc.)

class AvatarConversationResponse(BaseModel):
    reply: str
    suggestions: List[str] = []
    generated_notes: List[str] = []  # Auto-generated notes from the conversation

class LectureIngestRequest(BaseModel):
    text: str  # Transcribed lecture text
    subject: str = ""
    source: str = "manual"  # manual, microphone, upload

class LectureIngestResponse(BaseModel):
    summary: str
    key_points: List[str] = []
    generated_flashcards: int = 0
    generated_quiz_questions: int = 0
