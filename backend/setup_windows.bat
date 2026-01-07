@echo off
REM Setup script for Mbaymi Backend on Windows

echo.
echo ====================================
echo Mbaymi Backend Setup (Windows)
echo ====================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python from https://www.python.org/downloads/
    pause
    exit /b 1
)

echo [1/5] Python found:
python --version
echo.

REM Create virtual environment
echo [2/5] Creating virtual environment...
if exist venv (
    echo Virtual environment already exists, skipping creation.
) else (
    python -m venv venv
    if errorlevel 1 (
        echo ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
    echo Virtual environment created successfully.
)
echo.

REM Activate virtual environment
echo [3/5] Activating virtual environment...
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo ERROR: Failed to activate virtual environment
    pause
    exit /b 1
)
echo Virtual environment activated.
echo.

REM Upgrade pip
echo [4/5] Upgrading pip...
python -m pip install --upgrade pip
if errorlevel 1 (
    echo WARNING: pip upgrade may have failed, continuing anyway...
)
echo.

REM Install requirements
echo [5/5] Installing requirements...
pip install -r requirements.txt
if errorlevel 1 (
    echo ERROR: Failed to install requirements
    echo Try running: pip install -r requirements.txt
    pause
    exit /b 1
)
echo Requirements installed successfully.
echo.

REM Copy .env.example to .env if it doesn't exist
if not exist .env (
    echo Creating .env from .env.example...
    copy .env.example .env
    echo.
    echo IMPORTANT: Edit .env and add your DATABASE_URL from Neon PostgreSQL
    echo Example: DATABASE_URL=postgresql://user:password@host/dbname
    echo.
) else (
    echo .env already exists, skipping creation.
)
echo.

echo ====================================
echo Setup Complete!
echo ====================================
echo.
echo Next steps:
echo 1. Edit .env with your DATABASE_URL from Neon PostgreSQL
echo 2. Run: uvicorn app.main:app --reload
echo.
echo To deactivate virtual environment later, run: deactivate
echo.
pause
