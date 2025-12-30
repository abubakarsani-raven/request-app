#!/bin/bash

echo "🔍 Finding your computer's IP address..."
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
    IP=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)
fi

if [ -z "$IP" ]; then
    echo "❌ Could not automatically detect IP address."
    echo "Please find your IP address manually:"
    echo "  - macOS: System Preferences → Network"
    echo "  - Linux: ip addr show"
    echo "  - Windows: ipconfig"
    echo ""
    read -p "Enter your computer's IP address: " IP
fi

if [ -z "$IP" ]; then
    echo "❌ No IP address provided. Exiting."
    exit 1
fi

echo "✅ Found IP address: $IP"
echo ""
echo "📝 Updating API base URL..."

# Update api_constants.dart
API_FILE="lib/core/constants/api_constants.dart"
if [ -f "$API_FILE" ]; then
    # Backup original
    cp "$API_FILE" "${API_FILE}.backup"
    
    # Update the baseUrl
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|http://localhost:4000|http://$IP:4000|g" "$API_FILE"
    else
        sed -i "s|http://localhost:4000|http://$IP:4000|g" "$API_FILE"
    fi
    
    echo "✅ Updated $API_FILE"
    echo "   Changed: http://localhost:4000 → http://$IP:4000"
    echo "   Backup saved to: ${API_FILE}.backup"
else
    echo "❌ Could not find $API_FILE"
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Enable Wireless Debugging on your Android device"
echo "2. Connect your device using: adb pair <IP>:<PORT>"
echo "3. Run: flutter run"
echo ""
echo "See WIRELESS_DEBUGGING_SETUP.md for detailed instructions."



