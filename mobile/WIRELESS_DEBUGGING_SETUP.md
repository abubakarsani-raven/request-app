# Wireless Android Debugging Setup Guide

## Step 1: Enable Wireless Debugging on Your Android Device

1. **Enable Developer Options** (if not already enabled):
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings → Developer Options

2. **Enable Wireless Debugging**:
   - Open Developer Options
   - Find "Wireless debugging" and enable it
   - Tap on "Wireless debugging" to open settings
   - Tap "Pair device with pairing code"
   - Note down the **IP address and port** (e.g., `192.168.1.100:12345`)
   - Note down the **pairing code**

## Step 2: Connect Your Device Wirelessly

### Option A: Using ADB (Recommended)

1. **Find your computer's IP address**:
   ```bash
   # On macOS:
   ipconfig getifaddr en0
   # or
   ifconfig | grep "inet " | grep -v 127.0.0.1
   
   # On Linux:
   ip addr show | grep "inet " | grep -v 127.0.0.1
   
   # On Windows:
   ipconfig
   # Look for IPv4 Address under your active network adapter
   ```

2. **Connect via ADB**:
   ```bash
   # First, pair the device (use the IP:port and pairing code from Step 1)
   adb pair <DEVICE_IP>:<PAIRING_PORT>
   # Enter the pairing code when prompted
   
   # Then connect (use the IP:port shown after pairing)
   adb connect <DEVICE_IP>:<DEBUGGING_PORT>
   
   # Verify connection
   adb devices
   ```

### Option B: Using Flutter Directly

If your device and computer are on the same WiFi network, Flutter can sometimes auto-detect it. Just make sure:
- Both devices are on the same WiFi network
- Wireless debugging is enabled on your Android device

## Step 3: Update API Base URL

Since you're running on a physical device, you need to update the API base URL to use your computer's IP address instead of `localhost`.

1. **Find your computer's local IP address** (from Step 2, Option A)

2. **Update the API constants**:
   - Open `lib/core/constants/api_constants.dart`
   - Change `baseUrl` from `'http://localhost:4000'` to `'http://YOUR_COMPUTER_IP:4000'`
   - Example: `'http://192.168.1.50:4000'`

## Step 4: Run the App

```bash
cd mobile
flutter pub get
flutter run
```

If multiple devices are connected, select your wireless device when prompted.

## Troubleshooting

### Device not showing up?
- Make sure both devices are on the same WiFi network
- Check that wireless debugging is enabled and active
- Try disconnecting and reconnecting: `adb disconnect` then `adb connect <IP>:<PORT>`

### Connection issues?
- Restart wireless debugging on your device
- Make sure your firewall isn't blocking the connection
- Try using USB cable first, then switch to wireless

### API connection errors?
- Verify your backend server is running on port 3000
- Check that your computer's IP address is correct
- Ensure your phone can reach your computer's IP (try pinging from phone)
- Make sure your backend CORS settings allow requests from your device

## Quick Commands Reference

```bash
# Check connected devices
flutter devices
adb devices

# Connect wirelessly
adb pair <IP>:<PORT>
adb connect <IP>:<PORT>

# Disconnect
adb disconnect

# Run app
flutter run

# Run on specific device
flutter run -d <device-id>
```



