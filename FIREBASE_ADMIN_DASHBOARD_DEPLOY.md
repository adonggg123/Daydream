# Deploy Admin Dashboard Only - Firebase Hosting Guide

This guide will help you deploy **only** the admin dashboard as a separate web application using Firebase Hosting, without affecting your main application.

## Overview

We've created a separate entry point (`main_admin.dart`) that only loads the admin dashboard. This allows you to:
- Deploy the admin dashboard as a standalone web app
- Keep your main application unchanged
- Access the admin dashboard at a separate URL

## Prerequisites

1. **Flutter SDK** installed
2. **Firebase CLI** installed (`npm install -g firebase-tools`)
3. **Node.js** installed
4. **Firebase project** configured

## Step 1: Login to Firebase

```bash
firebase login
```

## Step 2: Verify Firebase Project

```bash
firebase use daydream-20e85
```

## Step 3: Build Admin Dashboard Web App

Build the Flutter app using the admin dashboard entry point:

```bash
flutter build web --release --target=lib/main_admin.dart
```

**Important Flags:**
- `--target=lib/main_admin.dart` - Uses the admin dashboard entry point
- Flutter will automatically select the best web renderer for your version

This will create optimized production files in the `build/web` directory.

## Step 4: Configure Firebase Hosting for Admin Dashboard

You have two options:

### Option A: Deploy to a Subdirectory (Recommended)

Update `firebase.json` to deploy the admin dashboard to a subdirectory:

```json
{
  "hosting": [
    {
      "target": "admin",
      "public": "build/web",
      "ignore": [
        "firebase.json",
        "**/.*",
        "**/node_modules/**"
      ],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    }
  ]
}
```

Then deploy:
```bash
firebase deploy --only hosting:admin
```

### Option B: Create Separate Firebase Hosting Site

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Hosting**
4. Click **Add another site**
5. Create a new site (e.g., `daydream-admin`)
6. Update `firebase.json`:

```json
{
  "hosting": [
    {
      "target": "admin",
      "public": "build/web",
      "ignore": [
        "firebase.json",
        "**/.*",
        "**/node_modules/**"
      ],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    }
  ]
}
```

7. Connect the site:
```bash
firebase target:apply hosting admin daydream-admin
```

8. Deploy:
```bash
firebase deploy --only hosting:admin
```

## Step 5: Deploy to Firebase Hosting

After building, deploy:

```bash
firebase deploy --only hosting
```

Or if using a separate target:
```bash
firebase deploy --only hosting:admin
```

## Step 6: Access Your Admin Dashboard

After deployment, your admin dashboard will be available at:
- `https://daydream-20e85.web.app` (if using main hosting)
- `https://daydream-admin.web.app` (if using separate site)

## Quick Deploy Script

Create a script to automate the build and deploy process:

### Windows (deploy_admin.bat):
```batch
@echo off
echo Building Admin Dashboard web app...
flutter build web --release --target=lib/main_admin.dart --web-renderer canvaskit
echo Deploying to Firebase Hosting...
firebase deploy --only hosting
echo Deployment complete!
pause
```

### Linux/Mac (deploy_admin.sh):
```bash
#!/bin/bash
echo "Building Admin Dashboard web app..."
flutter build web --release --target=lib/main_admin.dart --web-renderer canvaskit
echo "Deploying to Firebase Hosting..."
firebase deploy --only hosting
echo "Deployment complete!"
```

Make executable (Linux/Mac):
```bash
chmod +x deploy_admin.sh
```

## Updating the Admin Dashboard

To update your deployed admin dashboard:

1. Make changes to `admin_dashboard.dart` or related files
2. Rebuild:
   ```bash
   flutter build web --release --target=lib/main_admin.dart
   ```
3. Deploy:
   ```bash
   firebase deploy --only hosting
   ```

## Important Notes

### What's Included in Admin Dashboard Build

The admin dashboard build includes:
- ✅ Admin dashboard screen
- ✅ Login page (for authentication)
- ✅ All required services (AuthService, UserService, etc.)
- ✅ All required models
- ✅ Firebase configuration

### What's NOT Included

The admin dashboard build does NOT include:
- ❌ Home page
- ❌ User-facing screens
- ❌ Public booking pages
- ❌ Other user features

### Security Considerations

1. **Authentication Required**: The admin dashboard requires authentication
2. **Role-Based Access**: Only admin/staff/receptionist users can access
3. **Firestore Rules**: Ensure your Firestore rules properly restrict access
4. **HTTPS**: Firebase Hosting automatically provides HTTPS

### Troubleshooting

#### Issue: Build fails
**Solution:**
```bash
flutter clean
flutter pub get
flutter build web --release --target=lib/main_admin.dart --web-renderer canvaskit
```

#### Issue: Can't access admin dashboard
**Solution:**
1. Check browser console for errors
2. Verify you're logged in with an admin account
3. Check Firestore security rules
4. Verify Firebase configuration

#### Issue: Routing not working
**Solution:** The `firebase.json` rewrite rules should handle this. If issues persist, ensure all routes redirect to `index.html`.

#### Issue: Assets not loading
**Solution:** 
1. Check `pubspec.yaml` includes all required assets
2. Rebuild with `flutter clean` first
3. Verify asset paths in code

## Alternative: Deploy to Different Directory

If you want to keep both apps on the same domain:

1. Build admin dashboard to a different directory:
   ```bash
   flutter build web --release --target=lib/main_admin.dart --base-href=/admin/ --output=build/web_admin
   ```

2. Update `firebase.json`:
   ```json
   {
     "hosting": {
       "public": "build",
       "rewrites": [
         {
           "source": "/admin/**",
           "destination": "/admin/index.html"
         },
         {
           "source": "**",
           "destination": "/index.html"
         }
       ]
     }
   }
   ```

3. Deploy:
   ```bash
   firebase deploy --only hosting
   ```

Access at: `https://your-domain.web.app/admin/`

## Performance Tips

1. **Optimize Build Size:**
   ```bash
   flutter build web --release --target=lib/main_admin.dart
   ```
   Flutter automatically optimizes the build for production.

2. **Enable Tree Shaking:** Already enabled in release builds

3. **Optimize Images:** Compress images before including in assets

4. **Code Splitting:** Flutter web automatically handles this

## Next Steps

1. Build and deploy using the commands above
2. Test the admin dashboard at the provided URL
3. Set up a custom domain if needed
4. Configure CI/CD for automatic deployments (optional)

Your main application remains completely unchanged and can be deployed separately if needed.

