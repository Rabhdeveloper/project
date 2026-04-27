from fastapi import APIRouter, Depends
from app.api.auth import get_current_user
from app.models.user import UserInDB
from app.core.ml_engine import ml_engine
from app.core.database import get_database

router = APIRouter()

@router.get("/optimal")
async def get_optimal_schedule(current_user: UserInDB = Depends(get_current_user)):
    """
    Returns an AI-optimized schedule itinerary based on the user's history.
    """
    # Fetch current streak from the database to feed to the ML engine
    # For now, we will query the goals collection or default to 0 if not implemented easily
    db = get_database()
    goal = await db["goals"].find_one({"user_id": str(current_user.id)})
    current_streak = goal.get("streak", 0) if goal else 0
    
    prediction = ml_engine.predict_optimal_duration(
        user_id=str(current_user.id), 
        current_streak=current_streak
    )
    
    return {
        "status": "success",
        "data": prediction
    }
