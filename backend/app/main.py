from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.core.database import connect_to_mongo, close_mongo_connection
from app.api import auth

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
    version="1.0.0",
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

@app.get("/")
async def root():
    return {"message": "Welcome to the Smart Study Tracker API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
