from fastapi import APIRouter, Depends, status
from app.models.user import StudySessionCreate, StudySessionResponse
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime, timedelta
import uuid

router = APIRouter()


# ─── POST /  — Save a completed study session ─────────────────────────────────

@router.post("/", response_model=StudySessionResponse, status_code=status.HTTP_201_CREATED)
async def create_session(
    session: StudySessionCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Save a completed Pomodoro session for the authenticated user."""
    session_id = str(uuid.uuid4())
    now = datetime.utcnow()

    doc = {
        "_id": session_id,
        "user_id": current_user["_id"],
        "duration_minutes": session.duration_minutes,
        "session_type": session.session_type,
        "subject_id": session.subject_id,
        "created_at": now,
    }

    await db["study_sessions"].insert_one(doc)

    return StudySessionResponse(
        id=session_id,
        duration_minutes=session.duration_minutes,
        session_type=session.session_type,
        subject_id=session.subject_id,
        created_at=now,
    )


# ─── GET /  — List all sessions for user ──────────────────────────────────────

@router.get("/", response_model=list[StudySessionResponse])
async def get_sessions(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return all study sessions for the authenticated user, newest first."""
    cursor = db["study_sessions"].find(
        {"user_id": current_user["_id"]}
    ).sort("created_at", -1)

    sessions = []
    async for doc in cursor:
        sessions.append(StudySessionResponse(
            id=doc["_id"],
            duration_minutes=doc["duration_minutes"],
            session_type=doc.get("session_type", "focus"),
            subject_id=doc.get("subject_id"),
            created_at=doc["created_at"],
        ))
    return sessions


# ─── GET /weekly  — Last 7 days grouped by day ────────────────────────────────

@router.get("/weekly")
async def get_weekly_sessions(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return sessions grouped by day for the last 7 days."""
    now = datetime.utcnow()
    seven_days_ago = now - timedelta(days=7)

    cursor = db["study_sessions"].find({
        "user_id": current_user["_id"],
        "created_at": {"$gte": seven_days_ago},
    }).sort("created_at", 1)

    # Bucket by date string
    daily: dict[str, dict] = {}
    async for doc in cursor:
        date_str = doc["created_at"].strftime("%Y-%m-%d")
        if date_str not in daily:
            daily[date_str] = {"date": date_str, "count": 0, "total_minutes": 0}
        daily[date_str]["count"] += 1
        daily[date_str]["total_minutes"] += doc.get("duration_minutes", 25)

    # Fill in missing days with zeros
    result = []
    for i in range(7):
        day = (now - timedelta(days=6 - i)).strftime("%Y-%m-%d")
        if day in daily:
            result.append(daily[day])
        else:
            result.append({"date": day, "count": 0, "total_minutes": 0})

    return result


# ─── GET /stats  — Aggregated totals ──────────────────────────────────────────

@router.get("/stats")
async def get_session_stats(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return aggregated study stats for the authenticated user."""
    pipeline = [
        {"$match": {"user_id": current_user["_id"]}},
        {"$group": {
            "_id": None,
            "total_sessions": {"$sum": 1},
            "total_minutes": {"$sum": "$duration_minutes"},
        }},
    ]
    result = await db["study_sessions"].aggregate(pipeline).to_list(1)

    if not result:
        return {
            "total_sessions": 0,
            "total_hours": 0.0,
            "best_day": None,
            "best_day_count": 0,
        }

    stats = result[0]

    # Find best day
    best_day_pipeline = [
        {"$match": {"user_id": current_user["_id"]}},
        {"$group": {
            "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
            "count": {"$sum": 1},
        }},
        {"$sort": {"count": -1}},
        {"$limit": 1},
    ]
    best_day_result = await db["study_sessions"].aggregate(best_day_pipeline).to_list(1)
    best_day = best_day_result[0]["_id"] if best_day_result else None
    best_day_count = best_day_result[0]["count"] if best_day_result else 0

    return {
        "total_sessions": stats["total_sessions"],
        "total_hours": round(stats["total_minutes"] / 60, 1),
        "best_day": best_day,
        "best_day_count": best_day_count,
    }
