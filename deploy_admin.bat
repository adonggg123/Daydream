@echo off
echo ========================================
echo Building Admin Dashboard Web App
echo ========================================
echo.

echo Step 1: Cleaning previous build...
flutter clean

echo.
echo Step 2: Getting dependencies...
flutter pub get

echo.
echo Step 3: Building web app (this may take a few minutes)...
flutter build web --release --target=lib/main_admin.dart

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo Step 4: Deploying to Firebase Hosting...
firebase deploy --only hosting

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Deployment failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Your admin dashboard is now live at:
echo https://daydream-20e85.web.app
echo.
pause

