from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from typing import List
from datetime import datetime
from bson import ObjectId
from app.core.database import get_database
from app.api.auth import get_current_user
from app.models.rooms import StudyRoomCreate, StudyRoomResponse, RoomParticipant
from app.models.user import UserInDB
from app.websockets import manager

router = APIRouter()

@router.post("", response_model=StudyRoomResponse, status_code=status.HTTP_201_CREATED)
async def create_room(room_in: StudyRoomCreate, current_user: UserInDB = Depends(get_current_user)):
    db = get_database()
    
    room_data = {
        "host_id": str(current_user.id),
        "name": room_in.name,
        "is_private": room_in.is_private,
        "current_status": "idle",
        "participants": [
            {
                "user_id": str(current_user.id),
                "username": current_user.username,
                "status": "idle",
                "joined_at": datetime.utcnow()
            }
        ],
        "created_at": datetime.utcnow()
    }
    
    result = await db["rooms"].insert_one(room_data)
    room_data["_id"] = str(result.inserted_id)
    return room_data

@router.get("", response_model=List[StudyRoomResponse])
async def list_rooms(current_user: UserInDB = Depends(get_current_user)):
    db = get_database()
    # List all public rooms, maybe in the future we only show active ones
    cursor = db["rooms"].find({"is_private": False})
    rooms = []
    async for room in cursor:
        room["_id"] = str(room["_id"])
        rooms.append(room)
    return rooms

@router.get("/{room_id}", response_model=StudyRoomResponse)
async def get_room(room_id: str, current_user: UserInDB = Depends(get_current_user)):
    db = get_database()
    if not ObjectId.is_valid(room_id):
        raise HTTPException(status_code=400, detail="Invalid room ID")
        
    room = await db["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
        
    room["_id"] = str(room["_id"])
    return room

# WebSocket endpoint
# Wait, this router is prefixed with /api/rooms.
# We probably should put the websocket endpoint on the same router but note that the websocket doesn't use the standard Bearer token header easily in browsers. 
# But for Flutter, we can pass headers.
# Let's keep it here. The actual path will be /api/rooms/{room_id}/ws

@router.websocket("/{room_id}/ws")
async def websocket_endpoint(websocket: WebSocket, room_id: str):
    await manager.connect(websocket, room_id)
    try:
        while True:
            data = await websocket.receive_text()
            # expecting JSON string: {"action": "timer_start", "user_id": "...", ...}
            # For now, just broadcast whatever is received back to the room
            await manager.broadcast_to_room(data, room_id)
    except WebSocketDisconnect:
        manager.disconnect(websocket, room_id)
        await manager.broadcast_to_room({"action": "user_left", "message": "A user left the room"}, room_id)
