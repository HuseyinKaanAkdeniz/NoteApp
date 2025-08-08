# Troubleshooting Guide

## Issues Resolved

### 1. Stack Overflow Error ✅ FIXED

**Problem**: The app was crashing with "Unhandled Exception: Stack Overflow" during launch.

**Root Cause**: Infinite recursion in `ContextUtils.showDialog` and `ContextUtils.showTimePicker` methods. These methods were calling themselves instead of the global Flutter functions.

**Solution**: 
- Updated `lib/Model/context_utils.dart` to use aliased imports (`import 'package:flutter/material.dart' as material;`)
- Explicitly call `material.showDialog` and `material.showTimePicker` to avoid naming conflicts
- Used `dynamic` typing for context parameters to maintain compatibility

**Files Modified**:
- `lib/Model/context_utils.dart` - Fixed recursive calls

### 2. INSTALL_FAILED_INSUFFICIENT_STORAGE

**Problem**: Android installation fails with "INSTALL_FAILED_INSUFFICIENT_STORAGE: Failed to override installation location"

**Root Cause**: The Android emulator or device doesn't have enough storage space to install the app.

## Solutions for Storage Issue

### Option 1: Clean and Rebuild (Recommended)
```bash
flutter clean
flutter pub get
flutter run
```

### Option 2: Free Up Emulator Storage
1. **Open Android Studio**
2. **Go to Tools > AVD Manager**
3. **Click the pencil icon (Edit) next to your emulator**
4. **Click "Show Advanced Settings"**
5. **Increase "Internal Storage" to at least 2GB**
6. **Click "Finish"**
7. **Wipe Data** (this will reset the emulator but free up space)

### Option 3: Use a Different Emulator
1. **Create a new emulator with more storage**
2. **Or use a physical device**

### Option 4: Clear Emulator Data
```bash
# Stop the emulator first
adb emu kill

# Clear data (this will reset the emulator)
adb shell rm -rf /data/data/com.example.noteapplication
```

### Option 5: Increase Emulator Storage via Command Line
```bash
# List available emulators
emulator -list-avds

# Start emulator with increased storage
emulator -avd [your_avd_name] -partition-size 2048
```

## Additional Troubleshooting Steps

### If the app still doesn't work:

1. **Check Flutter Doctor**:
   ```bash
   flutter doctor -v
   ```

2. **Update Flutter**:
   ```bash
   flutter upgrade
   ```

3. **Check Device/Emulator Status**:
   ```bash
   flutter devices
   ```

4. **Run with Verbose Logging**:
   ```bash
   flutter run -v
   ```

5. **Check for Permission Issues**:
   - Ensure the app has notification permissions
   - Check if the device allows app installation from unknown sources

## Prevention Tips

1. **Regular Cleanup**: Run `flutter clean` periodically
2. **Monitor Storage**: Keep at least 1GB free on emulators
3. **Use Physical Devices**: They often have more storage and better performance
4. **Update Dependencies**: Keep Flutter and packages updated

## Common Error Messages and Solutions

| Error | Solution |
|-------|----------|
| `INSTALL_FAILED_INSUFFICIENT_STORAGE` | Free up storage, increase emulator storage, or use a different device |
| `Stack Overflow` | ✅ Fixed - was caused by recursive function calls |
| `ADB exited with exit code 1` | Usually related to storage or device issues |
| `Looking up a deactivated widget's ancestor is unsafe` | ✅ Fixed - using ContextUtils for safe context handling |

## Testing the Fix

After applying the fixes:

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Test notifications**:
   - Go to a note detail page
   - Try scheduling a notification
   - Check if permission dialogs appear correctly

3. **Test context safety**:
   - Navigate between pages quickly
   - Check if any context-related errors appear

## Support

If you continue to experience issues:

1. **Check the logs** for specific error messages
2. **Try on a different device/emulator**
3. **Ensure all dependencies are up to date**
4. **Consider using a physical device for testing**

---

**Last Updated**: December 2024
**Status**: Stack Overflow ✅ Fixed, Storage issue requires device-specific action
