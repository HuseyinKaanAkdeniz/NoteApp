// flutter_notifications_service.dart
// Tek dosyada sade, güvenli ve Samsung/Android12+ uyumlu bildirim servisi

import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance =
      NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelDailyId = 'daily_reminder_channel';
  static const String _channelOnceId = 'once_reminder_channel';
  static const String _channelSpecificId = 'specific_date_channel';
  static const String _channelTestId = 'test_channel';

  bool _initialized = false;

  Future<void> init({
    AndroidInitializationSettings? androidInitSettings,
    WindowsInitializationSettings? windowsInitSettings,
  }) async {
    if (_initialized) return;

    tz.initializeTimeZones();

    try {
      final String tzName =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('Timezone set to: $tzName');
    } catch (e) {
      debugPrint('Warning: could not set timezone: $e');
    }

    final AndroidInitializationSettings androidSettings =
        androidInitSettings ??
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    final WindowsInitializationSettings windowsSettings =
        windowsInitSettings ??
        const WindowsInitializationSettings(
          appName: 'NoteApplication',
          appUserModelId: 'com.example.noteapplication',
          guid: '{771CF256-F893-4F32-9D10-3B4A0C312355}',
        );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      windows: windowsSettings,
      // iOS / macOS initialization can be added here if needed
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        // navigation should be handled by app-level routing (not here)
      },
    );

    await _createNotificationChannels();

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final AndroidNotificationChannel daily = AndroidNotificationChannel(
      _channelDailyId,
      'Günlük Hatırlatıcı',
      description: 'Günlük hatırlatıcı bildirimleri',
      importance: Importance.max,
      playSound: true,
    );

    final AndroidNotificationChannel once = AndroidNotificationChannel(
      _channelOnceId,
      'Tek Seferlik Hatırlatıcı',
      description: 'Tek seferlik hatırlatıcı bildirimleri',
      importance: Importance.max,
      playSound: true,
    );

    final AndroidNotificationChannel specific = AndroidNotificationChannel(
      _channelSpecificId,
      'Belirli Tarih Hatırlatıcı',
      description: 'Belirli tarih hatırlatıcı bildirimleri',
      importance: Importance.max,
      playSound: true,
    );

    final AndroidNotificationChannel test = AndroidNotificationChannel(
      _channelTestId,
      'Test Kanalı',
      description: 'Test amaçlı bildirimler',
      importance: Importance.max,
      playSound: true,
    );

    final androidImpl =
        _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
            >();

    try {
      await androidImpl?.createNotificationChannel(daily);
      await androidImpl?.createNotificationChannel(once);
      await androidImpl?.createNotificationChannel(specific);
      await androidImpl?.createNotificationChannel(test);
      debugPrint('Channels created');
    } catch (e) {
      debugPrint('Channel creation error: $e');
    }
  }

  // --- Permissions ---
  /// Android 13+ requires POST_NOTIFICATIONS runtime permission.
  /// For exact alarms on Android 12+ the user may need to grant schedule-exact-alarm in settings.
  Future<bool> requestNotificationPermission() async {
    try {
      final androidImpl =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final granted =
          await androidImpl?.requestNotificationsPermission() ?? false;
      debugPrint('Notifications permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('requestNotificationPermission error: $e');
      return false;
    }
  }

  /// Opens the Android settings screen where user can allow exact alarms for your app.
  Future<void> requestExactAlarmPermission({String? packageName}) async {
    if (!Platform.isAndroid) return;

    try {
      // Android Settings action: REQUEST_SCHEDULE_EXACT_ALARM
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        arguments:
            packageName != null
                ? <String, dynamic>{
                  'android.provider.extra.APP_PACKAGE': packageName,
                }
                : null,
      );
      await intent.launch();
    } catch (e) {
      debugPrint('requestExactAlarmPermission error: $e');
    }
  }

  // Check by trying to schedule a test exact alarm and catching errors
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;

    try {
      final now = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      await _plugin.zonedSchedule(
        999999,
        'permission_test',
        'permission_test',
        now,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelTestId,
            'Test',
            channelDescription: 'Test',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      await _plugin.cancel(999999);
      return true;
    } catch (e) {
      final message = e.toString();
      if (message.contains('exact_alarms_not_permitted')) {
        return false;
      }
      // If some other error happened, return false conservatively
      return false;
    }
  }

  // --- Scheduling helpers ---

  Future<void> showTestNotification() async {
    await _plugin.show(
      1,
      'Test Bildirimi',
      'Bu bir deneme bildirimi.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelTestId,
          'Test Kanalı',
          channelDescription: 'Test amaçlı bildirimler',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> _zonedSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate, {
    bool repeating = false,
    DateTimeComponents? matchComponents,
    required String channelId,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        channelDescription: 'Hatırlatıcı kanal',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
      );
      debugPrint('Scheduled exact: id=$id date=$scheduledDate');
    } catch (e) {
      debugPrint('Exact schedule failed ($e). Trying inexact fallback');
      // fallback to inexact
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: matchComponents,
      );
      debugPrint('Scheduled inexact fallback: id=$id date=$scheduledDate');
    }
  }

  /// Günlük tekrarlayan bildirim (sadece saat/dakika eşleşmesi)
  Future<void> scheduleDaily(TimeOfDay time, String title, {int? id}) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now))
      scheduled = scheduled.add(const Duration(days: 1));

    final notificationId = id ?? (time.hour * 100 + time.minute);

    await _zonedSchedule(
      notificationId,
      title,
      'Günlük hatırlatmanız var',
      scheduled,
      repeating: true,
      matchComponents: DateTimeComponents.time,
      channelId: _channelDailyId,
    );
  }

  /// Tek seferlik bildirim (sadece saat/dakika için)
  Future<void> scheduleOnce(TimeOfDay time, String title, {int? id}) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now))
      scheduled = scheduled.add(const Duration(days: 1));

    final notificationId = id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _zonedSchedule(
      notificationId,
      title,
      'Hatırlatmanız var',
      scheduled,
      repeating: false,
      channelId: _channelOnceId,
    );
  }

  /// Belirli tarih ve saatte tek seferlik bildirim
  Future<void> scheduleSpecificDate(
    DateTime dateTime,
    String title, {
    int? id,
  }) async {
    final tz.TZDateTime scheduled = tz.TZDateTime.from(dateTime, tz.local);
    final notificationId = id ?? dateTime.millisecondsSinceEpoch ~/ 1000;

    await _zonedSchedule(
      notificationId,
      title,
      'Hatırlatmanız var',
      scheduled,
      repeating: false,
      channelId: _channelSpecificId,
    );
  }

  // Cancel
  Future<void> cancel(int id) async => await _plugin.cancel(id);
  Future<void> cancelAll() async => await _plugin.cancelAll();

  Future<List<PendingNotificationRequest>> getPending() async =>
      await _plugin.pendingNotificationRequests();
}

