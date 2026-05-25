import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:noteapplication/Model/ScheduleNotification.dart';

class NotificationDebugPage extends StatefulWidget {
  const NotificationDebugPage({Key? key}) : super(key: key);

  @override
  State<NotificationDebugPage> createState() => _NotificationDebugPageState();
}

class _NotificationDebugPageState extends State<NotificationDebugPage> {
  List<PendingNotificationRequest> pendingNotifications = [];
  bool isLoading = false;
  String debugInfo = '';

  @override
  void initState() {
    super.initState();
    loadPendingNotifications();
    runDebugChecks();
  }

  Future<void> runDebugChecks() async {
    String info = '';

    // Exact alarm izni
    try {
      final canExact = await checkExactAlarmPermission();
      info += 'Exact Alarm Permission: ${canExact ? "GRANTED" : "DENIED"}\n';
    } catch (e) {
      info += 'Exact Alarm Permission Check Error: $e\n';
    }

    // Bildirim izni
    try {
      final service = NotificationService();
      final granted = await service.requestNotificationPermission();
      info += 'Notification Permission Granted: $granted\n';
    } catch (e) {
      info += 'Notification Permission Check Error: $e\n';
    }

    // Bekleyen bildirim sayısı (v19'da getNotificationChannels kaldırıldı)
    try {
      final pending = await getPendingNotifications();
      info += 'Pending Notifications: ${pending.length} adet\n';
    } catch (e) {
      info += 'Pending Check Error: $e\n';
    }

    if (!mounted) return;
    setState(() {
      debugInfo = info;
    });
  }

  Future<void> loadPendingNotifications() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final notifications = await getPendingNotifications();
      if (!mounted) return;
      setState(() {
        pendingNotifications = notifications;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Pending notifications yüklenemedi: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> testImmediateNotification() async {
    try {
      await showTestNotification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test bildirimi gönderildi!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> scheduleTestNotification() async {
    try {
      final scheduledTime = DateTime.now().add(const Duration(minutes: 1));
      await scheduleSpecificDateNotification(scheduledTime, 'Debug Test Notu');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bildirim ayarlandı: $scheduledTime'),
          backgroundColor: Colors.blue,
        ),
      );
      await loadPendingNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zamanlama hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> scheduleDailyTest() async {
    try {
      final now = DateTime.now();
      final testTime = TimeOfDay(
        hour: now.hour,
        minute: (now.minute + 1) % 60,
      );
      await scheduleDailyNotification(testTime, 'Günlük Debug Testi');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Günlük bildirim ayarlandı: ${testTime.format(context)}'),
          backgroundColor: Colors.blue,
        ),
      );
      await loadPendingNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Günlük zamanlama hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> cancelAllAndRefresh() async {
    try {
      await cancelAllNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm bildirimler iptal edildi'),
          backgroundColor: Colors.orange,
        ),
      );
      await loadPendingNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İptal hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              await loadPendingNotifications();
              await runDebugChecks();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Debug bilgileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Debug Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      debugInfo.isEmpty ? 'Yükleniyor...' : debugInfo,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test butonları
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: testImmediateNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Hemen Bildirim Gönder'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: scheduleTestNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('1 Dakika Sonra Bildirim'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: scheduleDailyTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Günlük Bildirim Test'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: cancelAllAndRefresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Tüm Bildirimleri İptal Et'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bekleyen bildirimler
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Bekleyen Bildirimler',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (pendingNotifications.isEmpty)
                      const Text(
                        'Bekleyen bildirim yok',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = pendingNotifications[index];
                          return ListTile(
                            leading: const Icon(Icons.notifications),
                            title: Text(notification.title ?? 'Başlık yok'),
                            subtitle: Text('ID: ${notification.id}'),
                            trailing: IconButton(
                              onPressed: () async {
                                await cancelNotification(notification.id);
                                await loadPendingNotifications();
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}