@echo off
REM Run Mbaymi Backend

echo.
echo Starting Mbaymi API...
echo.

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Run FastAPI
echo Uvicorn starting on http://localhost:8000
echo API Documentation: http://localhost:8000/docs
echo.

uvicorn app.main:app --reload
