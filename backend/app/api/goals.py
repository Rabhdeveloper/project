from fastapi import APIRouter, Depends, status
from app.models.goals import UserGoalUpdate, GoalResponse, TodayProgressResponse
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime, timedelta
import uuid

router = APIRouter()


# ─── Helper: compute streak ──────────────────────────────────────────────────

async def _compute_streak(db, user_id: str, daily_target: int) -> int:
    """Count consecutive days (backwards from yesterday) where user met their goal.
    Today is only counted if the goal is already met."""
    streak = 0
    today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)

    # Check up to 365 days back
    for i in range(0, 365):
        day_start = today - timedelta(days=i)
        day_end = day_start + timedelta(days=1)

        count = await db["study_sessions"].count_documents({
            "user_id": user_id,
            "session_type": "focus",
            "created_at": {"$gte": day_start, "$lt": day_end},
        })

        if count >= daily_target:
            streak += 1
        else:
            # If today hasn't been met yet, that's okay — skip to yesterday
            if i == 0:
                continue
            break

    return streak


# ─── GET / — get user's daily goal + current streak ──────────────────────────

@router.get("/", response_model=GoalResponse)
async def get_goal(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return the user's daily goal and current streak."""
    goal_doc = await db["user_goals"].find_one({"user_id": current_user["_id"]})
    daily_target = goal_doc["daily_target"] if goal_doc else 4

    streak = await _compute_streak(db, current_user["_id"], daily_target)

    return GoalResponse(daily_target=daily_target, current_streak=streak)


# ─── PUT / — update daily goal ───────────────────────────────────────────────

@router.put("/", response_model=GoalResponse)
async def update_goal(
    body: UserGoalUpdate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Create or update the user's daily session goal."""
    await db["user_goals"].update_one(
        {"user_id": current_user["_id"]},
        {
            "$set": {"daily_target": body.daily_target},
            "$setOnInsert": {
                "_id": str(uuid.uuid4()),
                "user_id": current_user["_id"],
                "created_at": datetime.utcnow(),
            },
        },
        upsert=True,
    )

    streak = await _compute_streak(db, current_user["_id"], body.daily_target)
    return GoalResponse(daily_target=body.daily_target, current_streak=streak)


# ─── GET /today — today's progress ──────────────────────────────────────────

@router.get("/today", response_model=TodayProgressResponse)
async def get_today_progress(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return today's session count vs daily target."""
    goal_doc = await db["user_goals"].find_one({"user_id": current_user["_id"]})
    daily_target = goal_doc["daily_target"] if goal_doc else 4

    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)

    sessions_done = await db["study_sessions"].count_documents({
        "user_id": current_user["_id"],
        "session_type": "focus",
        "created_at": {"$gte": today_start, "$lt": today_end},
    })

    return TodayProgressResponse(
        sessions_done=sessions_done,
        daily_target=daily_target,
        completed=sessions_done >= daily_target,
    )
