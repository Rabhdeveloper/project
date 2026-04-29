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


# ─── VR Environments ──────────────────────────────────────────────────────────

class VREnvironmentBase(BaseModel):
    name: str  # e.g., "Cyberpunk Library", "Zen Garden", "Deep Space"
    description: str = ""
    environment_type: str = "library"  # library, garden, space, underwater, forest
    spatial_audio_preset: str = "none"  # none, white_noise, binaural_beats, rain, fireplace
    lighting_preset: str = "neutral"  # neutral, warm, cool, neon, candlelight


class VREnvironmentCreate(VREnvironmentBase):
    pass


class VREnvironmentResponse(VREnvironmentBase):
    id: str = Field(alias="_id")
    user_id: str
    is_active: bool = False
    created_at: datetime

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# ─── AR 3D Flashcards ─────────────────────────────────────────────────────────

class ARFlashcard3DBase(BaseModel):
    title: str
    subject: str
    model_type: str = "generic"  # anatomy, molecule, architecture, math_graph, generic
    model_data: Dict = {}  # 3D model metadata (vertices, textures, scale, rotation)
    front_text: str = ""
    back_text: str = ""
    ar_scale: float = 1.0
    ar_pinned_to: str = ""  # Physical object description (e.g., "textbook", "desk")


class ARFlashcard3DCreate(ARFlashcard3DBase):
    pass


class ARFlashcard3DResponse(ARFlashcard3DBase):
    id: str = Field(alias="_id")
    user_id: str
    created_at: datetime

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# ─── Spatial Avatar Position (for multiplayer VR sync) ─────────────────────────

class AvatarPosition(BaseModel):
    user_id: str
    username: str
    position: Dict = {"x": 0.0, "y": 0.0, "z": 0.0}
    rotation: Dict = {"pitch": 0.0, "yaw": 0.0, "roll": 0.0}
    hand_left: Dict = {"x": 0.0, "y": 0.0, "z": 0.0}
    hand_right: Dict = {"x": 0.0, "y": 0.0, "z": 0.0}
    gesture: str = "idle"  # idle, pointing, writing, waving, thumbs_up


class SpatialSessionBase(BaseModel):
    name: str
    environment_id: str
    max_participants: int = 8


class SpatialSessionCreate(SpatialSessionBase):
    pass


class SpatialSessionResponse(SpatialSessionBase):
    id: str = Field(alias="_id")
    host_id: str
    participants: List[AvatarPosition] = []
    whiteboard_strokes: List[Dict] = []
    is_active: bool = True
    created_at: datetime

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}
