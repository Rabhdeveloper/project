from fastapi import APIRouter, Depends, status
from app.models.user import TypingResultCreate, TypingResultResponse
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime
import uuid

router = APIRouter()


# ─── POST /  — Save a typing result ───────────────────────────────────────────

@router.post("/", response_model=TypingResultResponse, status_code=status.HTTP_201_CREATED)
async def create_typing_result(
    result: TypingResultCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Save a completed typing test result for the authenticated user."""
    result_id = str(uuid.uuid4())
    now = datetime.utcnow()

    doc = {
        "_id": result_id,
        "user_id": current_user["_id"],
        "wpm": result.wpm,
        "accuracy": result.accuracy,
        "duration_seconds": result.duration_seconds,
        "created_at": now,
    }

    await db["typing_results"].insert_one(doc)

    return TypingResultResponse(
        id=result_id,
        wpm=result.wpm,
        accuracy=result.accuracy,
        duration_seconds=result.duration_seconds,
        created_at=now,
    )


# ─── GET /  — List all typing results for user ────────────────────────────────

@router.get("/", response_model=list[TypingResultResponse])
async def get_typing_results(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return all typing results for the authenticated user, newest first."""
    cursor = db["typing_results"].find(
        {"user_id": current_user["_id"]}
    ).sort("created_at", -1)

    results = []
    async for doc in cursor:
        results.append(TypingResultResponse(
            id=doc["_id"],
            wpm=doc["wpm"],
            accuracy=doc["accuracy"],
            duration_seconds=doc.get("duration_seconds", 0),
            created_at=doc["created_at"],
        ))
    return results


# ─── GET /best  — Personal best + averages ────────────────────────────────────

@router.get("/best")
async def get_typing_best(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return personal best WPM, average WPM, average accuracy, and total tests."""
    pipeline = [
        {"$match": {"user_id": current_user["_id"]}},
        {"$group": {
            "_id": None,
            "best_wpm": {"$max": "$wpm"},
            "average_wpm": {"$avg": "$wpm"},
            "average_accuracy": {"$avg": "$accuracy"},
            "total_tests": {"$sum": 1},
        }},
    ]
    result = await db["typing_results"].aggregate(pipeline).to_list(1)

    if not result:
        return {
            "best_wpm": 0,
            "average_wpm": 0.0,
            "average_accuracy": 0.0,
            "total_tests": 0,
        }

    stats = result[0]
    return {
        "best_wpm": stats["best_wpm"],
        "average_wpm": round(stats["average_wpm"], 1),
        "average_accuracy": round(stats["average_accuracy"], 1),
        "total_tests": stats["total_tests"],
    }
