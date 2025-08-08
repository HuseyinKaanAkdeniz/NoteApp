import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:noteapplication/Model/context_utils.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Permission status enum
enum NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unknown,
}

// Notification permission manager
class NotificationPermissionManager {
  static Future<NotificationPermissionStatus> requestPermission() async {
    try {
      final status = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      return _mapPermissionStatus(status);
    } catch (e) {
      print('Permission request error: $e');
      return NotificationPermissionStatus.unknown;
    }
  }

  static Future<NotificationPermissionStatus> checkPermission() async {
    try {
      final status = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      
      return _mapPermissionStatus(status);
    } catch (e) {
      print('Permission check error: $e');
      return NotificationPermissionStatus.unknown;
    }
  }

  static NotificationPermissionStatus _mapPermissionStatus(bool? status) {
    if (status == null) return NotificationPermissionStatus.unknown;
    return status 
        ? NotificationPermissionStatus.granted 
        : NotificationPermissionStatus.denied;
  }

  static String getPermissionStatusMessage(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return 'Bildirim izni verildi';
      case NotificationPermissionStatus.denied:
        return 'Bildirim izni reddedildi';
      case NotificationPermissionStatus.permanentlyDenied:
        return 'Bildirim izni kalıcı olarak reddedildi. Ayarlardan manuel olarak etkinleştirin.';
      case NotificationPermissionStatus.restricted:
        return 'Bildirim izni kısıtlandı';
      case NotificationPermissionStatus.unknown:
        return 'Bildirim izni durumu bilinmiyor';
    }
  }

  static String getPermissionRequestMessage(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return 'Bildirimler zaten etkin!';
      case NotificationPermissionStatus.denied:
        return 'Bildirim izni gerekli. Lütfen izin verin.';
      case NotificationPermissionStatus.permanentlyDenied:
        return 'Bildirim izni kalıcı olarak reddedildi. Ayarlardan etkinleştirin.';
      case NotificationPermissionStatus.restricted:
        return 'Bildirim izni kısıtlandı. Ayarları kontrol edin.';
      case NotificationPermissionStatus.unknown:
        return 'Bildirim izni durumu belirlenemedi.';
    }
  }
}

void initializeNotifications() {
  print('Initializing notifications...');
  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // iOS ayarları da eklenebilir.
  );

  flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Bildirime tıklanınca yapılacak işlemler burada
      // Note: Context is not available here, handle navigation differently
      print('Notification clicked: ${response.payload}');
    },
  ).then((_) {
    print('Notification plugin initialized successfully');
    // Create notification channels after initialization
    _createNotificationChannels();
  }).catchError((error) {
    print('Error initializing notification plugin: $error');
  });
}

// Create notification channels for Android
void _createNotificationChannels() async {
  print('Creating notification channels...');
  
  const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
    'test_channel',
    'Test Kanalı',
    description: 'Test amaçlı bildirim kanalı',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    // Samsung-specific settings
    enableLights: true,
    ledColor: Color(0xFF2196F3),
    showBadge: true,
  );

  const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
    'daily_reminder_channel',
    'Günlük Hatırlatıcı',
    description: 'Günlük hatırlatıcı bildirimleri',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    // Samsung-specific settings
    enableLights: true,
    ledColor: Color(0xFF4CAF50),
    showBadge: true,
  );

  const AndroidNotificationChannel onceChannel = AndroidNotificationChannel(
    'once_reminder_channel',
    'Tek Seferlik Hatırlatıcı',
    description: 'Tek seferlik hatırlatıcı bildirimleri',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    // Samsung-specific settings
    enableLights: true,
    ledColor: Color(0xFFFF9800),
    showBadge: true,
  );

  const AndroidNotificationChannel specificChannel = AndroidNotificationChannel(
    'specific_date_channel',
    'Belirli Tarih Hatırlatıcı',
    description: 'Belirli tarih hatırlatıcı bildirimleri',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    // Samsung-specific settings
    enableLights: true,
    ledColor: Color(0xFFE91E63),
    showBadge: true,
  );

  try {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(testChannel);
    print('Test channel created');

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(dailyChannel);
    print('Daily channel created');

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(onceChannel);
    print('Once channel created');

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(specificChannel);
    print('Specific channel created');
    
    print('All notification channels created successfully');
  } catch (e) {
    print('Error creating notification channels: $e');
  }
}

