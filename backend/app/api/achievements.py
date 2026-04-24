from fastapi import APIRouter, Depends
from app.models.achievements import ACHIEVEMENT_DEFS, AchievementResponse
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime
import uuid

router = APIRouter()


# ─── Helper: evaluate achievement conditions ─────────────────────────────────

async def _evaluate(db, user_id: str, achievement_id: str, daily_target: int = 4) -> bool:
    """Check if a specific achievement condition is met."""

    if achievement_id == "first_flame":
        count = await db["study_sessions"].count_documents({
            "user_id": user_id, "session_type": "focus"
        })
        return count >= 1

    elif achievement_id == "bookworm":
        count = await db["study_sessions"].count_documents({
            "user_id": user_id, "session_type": "focus"
        })
        return count >= 10

    elif achievement_id == "century_club":
        count = await db["study_sessions"].count_documents({
            "user_id": user_id, "session_type": "focus"
        })
        return count >= 100

    elif achievement_id == "speed_demon":
        best = await db["typing_results"].find_one(
            {"user_id": user_id, "wpm": {"$gte": 60}}
        )
        return best is not None

    elif achievement_id == "sharpshooter":
        best = await db["typing_results"].find_one(
            {"user_id": user_id, "accuracy": {"$gte": 95.0}}
        )
        return best is not None

    elif achievement_id == "week_warrior":
        # Use the streak computation from goals module
        from app.api.goals import _compute_streak
        streak = await _compute_streak(db, user_id, daily_target)
        return streak >= 7

    elif achievement_id == "month_master":
        from app.api.goals import _compute_streak
        streak = await _compute_streak(db, user_id, daily_target)
        return streak >= 30

    elif achievement_id == "typing_veteran":
        count = await db["typing_results"].count_documents({"user_id": user_id})
        return count >= 50

    elif achievement_id == "perfectionist":
        perfect = await db["typing_results"].find_one(
            {"user_id": user_id, "accuracy": 100.0}
        )
        return perfect is not None

    elif achievement_id == "diamond_focus":
        pipeline = [
            {"$match": {"user_id": user_id, "session_type": "focus"}},
            {"$group": {"_id": None, "total_minutes": {"$sum": "$duration_minutes"}}},
        ]
        result = await db["study_sessions"].aggregate(pipeline).to_list(1)
        if result:
            return result[0]["total_minutes"] >= 600  # 10 hours
        return False

    return False


# ─── GET / — list all achievements with locked/unlocked status ───────────────

@router.get("/", response_model=list[AchievementResponse])
async def get_achievements(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return all achievement definitions with the user's unlock status."""
    # Fetch all user achievements
    user_achievements = {}
    cursor = db["user_achievements"].find({"user_id": current_user["_id"]})
    async for doc in cursor:
        user_achievements[doc["achievement_id"]] = doc.get("unlocked_at")

    result = []
    for defn in ACHIEVEMENT_DEFS:
        unlocked_at = user_achievements.get(defn["id"])
        result.append(AchievementResponse(
            id=defn["id"],
            title=defn["title"],
            description=defn["description"],
            icon=defn["icon"],
            unlocked=unlocked_at is not None,
            unlocked_at=unlocked_at,
        ))
    return result


# ─── POST /check — re-evaluate and unlock new badges ────────────────────────

@router.post("/check")
async def check_achievements(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Re-evaluate all conditions and unlock any newly earned achievements.
    Returns a list of newly unlocked achievement IDs."""
    user_id = current_user["_id"]

    # Get user's daily target for streak-based achievements
    goal_doc = await db["user_goals"].find_one({"user_id": user_id})
    daily_target = goal_doc["daily_target"] if goal_doc else 4

    # Get currently unlocked achievements
    already_unlocked = set()
    cursor = db["user_achievements"].find({"user_id": user_id})
    async for doc in cursor:
        already_unlocked.add(doc["achievement_id"])

    newly_unlocked = []

    for defn in ACHIEVEMENT_DEFS:
        if defn["id"] in already_unlocked:
            continue

        if await _evaluate(db, user_id, defn["id"], daily_target):
            now = datetime.utcnow()
            await db["user_achievements"].insert_one({
                "_id": str(uuid.uuid4()),
                "user_id": user_id,
                "achievement_id": defn["id"],
                "unlocked_at": now,
            })
            newly_unlocked.append({
                "id": defn["id"],
                "title": defn["title"],
                "icon": defn["icon"],
            })

    return {"newly_unlocked": newly_unlocked}
