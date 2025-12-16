# Firebase Hosting Deployment Guide for Flutter Web App

This guide will help you deploy your Flutter admin dashboard as a web application using Firebase Hosting.

## Prerequisites

1. **Flutter SDK** installed and configured
2. **Firebase CLI** installed
3. **Node.js** installed (required for Firebase CLI)
4. **Firebase project** already set up (you have `firebase.json` configured)

## Step 1: Install Firebase CLI (if not already installed)

```bash
npm install -g firebase-tools
```

## Step 2: Login to Firebase

```bash
firebase login
```

This will open a browser window for you to authenticate with your Google account.

## Step 3: Verify Firebase Project

```bash
firebase projects:list
```

Make sure your project `daydream-20e85` is listed. If not, set it:

```bash
firebase use daydream-20e85
```

## Step 4: Enable Web Support in Flutter (if not already enabled)

Check if web support is enabled:

```bash
flutter devices
```

You should see `Chrome` listed. If not, enable web support:

```bash
flutter config --enable-web
```

## Step 5: Build Flutter Web App

Build your Flutter app for web in release mode:

```bash
flutter build web --release
```

This will create optimized production files in the `build/web` directory.

**Note:** The build process may take a few minutes. Make sure there are no errors.

## Step 6: Initialize Firebase Hosting (if not already initialized)

If you haven't initialized Firebase Hosting yet, run:

```bash
firebase init hosting
```

When prompted:
- **What do you want to use as your public directory?** → `build/web`
- **Configure as a single-page app?** → `Yes`
- **Set up automatic builds and deploys with GitHub?** → `No` (or `Yes` if you want CI/CD)
- **File build/web/index.html already exists. Overwrite?** → `No`

**Note:** Since we've already updated `firebase.json`, you can skip this step if the hosting configuration is already present.

## Step 7: Deploy to Firebase Hosting

Deploy your web app:

```bash
firebase deploy --only hosting
```

This will:
1. Upload your `build/web` files to Firebase Hosting
2. Provide you with a hosting URL (e.g., `https://daydream-20e85.web.app`)

## Step 8: Verify Deployment

After deployment, Firebase will provide you with:
- **Hosting URL:** `https://daydream-20e85.web.app`
- **Custom Domain:** (if configured) `https://yourdomain.com`

Open the URL in your browser to verify the app is working correctly.

## Step 9: Set Up Custom Domain (Optional)

If you want to use a custom domain:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Hosting** in the left sidebar
4. Click **Add custom domain**
5. Follow the instructions to verify your domain

## Troubleshooting

### Issue: Build fails with errors

**Solution:** Make sure all dependencies are up to date:
```bash
flutter pub get
flutter clean
flutter build web --release
```

### Issue: Firebase CLI not found

**Solution:** Install Firebase CLI globally:
```bash
npm install -g firebase-tools
```

### Issue: Authentication errors

**Solution:** Re-authenticate:
```bash
firebase logout
firebase login
```

### Issue: Web app not loading correctly

**Solution:** 
1. Check browser console for errors
2. Verify Firebase configuration in `lib/firebase_options.dart`
3. Ensure Firestore security rules allow web access
4. Check that all assets are properly included in `pubspec.yaml`

### Issue: Routing not working (404 errors)

**Solution:** The `firebase.json` already includes a rewrite rule that redirects all routes to `index.html`. This should handle Flutter's routing correctly.

## Updating Your Deployment

To update your deployed app:

1. Make your changes to the code
2. Rebuild the web app:
   ```bash
   flutter build web --release
   ```
3. Deploy again:
   ```bash
   firebase deploy --only hosting
   ```

## Performance Optimization Tips

1. **Enable caching:** The `firebase.json` already includes cache headers for static assets
2. **Use release mode:** Always build with `--release` flag for production
3. **Optimize images:** Compress images before including them in assets
4. **Code splitting:** Flutter web automatically handles code splitting

## Security Considerations

1. **Firestore Rules:** Ensure your Firestore security rules are properly configured for web access
2. **API Keys:** Firebase automatically handles API keys, but ensure your rules restrict access appropriately
3. **Authentication:** Verify that authentication works correctly on web

## Additional Resources

- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

## Quick Deploy Script

You can create a simple script to automate the build and deploy process:

**Windows (deploy.bat):**
```batch
@echo off
echo Building Flutter web app...
flutter build web --release
echo Deploying to Firebase Hosting...
firebase deploy --only hosting
echo Deployment complete!
```

**Linux/Mac (deploy.sh):**
```bash
#!/bin/bash
echo "Building Flutter web app..."
flutter build web --release
echo "Deploying to Firebase Hosting..."
firebase deploy --only hosting
echo "Deployment complete!"
```

Make the script executable (Linux/Mac):
```bash
chmod +x deploy.sh
```

Then run:
- Windows: `deploy.bat`
- Linux/Mac: `./deploy.sh`

