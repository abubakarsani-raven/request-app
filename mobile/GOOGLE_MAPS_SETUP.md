# Google Maps API Key Setup

## Step 1: Get Your Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Maps SDK for Android** (for Android)
   - **Maps SDK for iOS** (for iOS)
   - **Geocoding API** (for address lookups)
   - **Places API** (if you need place search)

4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Copy your API key

## Step 2: Restrict Your API Key (Recommended for Production)

### For Android:
1. Click on your API key to edit it
2. Under **Application restrictions**, select **Android apps**
3. Click **Add an item**
4. Enter your package name: `com.nsc.requestapp`
5. Get your SHA-1 certificate fingerprint (see below)
6. Add the SHA-1 fingerprint
7. Under **API restrictions**, restrict to only the APIs you need

### For iOS:
1. Click on your API key to edit it
2. Under **Application restrictions**, select **iOS apps**
3. Click **Add an item**
4. Enter your bundle ID: `com.nsc.requestapp`
5. Under **API restrictions**, restrict to only the APIs you need

## Step 3: Get SHA-1 Certificate Fingerprint

### For Debug Build:
```bash
cd android
./gradlew signingReport
```

Look for `SHA1` under the `debug` variant.

Or use:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### For Release Build:
```bash
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
```

## Step 4: Add API Key to Your App

### For Android:

1. Open `android/app/src/main/AndroidManifest.xml`
2. Find the `<application>` tag
3. Add the API key meta-data (already added, just replace `YOUR_GOOGLE_MAPS_API_KEY_HERE`):

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE"/>
```

### For iOS:

1. Open `ios/Runner/Info.plist`
2. Add the API key (already configured):

```xml
<key>GMSApiKey</key>
<string>YOUR_ACTUAL_API_KEY_HERE</string>
```

The API key is already configured in `Info.plist` as: `AIzaSyD3apWjzMf9iPAdZTSGR4ln2pU7U6Lo7_I`

## Step 5: Replace the Placeholder

In `android/app/src/main/AndroidManifest.xml`, replace:
- `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key

**Note:** iOS API key is already configured in `Info.plist`.

## Important Notes:

- **Never commit your API key to version control!**
- Consider using environment variables or a secrets file
- For production, always restrict your API key
- Monitor your API usage in Google Cloud Console
- Set up billing alerts to avoid unexpected charges

## Alternative: Using Environment Variables

You can use a local.properties file (which is gitignored):

1. Create/Edit `android/local.properties`:
```
MAPS_API_KEY=your_actual_api_key_here
```

2. In `android/app/build.gradle.kts`, add:
```kotlin
val mapsApiKey = project.findProperty("MAPS_API_KEY") as String? ?: ""

android {
    defaultConfig {
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }
}
```

3. In AndroidManifest.xml:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}"/>
```

## Troubleshooting:

### Android:
- **"API key not found"**: Make sure the meta-data is inside the `<application>` tag
- **"API key invalid"**: Check that you've enabled the correct APIs
- **"This API key is not authorized"**: Add your SHA-1 fingerprint to the API key restrictions
- **Maps not loading**: Check your internet connection and API quota

### iOS:
- **"API key not found"**: Verify `GMSApiKey` is in `Info.plist`
- **"API key invalid"**: Check that Maps SDK for iOS is enabled in Google Cloud Console
- **"This API key is not authorized"**: Add your bundle ID (`com.nsc.requestapp`) to the API key restrictions
- **Maps not loading**: Check your internet connection and API quota
- **Build errors**: Ensure CocoaPods dependencies are installed (`pod install` in `ios/` directory)

