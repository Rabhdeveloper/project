@echo off
echo =======================================================================
echo Starting Real-Time Smart Study ^& Productivity Tracker...
echo =======================================================================

:: 1. Start Infrastructure (MongoDB and Redis)
echo.
echo [1/3] Starting MongoDB and Redis via Docker Compose...
docker-compose up -d

:: 2. Start Backend (FastAPI)
echo.
echo [2/3] Setting up Python Backend...
cd backend

IF NOT EXIST venv (
    echo Creating virtual environment...
    python -m venv venv
)

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo Installing dependencies...
pip install -r requirements.txt

echo.
echo =======================================================================
echo Starting FastAPI proxy in a background window...
echo =======================================================================
start "FastAPI Server" cmd /k "call venv\Scripts\activate.bat && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

cd ..

:: 3. Start Frontend (Flutter)
echo.
echo [3/3] Starting Flutter Frontend...
cd frontend
flutter run -d chrome

echo =======================================================================
echo Done. To stop background docker containers, run 'docker-compose stop'
echo Close the 'FastAPI Server' command window to stop the backend.
echo =======================================================================
