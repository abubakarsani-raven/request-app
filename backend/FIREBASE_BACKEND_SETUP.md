# Backend Firebase Setup - Quick Guide

## How to Get FCM Credentials for Backend

### Method 1: From Service Account JSON (Recommended)

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project

2. **Navigate to Service Accounts**
   - Click the **gear icon** ⚙️ (Project Settings)
   - Go to **Service accounts** tab
   - Click **Generate new private key**
   - Download the JSON file

3. **Extract the Three Required Fields**

   Open the downloaded JSON file and find:

   ```json
   {
     "project_id": "your-project-id",           // ← FIREBASE_PROJECT_ID
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",  // ← FIREBASE_PRIVATE_KEY
     "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com"  // ← FIREBASE_CLIENT_EMAIL
   }
   ```

4. **Add to `.env` file**

   ```env
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
   ```

   **Important:** 
   - Keep the `\n` characters in the private key
   - Wrap the private key in double quotes
   - The entire private key should be on one line with `\n` for newlines

### Method 2: Using JSON File Directly (Alternative)

If you prefer to use the JSON file directly:

1. Place the service account JSON file in `backend/` directory
2. Update `backend/src/fcm/fcm.service.ts`:

```typescript
import * as admin from 'firebase-admin';
import * as path from 'path';

private initializeFirebase() {
  try {
    // Option 1: Use environment variables (current implementation)
    const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
    const privateKey = this.configService.get<string>('FIREBASE_PRIVATE_KEY');
    const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');

    // Option 2: Use JSON file directly (uncomment to use)
    // const serviceAccountPath = path.join(process.cwd(), 'path-to-your-service-account-key.json');
    // this.firebaseApp = admin.initializeApp({
    //   credential: admin.credential.cert(serviceAccountPath),
    // });

    if (!projectId || !privateKey || !clientEmail) {
      this.logger.warn('Firebase credentials not configured...');
      return;
    }

    // Current implementation using env vars
    if (admin.apps.length === 0) {
      this.firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          privateKey: privateKey.replace(/\\n/g, '\n'),
          clientEmail,
        }),
      });
    }
  } catch (error) {
    this.logger.error('Failed to initialize Firebase:', error);
  }
}
```

### Visual Guide: Finding Service Account Key

```
Firebase Console
  └─ Project Settings (⚙️)
      └─ Service Accounts tab
          └─ Generate new private key (button)
              └─ Downloads JSON file
                  └─ Open JSON file
                      ├─ project_id → FIREBASE_PROJECT_ID
                      ├─ private_key → FIREBASE_PRIVATE_KEY
                      └─ client_email → FIREBASE_CLIENT_EMAIL
```

### Example .env Entry

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=my-request-app-12345
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-abc123@my-request-app-12345.iam.gserviceaccount.com
```

### Verify Setup

After adding the credentials, restart your backend and check logs:

```
[FCMService] Firebase Admin SDK initialized successfully
```

If you see this message, Firebase is configured correctly!

### Troubleshooting

**Error: "Firebase credentials not configured"**
- Check that all three variables are in `.env`
- Verify no typos in variable names
- Make sure `.env` file is in the `backend/` directory

**Error: "Invalid private key"**
- Ensure the private key includes `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`
- Keep `\n` characters in the string (they represent newlines)
- Wrap the entire key in double quotes

**Error: "Permission denied"**
- The service account needs "Firebase Cloud Messaging API Admin" role
- Check IAM permissions in Google Cloud Console
