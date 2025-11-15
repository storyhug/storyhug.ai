# Quick Fix: Emulator DNS Issue

## Problem
- Emulator shows "Failed host lookup" error for Supabase
- Works fine on real devices
- Multiple emulator instances error

## Solution

### Option 1: Stop and Restart with DNS (Recommended)

1. **Stop the current emulator:**
   ```bash
   # In Android Studio, click the Stop button (square icon)
   # OR use terminal:
   adb emu kill
   ```

2. **Launch with DNS configured:**
   ```bash
   ./launch_emulator_with_dns.sh
   ```

### Option 2: Configure DNS in Running Emulator

If you want to keep your current emulator running:

1. **Open emulator settings:**
   - Click the three dots (`...`) in emulator toolbar
   - Go to **Settings** → **Network**

2. **Set DNS:**
   - Change DNS to: `8.8.8.8`
   - Click **Save**

3. **Restart the emulator** (cold boot)

### Option 3: Use Android Studio

1. **Stop current emulator** (Stop button in toolbar)

2. **Edit AVD:**
   - Tools → AVD Manager
   - Click pencil icon (Edit) next to your emulator
   - Show Advanced Settings
   - Under Network, set DNS: `8.8.8.8`
   - Click Finish

3. **Cold Boot:**
   - Click dropdown arrow next to emulator
   - Select "Cold Boot Now"

### Option 4: Manual Launch Command

```bash
# Stop existing
adb emu kill

# Wait a few seconds
sleep 3

# Launch with DNS (replace Medium_Phone_API_36.1 with your AVD name)
emulator -avd Medium_Phone_API_36.1 -dns-server 8.8.8.8,8.8.4.4 &
```

## Verify It Works

After restarting, test the connection:

```bash
# Test DNS resolution
adb shell nslookup glqthbevuzituddwgpev.supabase.co

# Test connectivity
adb shell ping -c 3 8.8.8.8
```

Then try logging in again in your Flutter app.

## Why This Happens

Android emulators sometimes don't inherit DNS settings correctly from your Mac, causing hostname resolution failures.

## Still Not Working?

- Restart Android Studio
- Create a new AVD with fresh settings
- Use a real Android device via USB debugging (most reliable)

