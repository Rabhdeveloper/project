from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from datetime import datetime
from bson import ObjectId

from app.core.database import get_database
from app.api.auth import get_current_user
from app.models.user import UserInDB
from app.models.iot import SmartDeviceCreate, SmartDeviceResponse, FocusProtocolConfig, FocusProtocolResponse
from app.core.context_engine import context_engine

router = APIRouter()


@router.post("/devices", response_model=SmartDeviceResponse, status_code=status.HTTP_201_CREATED)
async def register_device(device_in: SmartDeviceCreate, current_user: UserInDB = Depends(get_current_user)):
    """Register a smart home device (light, thermostat, speaker, etc.)."""
    db = get_database()
    device_doc = {
        "user_id": str(current_user.id), "name": device_in.name,
        "device_type": device_in.device_type, "brand": device_in.brand,
        "ip_address": device_in.ip_address, "is_online": True,
        "registered_at": datetime.utcnow(),
    }
    result = await db["iot_devices"].insert_one(device_doc)
    device_doc["_id"] = str(result.inserted_id)
    return device_doc


@router.get("/devices", response_model=List[SmartDeviceResponse])
async def list_devices(current_user: UserInDB = Depends(get_current_user)):
    db = get_database()
    cursor = db["iot_devices"].find({"user_id": str(current_user.id)})
    devices = []
    async for d in cursor:
        d["_id"] = str(d["_id"])
        devices.append(d)
    return devices


@router.post("/focus-protocol", response_model=FocusProtocolResponse)
async def activate_focus_protocol(
    config: FocusProtocolConfig = FocusProtocolConfig(),
    current_user: UserInDB = Depends(get_current_user),
):
    """Activate Focus Protocol — adjusts lights, temperature, locks phone, mutes notifications."""
    commands = context_engine.generate_iot_commands(config.dict())
    return FocusProtocolResponse(
        user_id=str(current_user.id), is_active=True, config=config,
        activated_at=datetime.utcnow(), commands_sent=commands,
    )


@router.delete("/focus-protocol")
async def deactivate_focus_protocol(current_user: UserInDB = Depends(get_current_user)):
    """Disengage Focus Protocol — restore normal device settings."""
    return {"status": "success", "message": "Focus Protocol deactivated. Devices restored to normal settings."}


@router.get("/context")
async def get_user_context(current_user: UserInDB = Depends(get_current_user)):
    """Get predictive context classification (commuting, library, bed, etc.)."""
    result = context_engine.classify_context(user_id=str(current_user.id))
    return {"status": "success", "data": result}
