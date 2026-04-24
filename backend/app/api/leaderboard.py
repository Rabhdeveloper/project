from fastapi import APIRouter, Depends
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime, timedelta

router = APIRouter()


# ─── GET /weekly — top 10 users this week by study sessions ──────────────────

@router.get("/weekly")
async def get_weekly_leaderboard(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return top 10 users this week ranked by number of focus sessions."""
    now = datetime.utcnow()
    # Start of current week (Monday)
    start_of_week = (now - timedelta(days=now.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )

    pipeline = [
        {
            "$match": {
                "session_type": "focus",
                "created_at": {"$gte": start_of_week},
            }
        },
        {
            "$group": {
                "_id": "$user_id",
                "sessions_count": {"$sum": 1},
                "total_minutes": {"$sum": "$duration_minutes"},
            }
        },
        {"$sort": {"sessions_count": -1}},
        {"$limit": 10},
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

    results = await db["study_sessions"].aggregate(pipeline).to_list(10)

    leaderboard = []
    for rank, entry in enumerate(results, 1):
        username = "Unknown"
        if entry.get("user_info"):
            username = entry["user_info"].get("username", "Unknown")

        leaderboard.append({
            "rank": rank,
            "username": username,
            "sessions_count": entry["sessions_count"],
            "total_minutes": entry["total_minutes"],
            "is_current_user": entry["_id"] == current_user["_id"],
        })

    return leaderboard


# ─── GET /typing — top 10 users by best WPM ─────────────────────────────────

@router.get("/typing")
async def get_typing_leaderboard(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return top 10 users ranked by their best typing WPM."""
    pipeline = [
        {
            "$group": {
                "_id": "$user_id",
                "best_wpm": {"$max": "$wpm"},
            }
        },
        {"$sort": {"best_wpm": -1}},
        {"$limit": 10},
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

    results = await db["typing_results"].aggregate(pipeline).to_list(10)

    leaderboard = []
    for rank, entry in enumerate(results, 1):
        username = "Unknown"
        if entry.get("user_info"):
            username = entry["user_info"].get("username", "Unknown")

        leaderboard.append({
            "rank": rank,
            "username": username,
            "best_wpm": entry["best_wpm"],
            "is_current_user": entry["_id"] == current_user["_id"],
        })

    return leaderboard
