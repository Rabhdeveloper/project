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


# ─── Biometric Sensor Readings ────────────────────────────────────────────────

class BiometricReadingBase(BaseModel):
    sensor_type: str  # hrv, gsr, eeg, heart_rate
    device_name: str = "unknown"  # e.g., "Oura Ring", "Apple Watch", "Muse Headband"
    value: float  # Primary reading value
    unit: str = ""  # bpm, ms, μS, μV
    metadata: Dict = {}  # Additional sensor-specific data (e.g., EEG bands: alpha, beta, theta)


class BiometricReadingCreate(BiometricReadingBase):
    pass


class BiometricReadingResponse(BiometricReadingBase):
    id: str = Field(alias="_id")
    user_id: str
    timestamp: datetime
    session_id: Optional[str] = None  # Linked study session if active

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# ─── Cognitive Load Index ──────────────────────────────────────────────────────

class CognitiveLoadIndex(BaseModel):
    user_id: str
    overall_load: float  # 0.0 (relaxed) to 1.0 (overloaded)
    focus_depth: float  # 0.0 (distracted) to 1.0 (deep focus)
    stress_level: float  # 0.0 (calm) to 1.0 (high stress)
    recommended_action: str  # "continue", "short_break", "long_break", "stop", "meditation"
    computed_at: datetime


# ─── Burnout Risk Profile ─────────────────────────────────────────────────────

class BurnoutRiskProfile(BaseModel):
    user_id: str
    risk_score: float  # 0.0 (no risk) to 1.0 (critical burnout risk)
    risk_level: str  # "low", "moderate", "high", "critical"
    contributing_factors: List[str] = []  # e.g., ["prolonged_high_stress", "no_breaks_3h", "elevated_hrv"]
    intervention: str = "none"  # none, suggest_break, force_break, suggest_meditation
    intervention_message: str = ""
    computed_at: datetime


# ─── Adaptive UI Preferences (Neuro-Adaptive) ─────────────────────────────────

class NeuroAdaptiveUIState(BaseModel):
    user_id: str
    zen_mode_active: bool = False
    ui_complexity: str = "full"  # full, simplified, minimal
    ambient_soundscape: str = "none"  # none, binaural_alpha, binaural_theta, rain, silence
    screen_brightness: float = 1.0  # 0.0 to 1.0
    last_updated: datetime
