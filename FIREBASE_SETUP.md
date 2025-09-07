# Firebase Setup Guide for Freedom App

## Overview
Your Flutter app has been configured with Firebase dependencies and basic setup. You now need to complete the configuration by setting up your Firebase project and adding the proper configuration files.

## What's Already Done ✅
- ✅ Firebase dependencies added to `pubspec.yaml`
- ✅ Firebase initialized in `main.dart`
- ✅ PostStorageService updated to use Firestore
- ✅ Placeholder configuration files created
- ✅ Web Firebase SDK added to `index.html`

## What You Need to Do 🔧

### 1. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name (e.g., "freedom-app")
4. Enable Google Analytics (optional)
5. Create the project

### 2. Add Android App
1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.example.freedomapp` (or your actual package name)
3. Download `google-services.json`
4. Replace the placeholder file at `android/app/google-services.json` with the downloaded file

### 3. Add iOS App
1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID: `com.example.freedomapp` (or your actual bundle ID)
3. Download `GoogleService-Info.plist`
4. Replace the placeholder file at `ios/Runner/GoogleService-Info.plist` with the downloaded file

### 4. Add Web App
1. In Firebase Console, click "Add app" → Web
2. Enter app nickname (e.g., "freedom-app-web")
3. Copy the Firebase configuration object
4. Replace the placeholder values in `web/firebase-config.js` with your actual config

### 5. Enable Firebase Services
In Firebase Console, enable these services:

#### Firestore Database
1. Go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location close to your users

#### Authentication (Optional)
1. Go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Anonymous" authentication (for anonymous posts)

#### Storage (Optional)
1. Go to "Storage"
2. Click "Get started"
3. Choose "Start in test mode"
4. Select a location

### 6. Update Package Names
Make sure your package names match in these files:
- `android/app/build.gradle.kts` - check `applicationId`
- `ios/Runner/Info.plist` - check `CFBundleIdentifier`

### 7. Test the Setup
Run your app:
```bash
flutter run
```

## Configuration Files to Replace

### Android: `android/app/google-services.json`
Replace with your downloaded file from Firebase Console.

### iOS: `ios/Runner/GoogleService-Info.plist`
Replace with your downloaded file from Firebase Console.

### Web: `web/firebase-config.js`
Update with your Firebase config:
```javascript
const firebaseConfig = {
  apiKey: "your-actual-api-key",
  authDomain: "your-project-id.firebaseapp.com",
  projectId: "your-actual-project-id",
  storageBucket: "your-project-id.appspot.com",
  messagingSenderId: "your-actual-sender-id",
  appId: "your-actual-app-id"
};
```

## Firestore Security Rules (Development)
For development, you can use these permissive rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ Warning: These rules allow anyone to read/write. Use proper security rules for production!**

## Storage Security Rules (Development)
For development, you can use these permissive rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ Warning: These rules allow anyone to read/write. Use proper security rules for production!**

## Troubleshooting

### Common Issues:
1. **Build errors**: Make sure you've replaced the placeholder config files
2. **Package name mismatch**: Ensure package names match between Firebase Console and your app
3. **Network errors**: Check your internet connection and Firebase project status
4. **Permission errors**: Verify Firestore rules allow read/write access

### Useful Commands:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check Firebase connection
flutter doctor
```

## Next Steps
Once Firebase is configured:
1. Test creating, reading, updating, and deleting posts
2. Implement user authentication if needed
3. Add image upload functionality using Firebase Storage
4. Set up proper security rules for production
5. Consider implementing real-time updates using Firestore streams

## Support
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
