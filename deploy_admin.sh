#!/bin/bash

echo "========================================"
echo "Building Admin Dashboard Web App"
echo "========================================"
echo ""

echo "Step 1: Cleaning previous build..."
flutter clean

echo ""
echo "Step 2: Getting dependencies..."
flutter pub get

echo ""
echo "Step 3: Building web app (this may take a few minutes)..."
flutter build web --release --target=lib/main_admin.dart

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Build failed!"
    exit 1
fi

echo ""
echo "Step 4: Deploying to Firebase Hosting..."
firebase deploy --only hosting

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Deployment failed!"
    exit 1
fi

echo ""
echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""
echo "Your admin dashboard is now live at:"
echo "https://daydream-20e85.web.app"
echo ""

