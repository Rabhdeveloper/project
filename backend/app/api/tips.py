from fastapi import APIRouter, Depends
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime, timedelta
import random

router = APIRouter()

MOTIVATIONAL_TIPS = [
    {"tip": "Start with just 15 minutes. Small steps build big habits! 🚀", "icon": "🚀", "category": "motivation"},
    {"tip": "The hardest part is starting. Open a book and read one page! 📖", "icon": "📖", "category": "motivation"},
    {"tip": "Consistency beats intensity. Show up every day, even briefly! 💪", "icon": "💪", "category": "motivation"},
    {"tip": "Set a tiny goal for today: 1 Pomodoro session. You got this! 🎯", "icon": "🎯", "category": "motivation"},
    {"tip": "Your future self will thank you for studying today! ⏳", "icon": "⏳", "category": "motivation"},
]

STREAK_TIPS = [
    {"tip": "🔥 {streak}-day streak! You're on fire! Don't break the chain!", "icon": "🔥", "category": "streak"},
    {"tip": "🏆 {streak} days in a row! You're building an unstoppable habit!", "icon": "🏆", "category": "streak"},
]

STUDY_TIPS = [
    {"tip": "Try the Pomodoro technique: 25 min focus + 5 min break! ⏱️", "icon": "⏱️", "category": "technique"},
    {"tip": "Review notes within 24 hours — retention jumps by 60%! 🧠", "icon": "🧠", "category": "technique"},
    {"tip": "Use flashcards with spaced repetition for long-term memory! 🃏", "icon": "🃏", "category": "technique"},
    {"tip": "Take breaks to let your brain consolidate information! 🌿", "icon": "🌿", "category": "technique"},
    {"tip": "Hydrate! Your brain is 75% water — drink up for focus! 💧", "icon": "💧", "category": "wellness"},
    {"tip": "Sleep 7-8 hours for better memory consolidation! 😴", "icon": "😴", "category": "wellness"},
]

TYPING_TIPS = [
    {"tip": "Your best typing speed is {wpm} WPM! Keep practicing! ⌨️", "icon": "⌨️", "category": "typing"},
    {"tip": "Focus on accuracy first, speed follows naturally! 🎯", "icon": "🎯", "category": "typing"},
]

HOUR_TIPS = [
    {"tip": "You study best around {hour}. Schedule hard tasks then! ⏰", "icon": "⏰", "category": "insight"},
]


@router.get("/daily")
async def get_daily_tip(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return a personalized daily study tip based on user data."""
    user_id = current_user["_id"]

    goal_doc = await db["user_goals"].find_one({"user_id": user_id})
    daily_target = goal_doc["daily_target"] if goal_doc else 4

    from app.api.goals import _compute_streak
    streak = await _compute_streak(db, user_id, daily_target)

    total_sessions = await db["study_sessions"].count_documents({
        "user_id": user_id, "session_type": "focus"
    })

    best_typing = await db["typing_results"].find_one(
        {"user_id": user_id}, sort=[("wpm", -1)]
    )
    best_wpm = best_typing["wpm"] if best_typing else 0

    focus_pipeline = [
        {"$match": {"user_id": user_id, "session_type": "focus"}},
        {"$group": {"_id": {"$hour": "$created_at"}, "count": {"$sum": 1}}},
        {"$sort": {"count": -1}}, {"$limit": 1},
    ]
    focus_result = await db["study_sessions"].aggregate(focus_pipeline).to_list(1)
    best_hour = focus_result[0]["_id"] if focus_result else None

    today_seed = int(datetime.utcnow().strftime("%Y%m%d"))
    random.seed(today_seed + hash(user_id))

    if streak == 0 and total_sessions == 0:
        tip = random.choice(MOTIVATIONAL_TIPS).copy()
    elif streak >= 7:
        tip = random.choice(STREAK_TIPS).copy()
        tip["tip"] = tip["tip"].format(streak=streak)
    elif best_wpm > 0 and random.random() < 0.3:
        tip = random.choice(TYPING_TIPS).copy()
        tip["tip"] = tip["tip"].format(wpm=best_wpm)
    elif best_hour is not None and random.random() < 0.25:
        display_hour = best_hour if best_hour <= 12 else best_hour - 12
        if display_hour == 0:
            display_hour = 12
        period = "AM" if best_hour < 12 else "PM"
        tip = random.choice(HOUR_TIPS).copy()
        tip["tip"] = tip["tip"].format(hour=f"{display_hour} {period}")
    elif streak == 0:
        tip = random.choice(MOTIVATIONAL_TIPS).copy()
    else:
        tip = random.choice(STUDY_TIPS).copy()

    random.seed()
    return tip
