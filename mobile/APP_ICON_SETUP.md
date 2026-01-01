# App Icon and Logo Setup Guide

This guide explains how to add your app icon and logo to the Flutter mobile app.

## 📐 Ideal Image Format

### For App Icon:
- **Format**: PNG (recommended) or JPG
- **Size**: **1024x1024 pixels** (square, 1:1 aspect ratio)
- **Background**: 
  - **Transparent background** (PNG with alpha channel) is ideal
  - Or solid color background matching your brand
- **File Size**: Keep under 500KB for best performance
- **Design Guidelines**:
  - Keep important content within the center 80% of the image (safe zone)
  - Avoid text that's too small (it won't be readable at small sizes)
  - Use high contrast colors
  - Test how it looks at small sizes (48x48, 72x72 pixels)

### For Logo (used in-app):
- **Format**: PNG with transparent background
- **Size**: 512x512 pixels or larger (can be rectangular)
- **Usage**: Displayed in splash screens, login pages, app headers, etc.

## 🚀 Setup Steps

### Step 1: Prepare Your Icon Image

1. Create or export your app icon as a **1024x1024 PNG** file
2. Name it `app_icon.png`
3. Place it in: `mobile/assets/icons/app_icon.png`

### Step 2: Generate All Icon Sizes

The `flutter_launcher_icons` package will automatically generate all required sizes for Android and iOS.

Run these commands in the `mobile` directory:

```bash
# Install dependencies (if not already done)
flutter pub get

# Generate all icon sizes
flutter pub run flutter_launcher_icons
```

This will:
- Generate Android icons in all required densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- Generate iOS icons in all required sizes
- Update AndroidManifest.xml and iOS configuration automatically

### Step 3: Verify the Icons

1. **Android**: Check `mobile/android/app/src/main/res/mipmap-*/ic_launcher.png`
2. **iOS**: Check `mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Step 4: Test the App

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## 📱 Platform-Specific Notes

### Android
- Icons are placed in `mipmap-*` folders (different densities)
- Adaptive icons (Android 8.0+) use foreground and background layers
- The `adaptive_icon_background` color is set in `pubspec.yaml`

### iOS
- Icons are placed in `Assets.xcassets/AppIcon.appiconset/`
- Multiple sizes are required (20pt, 29pt, 40pt, 60pt, 76pt, 83.5pt, 1024pt)
- All sizes are generated automatically from your source image

## 🎨 Adding Logo to App UI

If you want to use your logo within the app (not just as launcher icon):

1. Place your logo file in `mobile/assets/images/logo.png`
2. Use it in your Flutter code:

```dart
import 'package:flutter/material.dart';

// In your widget
Image.asset(
  'assets/images/logo.png',
  width: 200,
  height: 200,
  fit: BoxFit.contain,
)
```

3. Make sure `assets/images/` is listed in `pubspec.yaml` (already added)

## 🔧 Customization Options

You can customize the icon generation in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  # Android adaptive icon
  adaptive_icon_background: "#FFFFFF"  # Background color
  adaptive_icon_foreground: "assets/icons/app_icon.png"  # Foreground image
  # iOS specific
  remove_alpha_ios: true  # Remove transparency for iOS (recommended)
  # Generate only for specific platforms
  # android: "launcher_icon"
  # ios: true
```

## 📝 Current Configuration

Your `pubspec.yaml` is already configured with:
- Icon path: `assets/icons/app_icon.png`
- Adaptive icon background: White (#FFFFFF)
- Both Android and iOS enabled

## ⚠️ Troubleshooting

### Icons not updating?
1. Run `flutter clean`
2. Delete `build/` folder
3. Run `flutter pub run flutter_launcher_icons` again
4. Rebuild the app

### Icon looks blurry?
- Ensure your source image is exactly 1024x1024 pixels
- Use a high-quality PNG file
- Avoid upscaling small images

### iOS icons not generating?
- Make sure you have Xcode installed (for iOS development)
- Check that the image path in `pubspec.yaml` is correct

## 🎯 Quick Start Checklist

- [ ] Create 1024x1024 PNG icon
- [ ] Save as `mobile/assets/icons/app_icon.png`
- [ ] Run `flutter pub get`
- [ ] Run `flutter pub run flutter_launcher_icons`
- [ ] Test on device/emulator
- [ ] Verify icon appears correctly

## 📚 Additional Resources

- [flutter_launcher_icons package](https://pub.dev/packages/flutter_launcher_icons)
- [Android Icon Guidelines](https://developer.android.com/guide/practices/ui_guidelines/icon_design)
- [iOS Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
