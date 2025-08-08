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
    
    // Check exact alarm permission
    try {
      final canScheduleExactAlarms = await checkExactAlarmPermission();
      info += 'Exact Alarm Permission: ${canScheduleExactAlarms ? "GRANTED" : "DENIED"}\n';
    } catch (e) {
      info += 'Exact Alarm Permission Check Error: $e\n';
    }

    // Check notification permission
    try {
      final permissionStatus = await NotificationPermissionManager.checkPermission();
      info += 'Notification Permission: ${permissionStatus.name}\n';
    } catch (e) {
      info += 'Notification Permission Check Error: $e\n';
    }

    // Check notification channels
    try {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final channels = await androidPlugin.getNotificationChannels();
        if (channels != null) {
          info += 'Notification Channels: ${channels.length} found\n';
          for (var channel in channels) {
            info += '  - ${channel.id}: ${channel.importance.name}\n';
          }
        } else {
          info += 'Notification Channels: null\n';
        }
      }
    } catch (e) {
      info += 'Channel Check Error: $e\n';
    }

    setState(() {
      debugInfo = info;
    });
  }

  Future<void> loadPendingNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final notifications = await getPendingNotifications();
      setState(() {
        pendingNotifications = notifications;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading pending notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> testImmediateNotification() async {
    try {
      await showTestNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> scheduleTestNotification() async {
    try {
      final now = DateTime.now();
      final scheduledTime = now.add(const Duration(minutes: 1));
      
      await scheduleSpecificDateNotification(scheduledTime, 'Debug Test Note');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification scheduled for: ${scheduledTime.toString()}'),
          backgroundColor: Colors.blue,
        ),
      );
      
      // Reload pending notifications
      await loadPendingNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scheduling: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> scheduleDailyTest() async {
    try {
      final now = DateTime.now();
      final testTime = TimeOfDay(hour: now.hour, minute: (now.minute + 1) % 60);
      
      await scheduleDailyNotification(testTime, 'Daily Debug Test');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily notification scheduled for: ${testTime.format(context)}'),
          backgroundColor: Colors.blue,
        ),
      );
      
      await loadPendingNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scheduling daily: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
      await loadPendingNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling: $e'),
          backgroundColor: Colors.red,
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Debug Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Debug Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      debugInfo.isEmpty ? 'Loading debug info...' : debugInfo,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: testImmediateNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Send Test Notification Now'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: scheduleTestNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Schedule Test (1 min from now)'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: scheduleDailyTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Schedule Daily Test'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: cancelAllNotifications,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel All Notifications'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Pending Notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Pending Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                        'No pending notifications',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ...pendingNotifications.map((notification) => ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text(notification.title ?? 'No title'),
                        subtitle: Text('ID: ${notification.id}'),
                        trailing: IconButton(
                          onPressed: () async {
                            await flutterLocalNotificationsPlugin.cancel(notification.id);
                            await loadPendingNotifications();
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      )),
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
