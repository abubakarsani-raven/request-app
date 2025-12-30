# Firebase Setup Guide

This guide will help you set up Firebase Cloud Messaging (FCM) for both the mobile app and backend.

## Prerequisites

1. A Firebase project (create one at [Firebase Console](https://console.firebase.google.com/))
2. FlutterFire CLI installed
3. Node.js installed (for backend)

## Part 1: Mobile App Setup (FlutterFire CLI - Recommended)

### Step 1: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Step 2: Configure Firebase for Flutter

Navigate to your mobile app directory:

```bash
cd mobile
```

Run the FlutterFire CLI configuration:

```bash
flutterfire configure
```

This will:
- Ask you to select your Firebase project
- Automatically generate `lib/firebase_options.dart`
- Configure both Android and iOS automatically
- Add necessary files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS)

**Note:** You may need to log in to Firebase:
```bash
firebase login
```

### Step 3: Verify Setup

After running `flutterfire configure`, you should see:
- `lib/firebase_options.dart` file created
- `android/app/google-services.json` added (if Android is configured)
- `ios/Runner/GoogleService-Info.plist` added (if iOS is configured)

### Step 4: Install Dependencies

```bash
flutter pub get
```

The app is now configured! The code already uses `DefaultFirebaseOptions.currentPlatform` from `firebase_options.dart`.

---

## Part 2: Backend Setup (Service Account Key)

### Step 1: Generate Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the **gear icon** ⚙️ next to "Project Overview"
4. Select **Project settings**
5. Go to the **Service accounts** tab
6. Click **Generate new private key**
7. A JSON file will be downloaded (e.g., `your-project-firebase-adminsdk-xxxxx.json`)

### Step 2: Extract Credentials from JSON

Open the downloaded JSON file. You'll see something like:

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

### Step 3: Add to Backend Environment Variables

Add these to your `backend/.env` file:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
```

**Important Notes:**
- The `FIREBASE_PRIVATE_KEY` must include the `\n` characters (newlines) - keep them as `\n` in the .env file
- Wrap the private key in double quotes in the .env file
- The private key should be on a single line with `\n` characters

### Alternative: Using JSON File Directly (Optional)

If you prefer to use the JSON file directly instead of environment variables, you can modify `backend/src/fcm/fcm.service.ts`:

```typescript
import * as admin from 'firebase-admin';
import * as path from 'path';

// In initializeFirebase method:
const serviceAccountPath = path.join(__dirname, '../../path/to/your-service-account-key.json');
this.firebaseApp = admin.initializeApp({
  credential: admin.credential.cert(serviceAccountPath),
});
```

---

## Part 3: Testing

### Test Mobile App

1. Run the app:
   ```bash
   flutter run
   ```

2. Check logs for FCM token:
   ```
   FCM Token: [your-token-here]
   ```

3. The token should automatically be registered on the backend after login.

### Test Backend

1. Start the backend server
2. Check logs for:
   ```
   Firebase Admin SDK initialized successfully
   ```

3. Send a test notification from Firebase Console:
   - Go to Firebase Console > Cloud Messaging
   - Click "Send your first message"
   - Enter a test FCM token from your mobile app
   - Send the message

---

## Troubleshooting

### Mobile App Issues

**Error: "FirebaseOptions not found"**
- Make sure you ran `flutterfire configure`
- Check that `lib/firebase_options.dart` exists
- Run `flutter clean && flutter pub get`

**Error: "No Firebase App '[DEFAULT]' has been created"**
- Make sure Firebase is initialized before using FCM
- Check that `firebase_options.dart` is imported correctly

**iOS: "No valid 'aps-environment' entitlement"**
- Enable Push Notifications capability in Xcode
- Add the capability in your iOS project settings

### Backend Issues

**Error: "Firebase credentials not configured"**
- Check that all three environment variables are set
- Verify the private key includes `\n` characters
- Make sure the private key is wrapped in quotes

**Error: "Invalid private key"**
- The private key must include the BEGIN and END markers
- Ensure `\n` characters are preserved in the .env file
- Try regenerating the service account key

**Error: "Permission denied"**
- Make sure the service account has "Firebase Cloud Messaging API Admin" role
- Check IAM permissions in Google Cloud Console

---

## Security Best Practices

1. **Never commit service account keys to git**
   - Add `*.json` (service account files) to `.gitignore`
   - Use environment variables in production

2. **Rotate keys regularly**
   - Generate new service account keys periodically
   - Update environment variables

3. **Use least privilege**
   - Only grant necessary permissions to service accounts

4. **Monitor usage**
   - Check Firebase Console for unusual activity
   - Set up alerts for quota limits

---

## Quick Reference

### Mobile App (FlutterFire CLI)
```bash
cd mobile
dart pub global activate flutterfire_cli
flutterfire configure
flutter pub get
```

### Backend (.env)
```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
```

### Get Service Account Key
1. Firebase Console > Project Settings > Service Accounts
2. Click "Generate new private key"
3. Extract `project_id`, `private_key`, and `client_email` from JSON

---

## Additional Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Admin SDK Setup](https://firebase.google.com/docs/admin/setup)
- [FCM Setup Guide](https://firebase.google.com/docs/cloud-messaging)
