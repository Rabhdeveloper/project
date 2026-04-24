from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


# ─── Achievement Definitions (hardcoded) ───────────────────────────────────────

ACHIEVEMENT_DEFS = [
    {
        "id": "first_flame",
        "title": "First Flame",
        "description": "Complete 1 study session",
        "icon": "🔥",
    },
    {
        "id": "bookworm",
        "title": "Bookworm",
        "description": "Complete 10 study sessions",
        "icon": "📚",
    },
    {
        "id": "century_club",
        "title": "Century Club",
        "description": "Complete 100 study sessions",
        "icon": "🏆",
    },
    {
        "id": "speed_demon",
        "title": "Speed Demon",
        "description": "Reach 60+ WPM in typing",
        "icon": "⚡",
    },
    {
        "id": "sharpshooter",
        "title": "Sharpshooter",
        "description": "Reach 95%+ accuracy in typing",
        "icon": "🎯",
    },
    {
        "id": "week_warrior",
        "title": "Week Warrior",
        "description": "7-day study streak",
        "icon": "📅",
    },
    {
        "id": "month_master",
        "title": "Month Master",
        "description": "30-day study streak",
        "icon": "🗓️",
    },
    {
        "id": "typing_veteran",
        "title": "Typing Veteran",
        "description": "Complete 50 typing tests",
        "icon": "⌨️",
    },
    {
        "id": "perfectionist",
        "title": "Perfectionist",
        "description": "Score 100% accuracy in a typing test",
        "icon": "🌟",
    },
    {
        "id": "diamond_focus",
        "title": "Diamond Focus",
        "description": "Study 10+ hours total",
        "icon": "💎",
    },
]


# ─── Pydantic Models ──────────────────────────────────────────────────────────

class UserAchievement(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    user_id: str
    achievement_id: str
    unlocked_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True


class AchievementResponse(BaseModel):
    id: str
    title: str
    description: str
    icon: str
    unlocked: bool = False
    unlocked_at: Optional[datetime] = None
