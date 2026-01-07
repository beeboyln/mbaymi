@echo off
REM Setup script for Mbaymi Flutter Frontend on Windows

echo.
echo ====================================
echo Mbaymi Flutter Frontend Setup
echo ====================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

echo Flutter found:
flutter --version
echo.

REM Get dependencies
echo [1/2] Getting Flutter dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get Flutter dependencies
    pause
    exit /b 1
)
echo Dependencies installed successfully.
echo.

REM Check for devices
echo [2/2] Checking available devices...
echo.
flutter devices
echo.

echo ====================================
echo Setup Complete!
echo ====================================
echo.
echo Available commands:
echo   flutter run          - Run on default device
echo   flutter run -d android-emulator  - Run on Android Emulator
echo   flutter run -d chrome            - Run on Web
echo   flutter build apk --release      - Build Android APK
echo.
echo IMPORTANT: Make sure API_SERVICE baseUrl points to your backend!
echo Edit: lib/services/api_service.dart
echo.
pause
