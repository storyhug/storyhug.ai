#!/bin/bash
# Launch Android Emulator with Google DNS

# Stop any running emulators first
echo "🛑 Stopping any running emulators..."
adb emu kill 2>/dev/null || true
sleep 2

# Get the first available AVD
AVD_NAME=$(emulator -list-avds | head -n 1)

if [ -z "$AVD_NAME" ]; then
    echo "❌ No AVD found. Create one in Android Studio first."
    exit 1
fi

echo "🚀 Launching $AVD_NAME with Google DNS (8.8.8.8)..."
echo "📱 This will fix the 'Failed host lookup' error"
echo ""
emulator -avd "$AVD_NAME" -dns-server 8.8.8.8,8.8.4.4 &
