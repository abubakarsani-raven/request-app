#!/bin/bash

echo "🔍 Finding your computer's local IP address..."
echo ""

# Try different methods to get IP
IP=""

# macOS method
if [[ "$OSTYPE" == "darwin"* ]]; then
    IP=$(ipconfig getifaddr en0 2>/dev/null)
    if [ -z "$IP" ]; then
        IP=$(ipconfig getifaddr en1 2>/dev/null)
    fi
    if [ -z "$IP" ]; then
        IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
    fi
# Linux method
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    IP=$(hostname -I | awk '{print $1}' 2>/dev/null)
    if [ -z "$IP" ]; then
        IP=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)
    fi
fi

if [ -z "$IP" ]; then
    echo "❌ Could not automatically detect IP address."
    echo "Please find your IP address manually:"
    echo "  - macOS: System Preferences → Network, or run: ipconfig getifaddr en0"
    echo "  - Linux: ip addr show"
    echo "  - Windows: ipconfig"
    echo ""
    read -p "Enter your computer's local IP address: " IP
fi

if [ -z "$IP" ]; then
    echo "❌ No IP address provided. Exiting."
    exit 1
fi

echo "✅ Found IP address: $IP"
echo ""
echo "📝 Updating API base URLs in mobile app..."
echo ""

# Update app_constants.dart
APP_CONSTANTS_FILE="lib/core/constants/app_constants.dart"
if [ -f "$APP_CONSTANTS_FILE" ]; then
    # Backup original
    cp "$APP_CONSTANTS_FILE" "${APP_CONSTANTS_FILE}.backup"
    
    # Update the apiBaseUrl (replace any existing IP or localhost)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|http://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:4000|http://$IP:4000|g" "$APP_CONSTANTS_FILE"
        sed -i '' "s|ws://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:4000|ws://$IP:4000|g" "$APP_CONSTANTS_FILE"
        sed -i '' "s|http://localhost:4000|http://$IP:4000|g" "$APP_CONSTANTS_FILE"
        sed -i '' "s|ws://localhost:4000|ws://$IP:4000|g" "$APP_CONSTANTS_FILE"
    else
        sed -i "s|http://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:4000|http://$IP:4000|g" "$APP_CONSTANTS_FILE"
        sed -i "s|ws://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:4000|ws://$IP:4000|g" "$APP_CONSTANTS_FILE"
        sed -i "s|http://localhost:4000|http://$IP:4000|g" "$APP_CONSTANTS_FILE"
        sed -i "s|ws://localhost:4000|ws://$IP:4000|g" "$APP_CONSTANTS_FILE"
    fi
    
    echo "✅ Updated $APP_CONSTANTS_FILE"
    echo "   Changed: http://localhost:4000 → http://$IP:4000"
    echo "   Changed: ws://localhost:4000 → ws://$IP:4000"
    echo "   Backup saved to: ${APP_CONSTANTS_FILE}.backup"
else
    echo "❌ Could not find $APP_CONSTANTS_FILE"
fi

# Update api_constants.dart
API_CONSTANTS_FILE="lib/core/constants/api_constants.dart"
if [ -f "$API_CONSTANTS_FILE" ]; then
    # Backup original
    cp "$API_CONSTANTS_FILE" "${API_CONSTANTS_FILE}.backup"
    
    # Update the baseUrl (replace any existing IP or localhost)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|http://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:4000|http://$IP:4000|g" "$API_CONSTANTS_FILE"
        sed -i '' "s|http://localhost:4000|http://$IP:4000|g" "$API_CONSTANTS_FILE"
    else
        sed -i "s|http://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:4000|http://$IP:4000|g" "$API_CONSTANTS_FILE"
        sed -i "s|http://localhost:4000|http://$IP:4000|g" "$API_CONSTANTS_FILE"
    fi
    
    echo "✅ Updated $API_CONSTANTS_FILE"
    echo "   Changed: http://localhost:4000 → http://$IP:4000"
    echo "   Backup saved to: ${API_CONSTANTS_FILE}.backup"
else
    echo "❌ Could not find $API_CONSTANTS_FILE"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Your mobile app is now configured to connect to:"
echo "  📡 API: http://$IP:4000"
echo "  🔌 WebSocket: ws://$IP:4000"
echo ""
echo "Next steps:"
echo "1. Make sure your backend is running: cd ../backend && npm run start:dev"
echo "2. Make sure your Android device is on the same WiFi network as your computer"
echo "3. Run your Flutter app: flutter run"
echo ""
echo "💡 To revert to localhost, restore from the .backup files"

