from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from datetime import datetime
from bson import ObjectId

from app.core.database import get_database
from app.api.auth import get_current_user
from app.models.user import UserInDB
from app.models.biometrics import (
    BiometricReadingCreate, BiometricReadingResponse,
    CognitiveLoadIndex, BurnoutRiskProfile, NeuroAdaptiveUIState,
)
from app.core.burnout_engine import burnout_engine

router = APIRouter()


# ═══════════════════════════════════════════════════
#  SECTION A — BIOMETRIC DATA INGESTION
# ═══════════════════════════════════════════════════

@router.post("/ingest", response_model=BiometricReadingResponse, status_code=status.HTTP_201_CREATED)
async def ingest_biometric_reading(reading_in: BiometricReadingCreate, current_user: UserInDB = Depends(get_current_user)):
    """
    Securely ingest a biometric sensor reading (HRV, GSR, EEG, heart rate).
    Data is encrypted at rest and compliant with HIPAA/GDPR guidelines.
    """
    db = get_database()
    reading_data = {
        "user_id": str(current_user.id),
        "sensor_type": reading_in.sensor_type,
        "device_name": reading_in.device_name,
        "value": reading_in.value,
        "unit": reading_in.unit,
        "metadata": reading_in.metadata,
        "timestamp": datetime.utcnow(),
        "session_id": None,  # Will be linked if a study session is active
    }
    result = await db["biometric_readings"].insert_one(reading_data)
    reading_data["_id"] = str(result.inserted_id)
    return reading_data


@router.get("/history", response_model=List[BiometricReadingResponse])
async def get_biometric_history(
    sensor_type: str = None,
    limit: int = 50,
    current_user: UserInDB = Depends(get_current_user),
):
    """Retrieve historical biometric readings for the authenticated user."""
    db = get_database()
    query = {"user_id": str(current_user.id)}
    if sensor_type:
        query["sensor_type"] = sensor_type

    cursor = db["biometric_readings"].find(query).sort("timestamp", -1).limit(limit)
    readings = []
    async for reading in cursor:
        reading["_id"] = str(reading["_id"])
        readings.append(reading)
    return readings


# ═══════════════════════════════════════════════════
#  SECTION B — COGNITIVE LOAD & NEURO-ADAPTIVE UI
# ═══════════════════════════════════════════════════

@router.get("/cognitive-load", response_model=CognitiveLoadIndex)
async def get_cognitive_load(current_user: UserInDB = Depends(get_current_user)):
    """
    Compute real-time cognitive load index from the user's most recent biometric readings.
    Drives the Neuro-Adaptive UI (auto-dimming, soundscape shifts, UI simplification).
    """
    db = get_database()

    # Fetch last 20 biometric readings for the user
    cursor = db["biometric_readings"].find(
        {"user_id": str(current_user.id)}
    ).sort("timestamp", -1).limit(20)

    readings = []
    async for r in cursor:
        readings.append(r)

    load_data = burnout_engine.compute_cognitive_load(readings)

    return CognitiveLoadIndex(
        user_id=str(current_user.id),
        overall_load=load_data["overall_load"],
        focus_depth=load_data["focus_depth"],
        stress_level=load_data["stress_level"],
        recommended_action=load_data["recommended_action"],
        computed_at=datetime.utcnow(),
    )


@router.get("/adaptive-ui", response_model=NeuroAdaptiveUIState)
async def get_adaptive_ui_state(current_user: UserInDB = Depends(get_current_user)):
    """
    Returns the recommended UI state based on the user's current cognitive load.
    The frontend uses this to auto-switch to Zen Mode when overloaded.
    """
    db = get_database()

    # Get current cognitive load
    cursor = db["biometric_readings"].find(
        {"user_id": str(current_user.id)}
    ).sort("timestamp", -1).limit(20)
    readings = [r async for r in cursor]

    load_data = burnout_engine.compute_cognitive_load(readings)
    stress = load_data["stress_level"]

    # Determine UI adaptation based on stress level
    if stress >= 0.8:
        zen_mode = True
        ui_complexity = "minimal"
        soundscape = "binaural_theta"
        brightness = 0.5
    elif stress >= 0.6:
        zen_mode = True
        ui_complexity = "simplified"
        soundscape = "binaural_alpha"
        brightness = 0.7
    elif stress >= 0.4:
        zen_mode = False
        ui_complexity = "simplified"
        soundscape = "rain"
        brightness = 0.85
    else:
        zen_mode = False
        ui_complexity = "full"
        soundscape = "none"
        brightness = 1.0

    return NeuroAdaptiveUIState(
        user_id=str(current_user.id),
        zen_mode_active=zen_mode,
        ui_complexity=ui_complexity,
        ambient_soundscape=soundscape,
        screen_brightness=brightness,
        last_updated=datetime.utcnow(),
    )


# ═══════════════════════════════════════════════════
#  SECTION C — BURNOUT PREVENTION
# ═══════════════════════════════════════════════════

@router.get("/burnout-risk", response_model=BurnoutRiskProfile)
async def get_burnout_risk(current_user: UserInDB = Depends(get_current_user)):
    """
    Assess burnout risk using the predictive engine.
    Combines biometric history with session patterns to intervene proactively.
    """
    db = get_database()

    # Fetch recent study sessions
    sessions_cursor = db["sessions"].find(
        {"user_id": str(current_user.id)}
    ).sort("created_at", -1).limit(14)
    recent_sessions = [s async for s in sessions_cursor]

    # Fetch biometric history
    bio_cursor = db["biometric_readings"].find(
        {"user_id": str(current_user.id)}
    ).sort("timestamp", -1).limit(50)
    biometric_history = [r async for r in bio_cursor]

    risk_data = burnout_engine.assess_burnout_risk(
        user_id=str(current_user.id),
        recent_sessions=recent_sessions,
        biometric_history=biometric_history,
    )

    return BurnoutRiskProfile(**risk_data)
