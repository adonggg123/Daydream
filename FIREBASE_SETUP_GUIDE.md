# Firebase Setup Guide for Edit Profile Feature

## ✅ What's Already Configured

Your Firebase project is properly initialized:
- Project ID: `daydream-20e85`
- Firebase Core, Auth, Firestore, and Storage are all configured
- The app is connected to Firebase
- **Firestore rules** currently allow read/write until Dec 2025 (temporary, but works for now)

## ⚠️ IMPORTANT: You MUST Configure Storage Rules in Firebase Console

The code will work, but you need to deploy the Storage rules to Firebase Console for profile picture uploads to work.

### Step 1: Configure Firestore Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **daydream-20e85**
3. Go to **Firestore Database** → **Rules**
4. Update the rules to allow users to update their own profile:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can read/update their own profile
    match /users/{userId} {
      // Allow users to read their own profile
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Allow users to update their own profile (displayName, photoUrl)
      allow update: if request.auth != null && request.auth.uid == userId
        && request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['displayName', 'photoUrl']);
      
      // Allow creation if user is creating their own profile
      allow create: if request.auth != null && request.auth.uid == userId;
    }
    
    // Add your existing rules below for other collections
    // ... (rooms, bookings, etc.)
  }
}
```

5. Click **Publish** to save the rules

### Step 2: Configure Storage Rules (REQUIRED for Photo Upload)

**I've created a `storage.rules` file in your project. Now you need to deploy it:**

#### Option A: Deploy via Firebase CLI (Recommended)

1. Install Firebase CLI if you haven't:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Deploy the storage rules:
   ```bash
   firebase deploy --only storage
   ```

#### Option B: Manual Setup in Firebase Console

1. In Firebase Console, go to **Storage** → **Rules**
2. Copy and paste these rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile pictures - users can upload/delete their own
    match /profiles/{userId}/{allPaths=**} {
      // Allow read for authenticated users
      allow read: if request.auth != null;
      
      // Allow write (upload/delete) only for the owner
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Room images - allow read for all, write for admins (adjust as needed)
    match /rooms/{roomId}/{allPaths=**} {
      allow read: if request.auth != null;
      // Add admin-only write rules if needed
    }
    
    // Default: deny all other paths
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

3. Click **Publish** to save the rules

### Step 3: Verify Storage Bucket

1. Go to **Storage** → **Files**
2. Make sure the bucket `daydream-20e85.firebasestorage.app` is active
3. Check that you can see the `profiles/` folder (it will be created automatically)

## 🧪 Testing the Setup

After configuring the rules, test the Edit Profile feature:

1. **Upload Photo**: Should save to `profiles/{userId}/timestamp.jpg`
2. **Update Username**: Should update `users/{userId}` document's `displayName` field
3. **Change Password**: Should update Firebase Auth (no Firestore rules needed)

## 🔍 Troubleshooting

### If profile updates fail:

1. **Check Firestore Rules**:
   - Open Firebase Console → Firestore → Rules
   - Make sure the rules allow `update` for the `users` collection
   - Check the Rules Playground to test your rules

2. **Check Storage Rules**:
   - Open Firebase Console → Storage → Rules
   - Make sure the rules allow `write` for `profiles/{userId}/**`
   - Verify the bucket name matches: `daydream-20e85.firebasestorage.app`

3. **Check Network**:
   - Make sure your device/emulator has internet connection
   - Check Firebase Console → Project Settings → General for any errors

4. **Check Authentication**:
   - User must be logged in
   - User ID must match the document ID in Firestore

### Common Error Messages:

- **"Missing or insufficient permissions"**: Rules are too restrictive
- **"Storage permission denied"**: Storage rules don't allow upload
- **"User not authenticated"**: User needs to log in again

## 📝 Quick Checklist

- [ ] Firestore rules allow users to update their own profile
- [ ] Storage rules allow users to upload/delete their own profile pictures
- [ ] Rules are published (not just saved as draft)
- [ ] User is authenticated
- [ ] Internet connection is active
- [ ] Firebase project is active (not on free tier limits)

## 🚀 After Setup

Once the rules are configured, the Edit Profile feature will:
- ✅ Upload photos to Firebase Storage
- ✅ Update username in Firestore
- ✅ Change password in Firebase Auth
- ✅ All changes will persist and sync across devices

---

**Note**: If you're using Firebase Emulator Suite for local development, make sure the emulator rules match the production rules.

