import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ============================================================================
// NotificationService — Singleton
// ============================================================================

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance =
      NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Kanal ID'leri
  static const String _channelDailyId    = 'daily_reminder_channel';
  static const String _channelOnceId     = 'once_reminder_channel';
  static const String _channelSpecificId = 'specific_date_channel';
  static const String _channelTestId     = 'test_channel';

  bool _initialized = false;

  // --------------------------------------------------------------------------
  // init
  // --------------------------------------------------------------------------
  Future<void> init({
    AndroidInitializationSettings? androidInitSettings,
  }) async {
    if (_initialized) return;

    // 1. Zaman dilimi verilerini yükle
    tz.initializeTimeZones();

    // 2. Cihazın yerel zaman dilimini al
    //    flutter_timezone 5.x → getLocalTimezone() direkt String döndürür
    //    Eski sürümler       → .identifier ile String alınır
    //    Her iki durumu da try/catch ile yakala
    try {
      final dynamic rawTz = await FlutterTimezone.getLocalTimezone();
      final String tzName =
          (rawTz is String) ? rawTz : (rawTz as dynamic).identifier as String;
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('Timezone set to: $tzName');
    } catch (e) {
      debugPrint('Warning: could not set timezone, using UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    // 3. Başlatma ayarları
    final AndroidInitializationSettings androidSettings =
        androidInitSettings ??
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Bildirime tıklandı: ${response.payload}');
        // Navigasyon uygulama katmanında yönetilmeli
      },
    );

    // 4. Kanalları oluştur (sadece Android)
    await _createNotificationChannels();

    _initialized = true;
    debugPrint('NotificationService başlatıldı');
  }

  // --------------------------------------------------------------------------
  // Bildirim kanalları
  // --------------------------------------------------------------------------
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return;

    final channels = [
      const AndroidNotificationChannel(
        _channelDailyId,
        'Günlük Hatırlatıcı',
        description: 'Günlük hatırlatıcı bildirimleri',
        importance: Importance.max,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        _channelOnceId,
        'Tek Seferlik Hatırlatıcı',
        description: 'Tek seferlik hatırlatıcı bildirimleri',
        importance: Importance.max,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        _channelSpecificId,
        'Belirli Tarih Hatırlatıcı',
        description: 'Belirli tarih hatırlatıcı bildirimleri',
        importance: Importance.max,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        _channelTestId,
        'Test Kanalı',
        description: 'Test amaçlı bildirimler',
        importance: Importance.max,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      try {
        await androidImpl.createNotificationChannel(channel);
      } catch (e) {
        debugPrint('Kanal oluşturma hatası (${channel.id}): $e');
      }
    }

    debugPrint('Bildirim kanalları oluşturuldu');
  }

  // --------------------------------------------------------------------------
  // İzin yönetimi
  // --------------------------------------------------------------------------

  /// Android 13+ için POST_NOTIFICATIONS runtime izni ister.
  Future<bool> requestNotificationPermission() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImpl?.requestNotificationsPermission() ?? false;
      debugPrint('Bildirim izni: $granted');
      return granted;
    } catch (e) {
      debugPrint('requestNotificationPermission hatası: $e');
      return false;
    }
  }

  /// Android 12+ için tam zamanlı alarm iznini ayarlar ekranında açar.
  Future<void> requestExactAlarmPermission({String? packageName}) async {
    if (!Platform.isAndroid) return;
    try {
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        arguments: packageName != null
            ? <String, dynamic>{
                'android.provider.extra.APP_PACKAGE': packageName,
              }
            : null,
      );
      await intent.launch();
    } catch (e) {
      debugPrint('requestExactAlarmPermission hatası: $e');
    }
  }

  /// Tam zamanlı alarm iznini test eder.
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      final now =
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      await _plugin.zonedSchedule(
        999999,
        'izin_testi',
        'izin_testi',
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
      if (e.toString().contains('exact_alarms_not_permitted')) return false;
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // İç zamanlama yardımcısı
  // --------------------------------------------------------------------------
  Future<void> _zonedSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate, {
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
      debugPrint('Tam zamanlı bildirim ayarlandı — id=$id tarih=$scheduledDate');
    } catch (e) {
      debugPrint('Tam zamanlı alarm başarısız ($e). Yaklaşık zamanlıya geçiliyor.');
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: matchComponents,
      );
      debugPrint('Yaklaşık zamanlı bildirim ayarlandı — id=$id tarih=$scheduledDate');
    }
  }

  // --------------------------------------------------------------------------
  // Herkese açık zamanlama metodları
  // --------------------------------------------------------------------------

  /// Anlık test bildirimi gönderir.
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

  /// Her gün belirtilen saatte tekrarlayan bildirim.
  Future<void> scheduleDaily(
    TimeOfDay time,
    String title, {
    int? id,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final notificationId = id ?? (time.hour * 100 + time.minute);
    await _zonedSchedule(
      notificationId,
      title,
      'Günlük hatırlatmanız var',
      scheduled,
      matchComponents: DateTimeComponents.time,
      channelId: _channelDailyId,
    );
  }

  /// Bir kez belirtilen saatte bildirim (bugün geçtiyse yarın).
  Future<void> scheduleOnce(
    TimeOfDay time,
    String title, {
    int? id,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final notificationId =
        id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _zonedSchedule(
      notificationId,
      title,
      'Hatırlatmanız var',
      scheduled,
      channelId: _channelOnceId,
    );
  }

  /// Belirli bir tarih ve saatte tek seferlik bildirim.
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
      channelId: _channelSpecificId,
    );
  }

  // --------------------------------------------------------------------------
  // İptal
  // --------------------------------------------------------------------------
  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<void> cancelAll()        async => _plugin.cancelAll();

  Future<List<PendingNotificationRequest>> getPending() async =>
      _plugin.pendingNotificationRequests();
}

