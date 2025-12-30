# Android Device Setup Guide

This guide will help you connect your physical Android device to your backend API.

## Prerequisites

1. Your Android device and computer must be on the **same WiFi network**
2. Backend server must be running
3. MongoDB must be running

## Step 1: Find Your Computer's IP Address

### macOS
```bash
ipconfig getifaddr en0
# or
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### Linux
```bash
hostname -I
# or
ip addr show | grep "inet " | grep -v 127.0.0.1
```

### Windows
```bash
ipconfig
# Look for "IPv4 Address" under your active network adapter
```

## Step 2: Update Mobile App Configuration

### Option A: Automatic (Recommended)

Run the helper script from the `mobile` directory:

```bash
cd mobile
./update_api_ip.sh
```

This script will:
- Automatically detect your computer's IP address
- Update both `app_constants.dart` and `api_constants.dart`
- Create backup files in case you need to revert

### Option B: Manual

1. Open `mobile/lib/core/constants/app_constants.dart`
2. Replace `localhost` with your computer's IP address:
   ```dart
   static const String apiBaseUrl = 'http://192.168.1.100:4000'; // Your IP here
   static const String wsBaseUrl = 'ws://192.168.1.100:4000'; // Your IP here
   ```

3. Open `mobile/lib/core/constants/api_constants.dart`
4. Replace `localhost` with your computer's IP address:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:4000'; // Your IP here
   ```

## Step 3: Start the Backend

```bash
cd backend
npm run seed  # Create default admin user (first time only)
npm run start:dev
```

The backend will display your local IP addresses when it starts. Use one of those IPs in your mobile app.

## Step 4: Verify Connection

1. Make sure your Android device is on the same WiFi network
2. Make sure your computer's firewall allows connections on port 4000
3. Run your Flutter app:
   ```bash
   cd mobile
   flutter run
   ```

## Troubleshooting

### Can't connect from Android device

1. **Check WiFi**: Ensure both devices are on the same network
2. **Check Firewall**: Your computer's firewall might be blocking port 4000
   - macOS: System Preferences → Security & Privacy → Firewall
   - Linux: `sudo ufw allow 4000`
   - Windows: Windows Defender Firewall → Allow an app

3. **Check IP Address**: Verify you're using the correct IP address
   - The IP shown when backend starts is the one to use
   - Make sure it's not `127.0.0.1` or `localhost`

4. **Test Connection**: From your Android device's browser, try:
   ```
   http://YOUR_COMPUTER_IP:4000
   ```
   You should see a response (even if it's an error, it means the connection works)

### Backend shows "Application is running" but mobile can't connect

- Check that CORS is enabled (it is by default with `origin: true`)
- Verify the backend is listening on `0.0.0.0` (all interfaces), not just `localhost`
- Try restarting both the backend and the mobile app

### Reverting to localhost

If you need to revert the changes:
```bash
cd mobile
cp lib/core/constants/app_constants.dart.backup lib/core/constants/app_constants.dart
cp lib/core/constants/api_constants.dart.backup lib/core/constants/api_constants.dart
```

## Default Login Credentials

After running the seed script:
- **Email**: `admin@example.com`
- **Password**: `12345678`

## Notes

- The IP address might change if you reconnect to WiFi or restart your router
- If your IP changes, run `update_api_ip.sh` again or manually update the constants
- For production, use a proper domain name or static IP address

