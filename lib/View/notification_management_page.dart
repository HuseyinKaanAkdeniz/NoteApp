import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:noteapplication/Model/ScheduleNotification.dart';
import 'package:noteapplication/View/permission_management_page.dart';

class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({super.key});

  @override
  State<NotificationManagementPage> createState() => _NotificationManagementPageState();
}

class _NotificationManagementPageState extends State<NotificationManagementPage> {
  List<PendingNotificationRequest> pendingNotifications = [];

  @override
  void initState() {
    super.initState();
    loadPendingNotifications();
  }

  Future<void> loadPendingNotifications() async {
    final notifications = await getPendingNotifications();
    // Check if widget is still mounted before updating state
    if (!mounted) return;
    setState(() {
      pendingNotifications = notifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
             appBar: AppBar(
         title: const Text('Bildirim Yönetimi', style: TextStyle(color: Colors.white)),
         backgroundColor: Colors.transparent,
         elevation: 0,
         actions: [
           IconButton(
             onPressed: () {
               Navigator.of(context).push(
                 MaterialPageRoute(
                   builder: (context) => const PermissionManagementPage(),
                 ),
               );
             },
             icon: const Icon(Icons.security, color: Colors.white70),
             tooltip: 'İzin Yönetimi',
           ),
         ],
       ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bildirim Testleri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
                         // Test bildirimi butonu
             ElevatedButton.icon(
               onPressed: () async {
                 final success = await safeNotificationOperation(() async {
                   await showTestNotification();
                 }, context);
                 
                 if (success && mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text('Test bildirimi gönderildi'),
                       backgroundColor: Colors.green,
                     ),
                   );
                 }
               },
              icon: const Icon(Icons.notification_add),
              label: const Text('Test Bildirimi Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Hızlı bildirim butonları
            Row(
              children: [
                Expanded(
                                     child: ElevatedButton.icon(
                     onPressed: () async {
                       final success = await safeNotificationOperation(() async {
                         await scheduleOnceNotification(
                           const TimeOfDay(hour: 14, minute: 30),
                           'Test Notu',
                         );
                       }, context);
                       
                       if (success && mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Yarın 14:30\'da bildirim ayarlandı'),
                             backgroundColor: Colors.green,
                           ),
                         );
                         loadPendingNotifications();
                       }
                     },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Yarın 14:30'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                                     child: ElevatedButton.icon(
                     onPressed: () async {
                       final success = await safeNotificationOperation(() async {
                         await scheduleDailyNotification(
                           const TimeOfDay(hour: 9, minute: 0),
                           'Günlük Hatırlatma',
                         );
                       }, context);
                       
                       if (success && mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Her gün 09:00\'da bildirim ayarlandı'),
                             backgroundColor: Colors.green,
                           ),
                         );
                         loadPendingNotifications();
                       }
                     },
                    icon: const Icon(Icons.repeat),
                    label: const Text('Her gün 09:00'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Bekleyen bildirimler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bekleyen Bildirimler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton.icon(
                  onPressed: loadPendingNotifications,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  label: const Text('Yenile', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Expanded(
              child: pendingNotifications.isEmpty
                  ? const Center(
                      child: Text(
                        'Bekleyen bildirim yok',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: pendingNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = pendingNotifications[index];
                        return Card(
                          color: Colors.blueGrey.shade800,
                          child: ListTile(
                                                         leading: const Icon(Icons.notifications, color: Colors.orange),
                            title: Text(
                              notification.title ?? 'Bilinmeyen',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'ID: ${notification.id}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await cancelNotification(notification.id);
                                loadPendingNotifications();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bildirim iptal edildi'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // Tüm bildirimleri iptal et
            ElevatedButton.icon(
              onPressed: () async {
                await cancelAllNotifications();
                loadPendingNotifications();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tüm bildirimler iptal edildi'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Tüm Bildirimleri İptal Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
