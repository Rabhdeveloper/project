from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.core.database import connect_to_mongo, close_mongo_connection
from app.api import (
    auth, sessions, typing, goals, achievements, subjects, leaderboard,
    friends, activity, notes, flashcards, analytics, tips, reminders,
    rooms, schedule, developer,
    spatial, biometrics, auto_courses, web3_creds,
    iot, ai_avatar, security_api,
)
from app.security.audit_logger import audit_logger
from app.core.database import get_database
from datetime import datetime

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
    version="11.0.0",
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


# ─── Zero-Trust Audit Middleware (Level 11) ───────────────────────────────────
@app.middleware("http")
async def audit_middleware(request: Request, call_next):
    """Log every API request to the immutable audit trail."""
    response = await call_next(request)
    
    # Only audit authenticated API endpoints (skip health/docs)
    if request.url.path.startswith("/api/"):
        try:
            db = get_database()
            if db is not None:
                log_entry = audit_logger.create_log_entry(
                    user_id="system",  # Will be enriched by auth context in production
                    action=request.method,
                    resource=request.url.path,
                    details={"status_code": response.status_code},
                    ip_address=request.client.host if request.client else "unknown",
                )
                await db["audit_logs"].insert_one(log_entry)
        except Exception:
            pass  # Audit logging should never block requests
    
    return response


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

# Level 5
app.include_router(rooms.router, prefix="/api/rooms", tags=["Rooms"])

# Level 6
app.include_router(schedule.router, prefix="/api/schedule", tags=["Schedule"])
app.include_router(developer.router, prefix="/api/developer", tags=["Developer API"])

# Level 7 — Spatial Computing & AR/VR
app.include_router(spatial.router, prefix="/api/spatial", tags=["Spatial Computing"])

# Level 8 — Biometric Integration
app.include_router(biometrics.router, prefix="/api/biometrics", tags=["Biometrics"])

# Level 9 — Knowledge Graph & Credentials
app.include_router(auto_courses.router, prefix="/api/courses", tags=["AI Courses"])
app.include_router(web3_creds.router, prefix="/api/credentials", tags=["Web3 Credentials"])

# Level 10 — IoT & Contextual Intelligence
app.include_router(iot.router, prefix="/api/iot", tags=["IoT & Smart Home"])
app.include_router(ai_avatar.router, prefix="/api/avatar", tags=["AI Avatar"])

# Level 11 — Zero-Trust Security
app.include_router(security_api.router, prefix="/api/security", tags=["Security"])

@app.get("/")
async def root():
    return {"message": "Welcome to the Smart Study Tracker API", "version": "11.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "11.0.0"}
