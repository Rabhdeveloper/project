from fastapi import APIRouter, Depends
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime, timedelta

router = APIRouter()


# ─── GET /heatmap — 90-day study heatmap data ───────────────────────────────

@router.get("/heatmap")
async def get_heatmap(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return daily session counts for the last 90 days (heatmap data)."""
    now = datetime.utcnow()
    start = (now - timedelta(days=90)).replace(hour=0, minute=0, second=0, microsecond=0)

    pipeline = [
        {
            "$match": {
                "user_id": current_user["_id"],
                "session_type": "focus",
                "created_at": {"$gte": start},
            }
        },
        {
            "$group": {
                "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
                "sessions_count": {"$sum": 1},
                "total_minutes": {"$sum": "$duration_minutes"},
            }
        },
        {"$sort": {"_id": 1}},
    ]

    results = await db["study_sessions"].aggregate(pipeline).to_list(100)

    # Build a map for quick lookup
    data_map = {}
    for r in results:
        data_map[r["_id"]] = {
            "sessions_count": r["sessions_count"],
            "total_minutes": r["total_minutes"],
        }

    # Fill in all 90 days
    heatmap = []
    for i in range(90):
        day = (start + timedelta(days=i)).strftime("%Y-%m-%d")
        entry = data_map.get(day, {"sessions_count": 0, "total_minutes": 0})
        heatmap.append({
            "date": day,
            "sessions_count": entry["sessions_count"],
            "total_minutes": entry["total_minutes"],
        })

    return heatmap


# ─── GET /subjects — time breakdown by subject ──────────────────────────────

@router.get("/subjects")
async def get_subject_breakdown(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return total study time grouped by subject."""
    user_id = current_user["_id"]

    pipeline = [
        {"$match": {"user_id": user_id, "session_type": "focus"}},
        {
            "$group": {
                "_id": "$subject_id",
                "total_minutes": {"$sum": "$duration_minutes"},
                "session_count": {"$sum": 1},
            }
        },
        {"$sort": {"total_minutes": -1}},
    ]

    results = await db["study_sessions"].aggregate(pipeline).to_list(50)

    # Pre-fetch subjects
    subjects_map = {}
    subj_cursor = db["subjects"].find({"user_id": user_id})
    async for s in subj_cursor:
        subjects_map[s["_id"]] = s

    breakdown = []
    for entry in results:
        subj_id = entry["_id"]
        subj = subjects_map.get(subj_id) if subj_id else None
        breakdown.append({
            "subject_id": subj_id,
            "subject_name": subj["name"] if subj else "Untagged",
            "subject_color": subj["color"] if subj else "#64748B",
            "total_minutes": entry["total_minutes"],
            "session_count": entry["session_count"],
        })

    return breakdown


# ─── GET /trends — weekly averages over last 8 weeks ────────────────────────

@router.get("/trends")
async def get_weekly_trends(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return weekly averages for sessions and typing WPM over the last 8 weeks."""
    user_id = current_user["_id"]
    now = datetime.utcnow()
    eight_weeks_ago = now - timedelta(weeks=8)

    # Study sessions by week
    study_pipeline = [
        {
            "$match": {
                "user_id": user_id,
                "session_type": "focus",
                "created_at": {"$gte": eight_weeks_ago},
            }
        },
        {
            "$group": {
                "_id": {"$dateToString": {"format": "%Y-W%V", "date": "$created_at"}},
                "avg_sessions": {"$sum": 1},
                "avg_minutes": {"$sum": "$duration_minutes"},
            }
        },
        {"$sort": {"_id": 1}},
    ]

    study_results = await db["study_sessions"].aggregate(study_pipeline).to_list(10)

    # Typing WPM by week
    typing_pipeline = [
        {
            "$match": {
                "user_id": user_id,
                "created_at": {"$gte": eight_weeks_ago},
            }
        },
        {
            "$group": {
                "_id": {"$dateToString": {"format": "%Y-W%V", "date": "$created_at"}},
                "avg_wpm": {"$avg": "$wpm"},
            }
        },
        {"$sort": {"_id": 1}},
    ]

    typing_results = await db["typing_results"].aggregate(typing_pipeline).to_list(10)

    # Merge into a single list
    typing_map = {r["_id"]: round(r["avg_wpm"], 1) for r in typing_results}

    trends = []
    for entry in study_results:
        week = entry["_id"]
        trends.append({
            "week_label": week,
            "total_sessions": entry["avg_sessions"],
            "total_minutes": entry["avg_minutes"],
            "avg_wpm": typing_map.get(week),
        })

    return trends


# ─── GET /focus-hours — most productive hours ───────────────────────────────

@router.get("/focus-hours")
async def get_focus_hours(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return session count grouped by hour of the day (0-23)."""
    pipeline = [
        {"$match": {"user_id": current_user["_id"], "session_type": "focus"}},
        {
            "$group": {
                "_id": {"$hour": "$created_at"},
                "session_count": {"$sum": 1},
            }
        },
        {"$sort": {"_id": 1}},
    ]

    results = await db["study_sessions"].aggregate(pipeline).to_list(24)

    # Fill all 24 hours
    hour_map = {r["_id"]: r["session_count"] for r in results}
    hours = []
    for h in range(24):
        hours.append({
            "hour": h,
            "session_count": hour_map.get(h, 0),
        })

    return hours
