@echo off
REM Test API endpoints from command line

echo.
echo ====================================
echo Mbaymi API Test
echo ====================================
echo.

REM Test main endpoint
echo Testing GET http://localhost:8000/
curl -s http://localhost:8000/ | powershell -Command "ConvertFrom-Json | ConvertTo-Json"
echo.

REM Test health
echo Testing GET http://localhost:8000/health
curl -s http://localhost:8000/health | powershell -Command "ConvertFrom-Json | ConvertTo-Json"
echo.

REM Test Swagger
echo Testing GET http://localhost:8000/docs
curl -I http://localhost:8000/docs 2>&1 | findstr "HTTP"
echo.

echo Done!