// Check exact alarm permission
Future<bool> checkExactAlarmPermission() async {
  try {
    // Since canScheduleExactAlarms() doesn't exist, we'll try to schedule a test notification
    // and catch the exact_alarms_not_permitted error to determine permission status
    final now = DateTime.now().add(const Duration(seconds: 5));
    final testDate = tz.TZDateTime.from(now, tz.local);
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      999999, // Test ID
      'Test',
      'Test',
      testDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test',
          channelDescription: 'Test',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    
    // If we get here, exact alarms are permitted
    await flutterLocalNotificationsPlugin.cancel(999999);
    print('Can schedule exact alarms: true');
    return true;
  } catch (e) {
    if (e.toString().contains('exact_alarms_not_permitted')) {
      print('Can schedule exact alarms: false');
      return false;
    }
    print('Error checking exact alarm permission: $e');
    return false;
  }
}

// Permission check and request wrapper
Future<bool> ensureNotificationPermission(BuildContext context) async {
  return await ContextUtils.safeAsyncOperation<bool>(
    context: context,
    operation: () async {
      final permissionStatus = await NotificationPermissionManager.checkPermission();
      
      if (permissionStatus == NotificationPermissionStatus.granted) {
        return true;
      }

      // Show permission request dialog
      final shouldRequest = await ContextUtils.showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Bildirim İzni Gerekli'),
          content: Text(NotificationPermissionManager.getPermissionRequestMessage(permissionStatus)),
          actions: [
            if (permissionStatus == NotificationPermissionStatus.permanentlyDenied)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  _openAppSettings();
                },
                child: const Text('Ayarları Aç'),
              )
            else
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal'),
              ),
            if (permissionStatus != NotificationPermissionStatus.permanentlyDenied)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('İzin Ver'),
              ),
          ],
        ),
      );

      if (shouldRequest == true) {
        final newStatus = await NotificationPermissionManager.requestPermission();
        return newStatus == NotificationPermissionStatus.granted;
      }

      return false;
    },
    onContextUnmounted: () => false,
  ) ?? false;
}

// Open app settings (Android)
void _openAppSettings() {
  // This would typically use url_launcher package to open settings
  // For now, we'll just show a message
  print('Please manually enable notifications in app settings');
}

