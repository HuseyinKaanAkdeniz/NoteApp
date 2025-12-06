import 'package:flutter/material.dart';
import 'package:noteapplication/Model/ScheduleNotification.dart';

class PermissionManagementPage extends StatefulWidget {
  const PermissionManagementPage({super.key});

  @override
  State<PermissionManagementPage> createState() => _PermissionManagementPageState();
}

class _PermissionManagementPageState extends State<PermissionManagementPage> {
  NotificationPermissionStatus currentStatus = NotificationPermissionStatus.unknown;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkPermissionStatus();
  }

  Future<void> checkPermissionStatus() async {
    setState(() {
      isLoading = true;
    });

    final status = await NotificationPermissionManager.checkPermission();
    
    // Check if widget is still mounted before updating state
    if (!mounted) return;
    
    setState(() {
      currentStatus = status;
      isLoading = false;
    });
  }

  Future<void> requestPermission() async {
    setState(() {
      isLoading = true;
    });

    final status = await NotificationPermissionManager.requestPermission();
    
    // Check if widget is still mounted before updating state
    if (!mounted) return;
    
    setState(() {
      currentStatus = status;
      isLoading = false;
    });

    // Check if widget is still mounted before showing SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(NotificationPermissionManager.getPermissionStatusMessage(status)),
          backgroundColor: status == NotificationPermissionStatus.granted 
              ? Colors.green 
              : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim İzinleri', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: checkPermissionStatus,
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                color: Colors.blueGrey.shade800,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(currentStatus),
                            color: _getStatusColor(currentStatus),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mevcut Durum',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  _getStatusText(currentStatus),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        NotificationPermissionManager.getPermissionStatusMessage(currentStatus),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        
              const SizedBox(height: 24),
        
              // Action Buttons
              if (currentStatus != NotificationPermissionStatus.granted) ...[
                const Text(
                  'İzin İşlemleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                ElevatedButton.icon(
                  onPressed: isLoading ? null : requestPermission,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Bildirim İzni İste'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
        
                const SizedBox(height: 12),
        
                if (currentStatus == NotificationPermissionStatus.permanentlyDenied)
                  ElevatedButton.icon(
                    onPressed: () {
                      _showSettingsInstructions();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Ayarları Aç'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
              ],
        
              const SizedBox(height: 24),
        
              // Information Section
              const Text(
                'Bildirim İzinleri Hakkında',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
        
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'Neden Bildirim İzni Gerekli?',
                content: 'Bildirimler, notlarınız için hatırlatıcılar ayarlamanıza ve önemli bilgileri kaçırmamanıza yardımcı olur.',
              ),
        
              const SizedBox(height: 12),
        
              _buildInfoCard(
                icon: Icons.security,
                title: 'Güvenlik',
                content: 'Bildirimler sadece sizin ayarladığınız zamanlarda gönderilir. Kişisel verileriniz güvende kalır.',
              ),
        
              const SizedBox(height: 12),
        
              _buildInfoCard(
                icon: Icons.settings,
                title: 'İzin Yönetimi',
                content: 'İzinleri istediğiniz zaman cihaz ayarlarından değiştirebilir veya iptal edebilirsiniz.',
              ),
        
              const SizedBox(height: 24),
        
              // Troubleshooting Section
              const Text(
                'Sorun Giderme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
        
              _buildTroubleshootingItem(
                'Bildirimler gelmiyor',
                'Cihaz ayarlarından uygulama bildirimlerinin açık olduğundan emin olun.',
              ),
        
              _buildTroubleshootingItem(
                'İzin verildi ama bildirim yok',
                'Cihazın "Rahatsız Etme" modunda olmadığından emin olun.',
              ),
        
              _buildTroubleshootingItem(
                'Bildirimler yanlış zamanda geliyor',
                'Cihazın saat ayarlarının doğru olduğundan emin olun.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      color: Colors.blueGrey.shade700,
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingItem(String title, String solution) {
    return Card(
      color: Colors.blueGrey.shade700,
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              solution,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return Icons.check_circle;
      case NotificationPermissionStatus.denied:
        return Icons.cancel;
      case NotificationPermissionStatus.permanentlyDenied:
        return Icons.block;
      case NotificationPermissionStatus.restricted:
        return Icons.warning;
      case NotificationPermissionStatus.unknown:
        return Icons.help;
    }
  }

  Color _getStatusColor(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return Colors.green;
      case NotificationPermissionStatus.denied:
        return Colors.orange;
      case NotificationPermissionStatus.permanentlyDenied:
        return Colors.red;
      case NotificationPermissionStatus.restricted:
        return Colors.yellow;
      case NotificationPermissionStatus.unknown:
        return Colors.grey;
    }
  }

  String _getStatusText(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return 'İzin Verildi';
      case NotificationPermissionStatus.denied:
        return 'İzin Reddedildi';
      case NotificationPermissionStatus.permanentlyDenied:
        return 'Kalıcı Olarak Reddedildi';
      case NotificationPermissionStatus.restricted:
        return 'Kısıtlandı';
      case NotificationPermissionStatus.unknown:
        return 'Bilinmiyor';
    }
  }

  void _showSettingsInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayarları Aç'),
        content: const Text(
          'Bildirim izinlerini etkinleştirmek için:\n\n'
          '1. Cihaz Ayarları > Uygulamalar\n'
          '2. Bu uygulamayı bulun\n'
          '3. İzinler > Bildirimler\n'
          '4. Bildirimleri etkinleştirin',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
