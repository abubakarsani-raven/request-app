# iOS Setup Guide

This guide will help you set up and build the iOS version of the Request App.

## Prerequisites

1. **macOS** - iOS development requires a Mac
2. **Xcode** - Install from the Mac App Store (latest version recommended)
3. **CocoaPods** - Install with: `sudo gem install cocoapods`
4. **Flutter** - Ensure Flutter is installed and configured
5. **Apple Developer Account** - Required for device testing and App Store distribution (free account works for development)

## Step 1: Install CocoaPods Dependencies

Navigate to the iOS directory and install dependencies:

```bash
cd mobile/ios
pod install
cd ../..
```

**Note:** If you encounter issues, try:
```bash
pod deintegrate
pod install
```

## Step 2: Configure Firebase for iOS

The app already has Firebase configured in `lib/firebase_options.dart`, but you need to add the `GoogleService-Info.plist` file:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `request-app-cd149`
3. Click the iOS app icon (or add iOS app if not added)
4. Enter your bundle ID: `com.nsc.requestapp`
5. Download the `GoogleService-Info.plist` file
6. Place it in `mobile/ios/Runner/GoogleService-Info.plist`

**Alternative:** Use FlutterFire CLI (recommended):
```bash
cd mobile
dart pub global activate flutterfire_cli
flutterfire configure
```

This will automatically add the `GoogleService-Info.plist` file.

## Step 3: Configure Xcode Project

### 3.1 Open the Project

```bash
cd mobile/ios
open Runner.xcworkspace
```

**Important:** Always open `.xcworkspace`, not `.xcodeproj`

### 3.2 Configure Signing & Capabilities

1. Select the **Runner** project in the left sidebar
2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. Select your **Team** (Apple Developer account)
5. Xcode will automatically create a provisioning profile

### 3.3 Add Push Notifications Capability

1. In **Signing & Capabilities**, click **+ Capability**
2. Add **Push Notifications**
3. The entitlements file (`Runner.entitlements`) is already configured

### 3.4 Verify Bundle Identifier

Ensure the bundle identifier is set to: `com.nsc.requestapp`

## Step 4: Configure Google Maps for iOS

The Google Maps API key is already configured in `Info.plist`. However, you need to:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable **Maps SDK for iOS** API
3. Restrict your API key to iOS apps:
   - Go to **Credentials** → Select your API key
   - Under **Application restrictions**, select **iOS apps**
   - Add your bundle ID: `com.nsc.requestapp`
   - Save changes

The API key in `Info.plist` is: `AIzaSyD3apWjzMf9iPAdZTSGR4ln2pU7U6Lo7_I`

## Step 5: Generate App Icons

The app icon configuration is already set up in `pubspec.yaml`. Generate icons:

```bash
cd mobile
flutter pub run flutter_launcher_icons
```

This will generate all required iOS icon sizes automatically.

## Step 6: Build and Run

### Run on Simulator

```bash
cd mobile
flutter run -d ios
```

Or select an iOS simulator:
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

### Run on Physical Device

1. Connect your iPhone via USB
2. Trust the computer on your iPhone if prompted
3. In Xcode, select your device from the device dropdown
4. Run:
   ```bash
   flutter run -d <your-device-id>
   ```

**Note:** First-time device runs require:
- Device to be registered in your Apple Developer account
- Trust the developer certificate on your device (Settings → General → VPN & Device Management)

## Step 7: Build for Release

### Archive for App Store / TestFlight

1. Open `Runner.xcworkspace` in Xcode
2. Select **Any iOS Device** as the target
3. Go to **Product** → **Archive**
4. Once archived, click **Distribute App**
5. Follow the prompts to upload to App Store Connect

### Build IPA for Ad-Hoc Distribution

```bash
cd mobile/ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive
```

## Configuration Files Overview

### Info.plist
- **Location:** `mobile/ios/Runner/Info.plist`
- **Contains:**
  - App display name: "Request App"
  - Bundle identifier: `com.nsc.requestapp`
  - Location permissions (for trip tracking)
  - Camera permission (for QR scanner)
  - Photo library permissions
  - Google Maps API key
  - Portrait-only orientation

### AppDelegate.swift
- **Location:** `mobile/ios/Runner/AppDelegate.swift`
- **Contains:**
  - Firebase initialization
  - Push notification setup
  - APNs token registration

### Runner.entitlements
- **Location:** `mobile/ios/Runner/Runner.entitlements`
- **Contains:**
  - Push notifications capability (`aps-environment`)

### Podfile
- **Location:** `mobile/ios/Podfile`
- **Contains:**
  - Minimum iOS version: 13.0
  - Flutter pod dependencies

## Permissions Configured

The app requests the following permissions:

1. **Location (When In Use)** - For trip tracking and map features
2. **Location (Always)** - For background trip tracking
3. **Camera** - For QR code scanning
4. **Photo Library** - For image selection and saving
5. **Push Notifications** - For FCM notifications

All permission descriptions are configured in `Info.plist`.

## Troubleshooting

### "No valid 'aps-environment' entitlement"
- Open Xcode → Runner project → Signing & Capabilities
- Ensure "Push Notifications" capability is added
- Verify `Runner.entitlements` file exists and is referenced in build settings

### "GoogleService-Info.plist not found"
- Download from Firebase Console
- Place in `mobile/ios/Runner/GoogleService-Info.plist`
- Or run `flutterfire configure`

### "Build failed: Pod install required"
```bash
cd mobile/ios
pod install
cd ../..
flutter clean
flutter pub get
```

### "Code signing error"
- Select your team in Xcode (Signing & Capabilities)
- Ensure bundle ID matches Firebase configuration: `com.nsc.requestapp`
- Check that your Apple Developer account is active

### "Maps not loading"
- Verify Google Maps API key is correct in `Info.plist`
- Check that Maps SDK for iOS is enabled in Google Cloud Console
- Ensure API key restrictions allow your bundle ID

### "Firebase not initializing"
- Verify `GoogleService-Info.plist` is in the correct location
- Check that bundle ID matches Firebase project configuration
- Run `flutterfire configure` to regenerate configuration

### "Permission denied" errors
- Check that permission descriptions are in `Info.plist`
- Verify permissions are requested at runtime (handled by Flutter plugins)

## Testing Checklist

- [ ] App builds successfully
- [ ] App launches on simulator
- [ ] App launches on physical device
- [ ] Location permissions requested and working
- [ ] Camera permission requested and QR scanner works
- [ ] Push notifications received
- [ ] Google Maps displays correctly
- [ ] Firebase authentication works
- [ ] All app features function correctly

## Next Steps

1. **Test on multiple iOS versions** (iOS 13.0+)
2. **Test on different device sizes** (iPhone SE, iPhone 14 Pro Max, iPad)
3. **Configure App Store Connect** for distribution
4. **Set up TestFlight** for beta testing
5. **Prepare App Store listing** (screenshots, description, etc.)

## Additional Resources

- [Flutter iOS Setup](https://docs.flutter.dev/deployment/ios)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Google Maps iOS SDK](https://developers.google.com/maps/documentation/ios-sdk)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)

## Notes

- The app is configured for **portrait-only** orientation
- Minimum iOS version: **13.0**
- Bundle ID: **com.nsc.requestapp**
- Firebase project: **request-app-cd149**