// Test bildirimi gönderme
Future<void> showTestNotification() async {
  print('Showing test notification...');
  try {
    await flutterLocalNotificationsPlugin.show(
      999,
      'Test Bildirimi',
      'Bu bir deneme bildirimi.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Kanalı',
          channelDescription: 'Test amaçlı bildirim kanalı',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
    print('Test notification shown successfully');
  } catch (e) {
    print('Error showing test notification: $e');
    rethrow;
  }
}

// Smart notification scheduling with fallback
Future<void> _scheduleNotificationWithFallback({
  required int notificationId,
  required String title,
  required String body,
  required tz.TZDateTime scheduledDate,
  required String channelId,
  required String channelName,
  required String channelDescription,
  bool isRepeating = false,
}) async {
  try {
    // Try exact scheduling first
    print('Attempting exact scheduling for: ${scheduledDate.toString()}');
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      NotificationDetails(
                 android: AndroidNotificationDetails(
           channelId,
           channelName,
           channelDescription: channelDescription,
           importance: Importance.max,
           priority: Priority.max,
           playSound: true,
           enableVibration: true,
           icon: '@mipmap/ic_launcher',
           category: AndroidNotificationCategory.reminder,
           // Samsung-specific settings
           showWhen: true,
           when: scheduledDate.millisecondsSinceEpoch,
           autoCancel: false,
           ongoing: false,
           onlyAlertOnce: false,
           // Force notification to show
           visibility: NotificationVisibility.public,
         ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: isRepeating ? DateTimeComponents.time : null,
    );
    
    print('Exact scheduling successful');
  } catch (e) {
    print('Exact scheduling failed: $e');
    
    // Fallback to inexact scheduling with aggressive settings
    try {
      print('Attempting inexact scheduling as fallback');
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.max, // Use max priority
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
            category: AndroidNotificationCategory.reminder,
            // Samsung-specific aggressive settings
            showWhen: true,
            when: scheduledDate.millisecondsSinceEpoch,
            autoCancel: false,
            ongoing: false,
            onlyAlertOnce: false,
            visibility: NotificationVisibility.public,
            // Additional Samsung settings
            enableLights: true,
            ledColor: const Color(0xFF2196F3),
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: isRepeating ? DateTimeComponents.time : null,
      );
      
      print('Inexact scheduling successful (fallback)');
    } catch (fallbackError) {
      print('Both exact and inexact scheduling failed: $fallbackError');
      rethrow;
    }
  }
}

// Günlük tekrarlayan bildirim
Future<void> scheduleDailyNotification(TimeOfDay selectedTime, String noteTitle) async {
  try {
    final now = tz.TZDateTime.now(tz.local);
    
    // Create scheduled date for today
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Generate a unique ID based on time
    final notificationId = selectedTime.hour * 100 + selectedTime.minute;

    print('Scheduling daily notification for: ${scheduledDate.toString()}');
    print('Notification ID: $notificationId');

    await _scheduleNotificationWithFallback(
      notificationId: notificationId,
      title: 'Hatırlatma: $noteTitle',
      body: 'Notunuzu kontrol etmeyi unutmayın!',
      scheduledDate: scheduledDate,
      channelId: 'daily_reminder_channel',
      channelName: 'Günlük Hatırlatıcı',
      channelDescription: 'Günlük hatırlatıcı bildirimleri',
      isRepeating: true,
    );

    print('Daily notification scheduled successfully');
  } catch (e) {
    print('Error scheduling daily notification: $e');
    rethrow;
  }
}

// Tek seferlik bildirim
Future<void> scheduleOnceNotification(TimeOfDay selectedTime, String noteTitle) async {
  try {
    final now = tz.TZDateTime.now(tz.local);
    
    // Create scheduled date for today
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Generate a unique ID based on current timestamp
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    print('Scheduling once notification for: ${scheduledDate.toString()}');
    print('Notification ID: $notificationId');

    await _scheduleNotificationWithFallback(
      notificationId: notificationId,
      title: 'Hatırlatma: $noteTitle',
      body: 'Notunuzu kontrol etmeyi unutmayın!',
      scheduledDate: scheduledDate,
      channelId: 'once_reminder_channel',
      channelName: 'Tek Seferlik Hatırlatıcı',
      channelDescription: 'Tek seferlik hatırlatıcı bildirimleri',
      isRepeating: false,
    );

    print('Once notification scheduled successfully');
  } catch (e) {
    print('Error scheduling once notification: $e');
    rethrow;
  }
}

// Belirli bir tarih ve saatte bildirim
Future<void> scheduleSpecificDateNotification(DateTime selectedDateTime, String noteTitle) async {
  try {
    final scheduledDate = tz.TZDateTime.from(selectedDateTime, tz.local);
    final notificationId = selectedDateTime.millisecondsSinceEpoch ~/ 1000;

    print('Scheduling specific date notification for: ${scheduledDate.toString()}');
    print('Notification ID: $notificationId');

    await _scheduleNotificationWithFallback(
      notificationId: notificationId,
      title: 'Hatırlatma: $noteTitle',
      body: 'Notunuzu kontrol etmeyi unutmayın!',
      scheduledDate: scheduledDate,
      channelId: 'specific_date_channel',
      channelName: 'Belirli Tarih Hatırlatıcı',
      channelDescription: 'Belirli tarih hatırlatıcı bildirimleri',
      isRepeating: false,
    );

    print('Specific date notification scheduled successfully');
  } catch (e) {
    print('Error scheduling specific date notification: $e');
    rethrow;
  }
}

// Bildirimleri iptal etme
Future<void> cancelNotification(int id) async {
  await flutterLocalNotificationsPlugin.cancel(id);
}

// Tüm bildirimleri iptal etme
Future<void> cancelAllNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();
}

// Bekleyen bildirimleri listeleme
Future<List<PendingNotificationRequest>> getPendingNotifications() async {
  return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
}

// Error handling wrapper for notification operations
Future<bool> safeNotificationOperation(Future<void> Function() operation, BuildContext context) async {
  return await ContextUtils.safeAsyncOperation<bool>(
    context: context,
    operation: () async {
      // Check permission first
      final hasPermission = await ensureNotificationPermission(context);
      if (!hasPermission) {
        ContextUtils.showSnackBar(
          context,
          const SnackBar(
            content: Text('Bildirim izni gerekli'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }

      await operation();
      return true;
    },
    onContextUnmounted: () => false,
  ) ?? false;
}
