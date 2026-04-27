#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting Real-Time Smart Study & Productivity Tracker..."

# 1. Start Infrastructure (MongoDB and Redis)
echo "📦 Starting MongoDB and Redis via Docker Compose..."
docker-compose up -d

# 2. Start Backend (FastAPI)
echo "🐍 Setting up Python Backend..."
cd backend

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    python -m venv venv
    echo "Virtual environment created."
fi

# Activate virtual environment (handles Git Bash on Windows vs Linux/Mac)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi

# Install dependencies
pip install -r requirements.txt

# Start FastAPI server in the background
echo "🔥 Starting FastAPI server on http://localhost:8000..."
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

# Go back to the root directory
cd ..

# 3. Start Frontend (Flutter)
echo "📱 Starting Flutter Frontend..."
cd frontend
flutter run -d chrome

# 4. Cleanup when the script completes/is terminated
cleanup() {
    echo "🛑 Stopping services..."
    echo "Stopping FastAPI..."
    kill $BACKEND_PID 2>/dev/null
    
    # Optional: Stop docker containers if preferred by removing the comment
    # echo "Stopping Docker containers..."
    # docker-compose stop
    
    echo "Done."
}

trap cleanup EXIT
