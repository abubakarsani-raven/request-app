# Generate App Icons - Quick Start

Your app icon is ready at `assets/icons/app_icon.png`. Now generate all required sizes:

## Steps to Generate Icons

1. **Install dependencies** (if not already done):
   ```bash
   cd mobile
   flutter pub get
   ```

2. **Generate all icon sizes**:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

   This will:
   - Generate Android icons in all densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
   - Update AndroidManifest.xml automatically

3. **Clean and rebuild** (recommended):
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Verify Icons Were Generated

### Android
Check these folders exist with `ic_launcher.png` files:
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

## Troubleshooting

If icons don't appear:
1. Make sure your source image is exactly 1024x1024 pixels
2. Run `flutter clean` before rebuilding
3. Uninstall the app from your device/emulator and reinstall
4. For Android, check `android/app/src/main/AndroidManifest.xml` has `android:icon="@mipmap/ic_launcher"`

## Adding iOS Support Later

If you want to add iOS icon support later:

1. **Create iOS project structure** (if it doesn't exist):
   ```bash
   flutter create --platforms=ios .
   ```

2. **Update pubspec.yaml** to enable iOS:
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: true  # Change to true
     image_path: "assets/icons/app_icon.png"
   ```

3. **Regenerate icons**:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

## Next Steps

After generating icons:
- Test on Android device/emulator
- Verify the icon appears correctly in the app launcher
- Check that adaptive icons work on Android 8.0+ devices
