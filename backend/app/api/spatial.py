from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from typing import List
from datetime import datetime
from bson import ObjectId

from app.core.database import get_database
from app.api.auth import get_current_user
from app.models.user import UserInDB
from app.models.spatial import (
    VREnvironmentCreate, VREnvironmentResponse,
    ARFlashcard3DCreate, ARFlashcard3DResponse,
    SpatialSessionCreate, SpatialSessionResponse,
)
from app.websockets import manager

router = APIRouter()


# ═══════════════════════════════════════════════════
#  SECTION A — VR FOCUS PORTALS
# ═══════════════════════════════════════════════════

# Default immersive environments available to all users
DEFAULT_ENVIRONMENTS = [
    {
        "name": "Cyberpunk Library",
        "description": "A neon-lit futuristic library with holographic bookshelves and ambient rain.",
        "environment_type": "library",
        "spatial_audio_preset": "rain",
        "lighting_preset": "neon",
    },
    {
        "name": "Zen Garden",
        "description": "A serene Japanese garden with koi ponds, bamboo, and gentle wind chimes.",
        "environment_type": "garden",
        "spatial_audio_preset": "white_noise",
        "lighting_preset": "warm",
    },
    {
        "name": "Deep Space Station",
        "description": "A quiet orbital station overlooking Earth with the hum of life-support systems.",
        "environment_type": "space",
        "spatial_audio_preset": "binaural_beats",
        "lighting_preset": "cool",
    },
    {
        "name": "Underwater Coral Reef",
        "description": "Study surrounded by bioluminescent coral and gentle ocean currents.",
        "environment_type": "underwater",
        "spatial_audio_preset": "white_noise",
        "lighting_preset": "cool",
    },
    {
        "name": "Enchanted Forest",
        "description": "A mystical forest clearing with fireflies, ancient trees, and birdsong.",
        "environment_type": "forest",
        "spatial_audio_preset": "fireplace",
        "lighting_preset": "warm",
    },
]


@router.get("/environments", response_model=List[VREnvironmentResponse])
async def list_environments(current_user: UserInDB = Depends(get_current_user)):
    """List all available VR study environments (defaults + user-created)."""
    db = get_database()

    environments = []
    # Return default environments with synthetic IDs
    for i, env in enumerate(DEFAULT_ENVIRONMENTS):
        environments.append({
            **env,
            "_id": f"default_{i}",
            "user_id": "system",
            "is_active": False,
            "created_at": datetime.utcnow(),
        })

    # Also fetch user-created custom environments
    cursor = db["vr_environments"].find({"user_id": str(current_user.id)})
    async for env in cursor:
        env["_id"] = str(env["_id"])
        environments.append(env)

    return environments


@router.post("/environments", response_model=VREnvironmentResponse, status_code=status.HTTP_201_CREATED)
async def create_environment(env_in: VREnvironmentCreate, current_user: UserInDB = Depends(get_current_user)):
    """Create a custom VR study environment."""
    db = get_database()
    env_data = {
        "user_id": str(current_user.id),
        "name": env_in.name,
        "description": env_in.description,
        "environment_type": env_in.environment_type,
        "spatial_audio_preset": env_in.spatial_audio_preset,
        "lighting_preset": env_in.lighting_preset,
        "is_active": False,
        "created_at": datetime.utcnow(),
    }
    result = await db["vr_environments"].insert_one(env_data)
    env_data["_id"] = str(result.inserted_id)
    return env_data


# ═══════════════════════════════════════════════════
#  SECTION B — AR INTERACTIVE LEARNING
# ═══════════════════════════════════════════════════

@router.post("/ar/flashcards", response_model=ARFlashcard3DResponse, status_code=status.HTTP_201_CREATED)
async def create_ar_flashcard(card_in: ARFlashcard3DCreate, current_user: UserInDB = Depends(get_current_user)):
    """Create a 3D AR flashcard that can be projected onto physical surfaces."""
    db = get_database()
    card_data = {
        "user_id": str(current_user.id),
        "title": card_in.title,
        "subject": card_in.subject,
        "model_type": card_in.model_type,
        "model_data": card_in.model_data,
        "front_text": card_in.front_text,
        "back_text": card_in.back_text,
        "ar_scale": card_in.ar_scale,
        "ar_pinned_to": card_in.ar_pinned_to,
        "created_at": datetime.utcnow(),
    }
    result = await db["ar_flashcards_3d"].insert_one(card_data)
    card_data["_id"] = str(result.inserted_id)
    return card_data


@router.get("/ar/flashcards", response_model=List[ARFlashcard3DResponse])
async def list_ar_flashcards(current_user: UserInDB = Depends(get_current_user)):
    """List all AR 3D flashcards for the authenticated user."""
    db = get_database()
    cursor = db["ar_flashcards_3d"].find({"user_id": str(current_user.id)})
    cards = []
    async for card in cursor:
        card["_id"] = str(card["_id"])
        cards.append(card)
    return cards


# ═══════════════════════════════════════════════════
#  SECTION C — SPATIAL MULTIPLAYER
# ═══════════════════════════════════════════════════

@router.post("/sessions", response_model=SpatialSessionResponse, status_code=status.HTTP_201_CREATED)
async def create_spatial_session(session_in: SpatialSessionCreate, current_user: UserInDB = Depends(get_current_user)):
    """Create a spatial multiplayer VR study session."""
    db = get_database()
    session_data = {
        "host_id": str(current_user.id),
        "name": session_in.name,
        "environment_id": session_in.environment_id,
        "max_participants": session_in.max_participants,
        "participants": [
            {
                "user_id": str(current_user.id),
                "username": current_user.username,
                "position": {"x": 0.0, "y": 0.0, "z": 0.0},
                "rotation": {"pitch": 0.0, "yaw": 0.0, "roll": 0.0},
                "hand_left": {"x": 0.0, "y": 0.0, "z": 0.0},
                "hand_right": {"x": 0.0, "y": 0.0, "z": 0.0},
                "gesture": "idle",
            }
        ],
        "whiteboard_strokes": [],
        "is_active": True,
        "created_at": datetime.utcnow(),
    }
    result = await db["spatial_sessions"].insert_one(session_data)
    session_data["_id"] = str(result.inserted_id)
    return session_data


@router.get("/sessions", response_model=List[SpatialSessionResponse])
async def list_spatial_sessions(current_user: UserInDB = Depends(get_current_user)):
    """List all active spatial VR sessions."""
    db = get_database()
    cursor = db["spatial_sessions"].find({"is_active": True})
    sessions = []
    async for session in cursor:
        session["_id"] = str(session["_id"])
        sessions.append(session)
    return sessions


@router.websocket("/{session_id}/ws")
async def spatial_websocket(websocket: WebSocket, session_id: str):
    """
    High-frequency WebSocket for spatial multiplayer sync.
    Handles: avatar positions, hand gestures, whiteboard strokes.
    Expected JSON format:
    {"action": "position_update"|"gesture"|"whiteboard_stroke", "data": {...}}
    """
    await manager.connect(websocket, f"spatial_{session_id}")
    try:
        while True:
            data = await websocket.receive_text()
            # Broadcast positional/gesture data to all participants in the spatial session
            await manager.broadcast_to_room(data, f"spatial_{session_id}")
    except WebSocketDisconnect:
        manager.disconnect(websocket, f"spatial_{session_id}")
        await manager.broadcast_to_room(
            {"action": "avatar_left", "message": "An avatar disconnected from the spatial session."},
            f"spatial_{session_id}"
        )
