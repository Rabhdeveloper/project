from fastapi import APIRouter, Depends
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime, timedelta

router = APIRouter()


# ─── GET /friends — recent sessions from friends (last 24h) ─────────────────

@router.get("/friends")
async def get_friend_activity(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return recent study activity from the current user's friends (last 24h)."""
    user_id = current_user["_id"]

    # Get all accepted friend IDs
    friend_ids = []
    cursor = db["friend_requests"].find({
        "$or": [
            {"from_user_id": user_id, "status": "accepted"},
            {"to_user_id": user_id, "status": "accepted"},
        ]
    })
    async for doc in cursor:
        fid = doc["to_user_id"] if doc["from_user_id"] == user_id else doc["from_user_id"]
        friend_ids.append(fid)

    if not friend_ids:
        return []

    # Get sessions from friends in the last 24 hours
    since = datetime.utcnow() - timedelta(hours=24)

    pipeline = [
        {
            "$match": {
                "user_id": {"$in": friend_ids},
                "session_type": "focus",
                "created_at": {"$gte": since},
            }
        },
        {
            "$group": {
                "_id": "$user_id",
                "sessions_count": {"$sum": 1},
                "total_minutes": {"$sum": "$duration_minutes"},
                "latest_at": {"$max": "$created_at"},
            }
        },
        {"$sort": {"latest_at": -1}},
        {
            "$lookup": {
                "from": "users",
                "localField": "_id",
                "foreignField": "_id",
                "as": "user_info",
            }
        },
        {"$unwind": {"path": "$user_info", "preserveNullAndEmptyArrays": True}},
    ]

    results = await db["study_sessions"].aggregate(pipeline).to_list(20)

    activity = []
    for entry in results:
        username = "Unknown"
        if entry.get("user_info"):
            username = entry["user_info"].get("username", "Unknown")

        activity.append({
            "user_id": entry["_id"],
            "username": username,
            "sessions_count": entry["sessions_count"],
            "total_minutes": entry["total_minutes"],
            "latest_at": entry["latest_at"].isoformat() if entry.get("latest_at") else None,
        })

    return activity