// ============================================================================
// GLOBAL WRAPPERS & HELPERS (Backward Compatibility)
// ============================================================================

final _service = NotificationService();

/// Global initializer
Future<void> initializeNotifications() async {
  await _service.init();
}

/// Helper method to ensure we have permissions before doing something
Future<bool> ensureNotificationPermission(BuildContext context) async {
  final granted = await _service.requestNotificationPermission();
  if (granted) {
    // Also check exact alarm permission if on Android
    if (Platform.isAndroid) {
      final canExact = await _service.canScheduleExactAlarms();
      if (!canExact) {
        // Option: Show dialog or snackbar to user explaining they need to allow exact alarms
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tam zamanlı hatırlatıcılar için izin gerekiyor.'),
              action: SnackBarAction(
                label: 'Ayarlar',
                onPressed: _openAlarmSettings,
              ),
            ),
          );
        }
        return false;
      }
    }
  }
  return granted;
}

void _openAlarmSettings() async {
  await _service.requestExactAlarmPermission();
}

/// Wrapper for specific date
Future<void> scheduleSpecificDateNotification(
  DateTime date,
  String title,
) async {
  await _service.scheduleSpecificDate(date, title);
}

/// Wrapper for daily
Future<void> scheduleDailyNotification(TimeOfDay time, String title) async {
  await _service.scheduleDaily(time, title);
}

/// Wrapper for once
Future<void> scheduleOnceNotification(TimeOfDay time, String title) async {
  await _service.scheduleOnce(time, title);
}

/// Wrapper for test
Future<void> showTestNotification() async {
  await _service.showTestNotification();
}

/// Wrapper for pending
Future<List<PendingNotificationRequest>> getPendingNotifications() async {
  return _service.getPending();
}

/// Wrapper for cancel
Future<void> cancelNotification(int id) async {
  await _service.cancel(id);
}

/// Wrapper for cancel all
Future<void> cancelAllNotifications() async {
  await _service.cancelAll();
}

/// Helper for safe operations with context
Future<bool> safeNotificationOperation(
  Future<void> Function() operation,
  BuildContext context,
) async {
  try {
    await operation();
    return true;
  } catch (e) {
    debugPrint('Notification operation failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
    return false;
  }
}

Future<bool> checkExactAlarmPermission() async {
  return _service.canScheduleExactAlarms();
}

// --- Permission Manager Classes (Restored) ---

enum NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unknown,
}

class NotificationPermissionManager {
  static Future<NotificationPermissionStatus> checkPermission() async {
    // Simple mapping for now
    final granted = await _service.requestNotificationPermission();
    return granted
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  static Future<NotificationPermissionStatus> requestPermission() async {
    final granted = await _service.requestNotificationPermission();
    return granted
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  static String getPermissionStatusMessage(
    NotificationPermissionStatus status,
  ) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return 'Bildirim izni verildi';
      case NotificationPermissionStatus.denied:
        return 'Bildirim izni reddedildi';
      case NotificationPermissionStatus.permanentlyDenied:
        return 'Bildirim izni kalıcı olarak reddedildi, ayarlardan açmanız gerekebilir';
      case NotificationPermissionStatus.restricted:
        return 'Bildirim izni kısıtlı';
      case NotificationPermissionStatus.unknown:
      default:
        return 'Bilinmeyen durum';
    }
  }
}