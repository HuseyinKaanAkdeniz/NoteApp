# Notification Debugging Guide

## Problem: Test notifications work, but scheduled notifications don't fire

### ✅ **What I Fixed:**

1. **Changed Android Schedule Mode**: 
   - From: `AndroidScheduleMode.inexact` (can be delayed by system)
   - To: `AndroidScheduleMode.exactAllowWhileIdle` (fires exactly on time, even when device is idle)

2. **Added Proper Notification Channels**: 
   - Created dedicated channels for each notification type
   - Set proper importance and priority levels

3. **Added Error Handling and Logging**: 
   - Added try-catch blocks with detailed error messages
   - Added print statements to track scheduling process

4. **Improved Notification IDs**: 
   - Better unique ID generation to prevent conflicts

### 🔧 **Additional Steps to Ensure Notifications Work:**

#### 1. **Check Device Settings**

**Battery Optimization:**
- Go to **Settings > Apps > Your App > Battery**
- Set to **"Don't optimize"** or **"Unrestricted"**

**Notification Settings:**
- Go to **Settings > Apps > Your App > Notifications**
- Ensure **"Show notifications"** is ON
- Enable **"Allow notification dot"** and **"Sound"**

**Do Not Disturb:**
- Make sure **Do Not Disturb** mode is OFF
- Or add your app to **"Allowed apps"** in Do Not Disturb settings

#### 2. **Check App Permissions**

**Notification Permission:**
- Go to **Settings > Apps > Your App > Permissions**
- Ensure **"Notifications"** permission is granted

**Auto-start Permission (for some devices):**
- Some Android devices (Xiaomi, Huawei, etc.) require auto-start permission
- Go to **Settings > Apps > Your App > Auto-start** and enable it

#### 3. **Test with Different Times**

**Immediate Test:**
- Schedule a notification for 1-2 minutes from now
- Keep the app open and wait
- Check if the notification appears

**Future Test:**
- Schedule for a specific time (e.g., 14:30)
- Close the app completely
- Wait for the scheduled time
- Check if notification appears

#### 4. **Debug Commands**

**Check Pending Notifications:**
```bash
# In your app, go to notification management page
# Or add this debug code temporarily:

Future<void> debugPendingNotifications() async {
  final pending = await getPendingNotifications();
  print('Pending notifications: ${pending.length}');
  for (var notification in pending) {
    print('ID: ${notification.id}, Title: ${notification.title}');
  }
}
```

**Check Notification Channels:**
```bash
# Add this to your app temporarily:

Future<void> debugNotificationChannels() async {
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  
  if (androidPlugin != null) {
    final channels = await androidPlugin.getNotificationChannels();
    print('Available channels: ${channels.length}');
    for (var channel in channels) {
      print('Channel: ${channel.id}, Importance: ${channel.importance}');
    }
  }
}
```

#### 5. **Common Issues and Solutions**

| Issue | Solution |
|-------|----------|
| **Notifications don't fire when app is closed** | Check battery optimization settings |
| **Notifications are delayed** | Ensure using `AndroidScheduleMode.exactAllowWhileIdle` |
| **No sound/vibration** | Check device notification settings and app permissions |
| **Notifications appear but no sound** | Check device volume and notification sound settings |
| **Notifications work on emulator but not device** | Check device-specific battery optimization |

#### 6. **Device-Specific Settings**

**Samsung:**
- Settings > Apps > Your App > Battery > Background activity limits > Allow background activity

**Xiaomi:**
- Settings > Apps > Your App > Permissions > Auto-start > Allow
- Settings > Battery & performance > App battery saver > Your App > No restrictions

**Huawei:**
- Settings > Apps > Your App > Permissions > Auto-launch > Allow
- Settings > Battery > Launch > Your App > Allow

**OnePlus:**
- Settings > Apps > Your App > Battery > Background activity > Allow

#### 7. **Testing Checklist**

- [ ] Test notification works immediately (test button)
- [ ] Schedule notification for 1-2 minutes from now
- [ ] Keep app open and wait for notification
- [ ] Schedule notification for specific time
- [ ] Close app completely and wait for notification
- [ ] Check device notification settings
- [ ] Check battery optimization settings
- [ ] Check Do Not Disturb settings

#### 8. **Log Analysis**

**Look for these log messages:**
```
Scheduling daily notification for: [timestamp]
Notification ID: [number]
Daily notification scheduled successfully
```

**If you see errors:**
```
Error scheduling daily notification: [error message]
```

#### 9. **Alternative Solutions**

**If notifications still don't work:**

1. **Use WorkManager** (for more reliable background tasks)
2. **Use AlarmManager** (for exact timing)
3. **Use Firebase Cloud Messaging** (for server-side notifications)

#### 10. **Quick Test Code**

Add this to your app temporarily for testing:

```dart
// Test immediate notification
ElevatedButton(
  onPressed: () async {
    await showTestNotification();
    print('Test notification sent');
  },
  child: Text('Test Now'),
),

// Test scheduled notification (1 minute from now)
ElevatedButton(
  onPressed: () async {
    final now = DateTime.now();
    final scheduledTime = now.add(Duration(minutes: 1));
    await scheduleSpecificDateNotification(scheduledTime, 'Test Note');
    print('Scheduled for: $scheduledTime');
  },
  child: Text('Schedule 1 min from now'),
),
```

---

**Last Updated**: December 2024
**Status**: Fixed scheduling issues, added comprehensive debugging guide