// ============================================================================
// Global sarmalayıcılar (Geriye dönük uyumluluk)
// ============================================================================

final _service = NotificationService();

/// Uygulamanın main() içinde çağrılmalı.
Future<void> initializeNotifications() async {
  await _service.init();
}

/// Bildirim izinlerini kontrol eder; gerekiyorsa kullanıcıyı ayarlara yönlendirir.
Future<bool> ensureNotificationPermission(BuildContext context) async {
  final granted = await _service.requestNotificationPermission();
  if (!granted) return false;

  if (Platform.isAndroid) {
    final canExact = await _service.canScheduleExactAlarms();
    if (!canExact && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Tam zamanlı hatırlatıcılar için izin gerekiyor.'),
          action: SnackBarAction(
            label: 'Ayarlar',
            onPressed: () => _service.requestExactAlarmPermission(),
          ),
        ),
      );
      return false;
    }
  }
  return true;
}

Future<void> scheduleSpecificDateNotification(
        DateTime date, String title) async =>
    _service.scheduleSpecificDate(date, title);

Future<void> scheduleDailyNotification(
        TimeOfDay time, String title) async =>
    _service.scheduleDaily(time, title);

Future<void> scheduleOnceNotification(
        TimeOfDay time, String title) async =>
    _service.scheduleOnce(time, title);

Future<void> showTestNotification() async =>
    _service.showTestNotification();

Future<List<PendingNotificationRequest>> getPendingNotifications() async =>
    _service.getPending();

Future<void> cancelNotification(int id) async => _service.cancel(id);

Future<void> cancelAllNotifications() async => _service.cancelAll();

Future<bool> checkExactAlarmPermission() async =>
    _service.canScheduleExactAlarms();

/// Bildirim işlemlerini try/catch ile güvenli şekilde çalıştırır.
Future<bool> safeNotificationOperation(
  Future<void> Function() operation,
  BuildContext context,
) async {
  try {
    await operation();
    return true;
  } catch (e) {
    debugPrint('Bildirim işlemi başarısız: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
    return false;
  }
}

// ============================================================================
// İzin Yöneticisi
// ============================================================================

enum NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unknown,
}

class NotificationPermissionManager {
  static Future<NotificationPermissionStatus> checkPermission() async {
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
      NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return 'Bildirim izni verildi';
      case NotificationPermissionStatus.denied:
        return 'Bildirim izni reddedildi';
      case NotificationPermissionStatus.permanentlyDenied:
        return 'Bildirim izni kalıcı olarak reddedildi, '
            'ayarlardan açmanız gerekebilir';
      case NotificationPermissionStatus.restricted:
        return 'Bildirim izni kısıtlı';
      case NotificationPermissionStatus.unknown:
        return 'Bilinmeyen durum';
    }
  }
}