from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.core.database import connect_to_mongo, close_mongo_connection
from app.api import (
    auth, sessions, typing, goals, achievements, subjects, leaderboard,
    friends, activity, notes, flashcards, analytics, tips, reminders,
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup loop
    connect_to_mongo()
    yield
    # Shutdown loop
    close_mongo_connection()

app = FastAPI(
    title="Smart Study & Productivity Tracker API",
    description="Backend API for real-time tracking of study sessions and typing practice.",
    version="4.0.0",
    lifespan=lifespan
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers — Level 1–2
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(sessions.router, prefix="/api/sessions", tags=["Study Sessions"])
app.include_router(typing.router, prefix="/api/typing", tags=["Typing Results"])

# Level 3
app.include_router(goals.router, prefix="/api/goals", tags=["Goals & Streaks"])
app.include_router(achievements.router, prefix="/api/achievements", tags=["Achievements"])
app.include_router(subjects.router, prefix="/api/subjects", tags=["Subjects"])
app.include_router(leaderboard.router, prefix="/api/leaderboard", tags=["Leaderboard"])

# Level 4
app.include_router(friends.router, prefix="/api/friends", tags=["Friends"])
app.include_router(activity.router, prefix="/api/activity", tags=["Activity Feed"])
app.include_router(notes.router, prefix="/api/notes", tags=["Notes"])
app.include_router(flashcards.router, prefix="/api/flashcards", tags=["Flashcards"])
app.include_router(analytics.router, prefix="/api/analytics", tags=["Analytics"])
app.include_router(tips.router, prefix="/api/tips", tags=["Study Tips"])
app.include_router(reminders.router, prefix="/api/reminders", tags=["Reminders"])

@app.get("/")
async def root():
    return {"message": "Welcome to the Smart Study Tracker API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
