from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.core.database import connect_to_mongo, close_mongo_connection
from app.api import auth, sessions, typing

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
    version="2.0.0",
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

# Include Routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(sessions.router, prefix="/api/sessions", tags=["Study Sessions"])
app.include_router(typing.router, prefix="/api/typing", tags=["Typing Results"])

@app.get("/")
async def root():
    return {"message": "Welcome to the Smart Study Tracker API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
