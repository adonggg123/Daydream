# How to Run the Daydream Resort App

## Quick Start Guide

The app **automatically creates all 7 rooms** when you run it. You don't need to do anything manually!

---

## Step-by-Step Instructions

### Step 1: Open Terminal/Command Prompt

1. Open your terminal/command prompt in the project directory:
   ```
   C:\Users\judej\Desktop\daydream
   ```

### Step 2: Install Dependencies (if not already done)

```bash
flutter pub get
```

### Step 3: Check Available Devices

```bash
flutter devices
```

This will show you available devices (Windows, Chrome, Android emulator, etc.)

### Step 4: Run the App

Choose one of these options:

#### Option A: Run on Windows Desktop (Recommended)
```bash
flutter run -d windows
```

#### Option B: Run on Web (Chrome)
```bash
flutter run -d chrome
```

#### Option C: Run on Android Device/Emulator
```bash
flutter run
```
(Select your Android device when prompted)

#### Option D: Run on Specific Device
```bash
flutter run -d <device-id>
```
(Use the device ID from `flutter devices`)

---

## What Happens When You Run the App

1. **App Starts**: The Flutter app launches
2. **Firebase Initializes**: Firebase connects to your project
3. **Rooms Are Created**: The app automatically:
   - Clears any existing rooms in Firestore
   - Creates all 7 rooms with images, descriptions, and prices
   - Saves them to Firestore database
4. **Home Page Loads**: All rooms are displayed with images
5. **Ready to Use**: You can browse rooms and click "Book Now"

---

## Troubleshooting

### If rooms don't appear:

1. **Check Firebase Connection**:
   - Make sure `google-services.json` is in `android/app/`
   - Verify Firebase is initialized in `main.dart`

2. **Check Firestore Rules**:
   - Go to Firebase Console → Firestore Database → Rules
   - Make sure read access is allowed:
   ```javascript
   match /rooms/{document} {
     allow read: if true;
   }
   ```

3. **Check Console Logs**:
   - Look for debug messages like:
     - "Created room: Poolside Villa"
     - "Total rooms created: 7"
     - "Loaded 7 rooms"

4. **Pull to Refresh**:
   - On the home page, pull down to refresh
   - This will reload rooms from Firestore

5. **Restart the App**:
   - Stop the app (Ctrl+C in terminal)
   - Run again: `flutter run -d windows`

---

## Available Commands

```bash
# Run on Windows
flutter run -d windows

# Run on Web
flutter run -d chrome

# Run on Android
flutter run -d android

# Hot Reload (while app is running)
# Press 'r' in terminal

# Hot Restart (while app is running)
# Press 'R' in terminal

# Stop the app
# Press 'q' in terminal or Ctrl+C
```

---

## Expected Behavior

When you run the app:

1. ✅ **Landing Page** appears first (if not logged in)
2. ✅ **Login/Register** to access the app
3. ✅ **Home Page** shows all 7 rooms with images
4. ✅ **Click any room** to see details
5. ✅ **Click "Book Now"** to start booking
6. ✅ **Social Feed** section at the bottom

---

## Room Creation Process

The app uses `forceInitializeRooms()` which:

1. **Deletes** all existing rooms in Firestore
2. **Creates** 7 new rooms:
   - Poolside Villa ($349.99)
   - Ocean View Suite ($299.99)
   - Infinity Pool Penthouse ($599.99)
   - Tropical Garden Bungalow ($199.99)
   - Luxury Pool Suite ($249.99)
   - Family Pool Villa ($449.99)
   - Beachfront Deluxe ($279.99)
3. **Saves** each room to Firestore
4. **Loads** all rooms on the home page

**This happens automatically every time you run the app!**

---

## Need Help?

If you encounter issues:

1. Check the terminal for error messages
2. Check Firebase Console to see if rooms were created
3. Verify your internet connection (needed for Firestore)
4. Make sure Firebase is properly configured

---

## Quick Test

To verify rooms are being created:

1. Run the app: `flutter run -d windows`
2. Login/Register
3. Check the home page - you should see 7 room cards
4. Check Firebase Console → Firestore → `rooms` collection
5. You should see 7 documents (room1, room2, ..., room7)

