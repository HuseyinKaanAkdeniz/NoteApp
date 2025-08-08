# Flutter Notification Guide

Bu rehber, Flutter uygulamanızda bildirimlerin nasıl kullanılacağını açıklar.

## Kurulum

Gerekli paketler `pubspec.yaml` dosyasında zaten mevcut:
- `flutter_local_notifications: ^19.4.0`
- `timezone: ^0.10.1`

## Kullanım

### 1. Bildirim Yönetimi Sayfası

Ana sayfada sağ üst köşedeki bildirim ikonuna tıklayarak bildirim yönetimi sayfasına erişebilirsiniz.

### 2. Test Bildirimi

- "Test Bildirimi Gönder" butonuna tıklayarak anında test bildirimi gönderebilirsiniz
- Bu, bildirim sisteminin çalışıp çalışmadığını kontrol etmek için kullanılır

### 3. Hızlı Bildirimler

- **Yarın 14:30**: Yarın saat 14:30'da tek seferlik bildirim ayarlar
- **Her gün 09:00**: Her gün saat 09:00'da tekrarlayan bildirim ayarlar

### 4. Not Detay Sayfasında Bildirim

Herhangi bir notun detay sayfasında:
1. Sağ alt köşedeki bildirim ikonuna tıklayın
2. Zaman seçin
3. Tek seferlik veya günlük tekrar seçin
4. "Onayla" butonuna tıklayın

### 5. Bekleyen Bildirimleri Yönetme

Bildirim yönetimi sayfasında:
- Bekleyen tüm bildirimleri görebilirsiniz
- Her bildirimi tek tek iptal edebilirsiniz
- "Tüm Bildirimleri İptal Et" ile hepsini silebilirsiniz

## Bildirim Türleri

### 1. Anında Bildirim
```dart
await showTestNotification();
```

### 2. Tek Seferlik Bildirim
```dart
await scheduleOnceNotification(TimeOfDay(hour: 14, minute: 30), "Not Başlığı");
```

### 3. Günlük Tekrarlayan Bildirim
```dart
await scheduleDailyNotification(TimeOfDay(hour: 9, minute: 0), "Not Başlığı");
```

### 4. Belirli Tarih Bildirimi
```dart
await scheduleSpecificDateNotification(DateTime(2024, 12, 25, 10, 30), "Not Başlığı");
```

## Bildirim Yönetimi

### Bildirim İptal Etme
```dart
// Belirli bir bildirimi iptal et
await cancelNotification(notificationId);

// Tüm bildirimleri iptal et
await cancelAllNotifications();
```

### Bekleyen Bildirimleri Listeleme
```dart
List<PendingNotificationRequest> notifications = await getPendingNotifications();
```

## Android İzinleri

`android/app/src/main/AndroidManifest.xml` dosyasında gerekli izinler mevcut:
- `RECEIVE_BOOT_COMPLETED`: Cihaz yeniden başlatıldığında bildirimleri yeniden ayarlar
- `SCHEDULE_EXACT_ALARM`: Tam zamanlı bildirimler için

## İzin Yönetimi

### Bildirim İzinlerini Kontrol Etme
1. Bildirim yönetimi sayfasında sağ üst köşedeki güvenlik ikonuna tıklayın
2. Mevcut izin durumunu görüntüleyin
3. Gerekirse izin isteyin

### İzin Durumları
- **İzin Verildi**: Bildirimler normal çalışır
- **İzin Reddedildi**: İzin isteyebilirsiniz
- **Kalıcı Olarak Reddedildi**: Cihaz ayarlarından manuel olarak etkinleştirmeniz gerekir
- **Kısıtlandı**: Cihaz ayarlarını kontrol edin

### İzin İsteme
```dart
// Manuel izin isteme
final status = await NotificationPermissionManager.requestPermission();

// Otomatik izin kontrolü ve isteme
final hasPermission = await ensureNotificationPermission(context);
```

## Sorun Giderme

### Bildirimler Gelmiyor
1. **İzin Kontrolü**: Bildirim yönetimi sayfasından izin durumunu kontrol edin
2. **Cihaz Ayarları**: Cihaz ayarlarından uygulama bildirimlerinin açık olduğundan emin olun
3. **Test Bildirimi**: Test bildirimi göndererek sistemin çalışıp çalışmadığını kontrol edin
4. **Rahatsız Etme Modu**: Cihazın "Rahatsız Etme" modunda olmadığından emin olun

### Bildirimler Yanlış Zamanda Geliyor
- Zaman dilimi ayarlarını kontrol edin
- Cihazın saat ayarlarının doğru olduğundan emin olun

### İzin Hataları
- **Kalıcı Red**: Cihaz ayarlarından manuel olarak etkinleştirin
- **Kısıtlama**: Cihaz güvenlik ayarlarını kontrol edin
- **Bilinmeyen Durum**: Uygulamayı yeniden başlatın

## Özelleştirme

### Bildirim İçeriğini Değiştirme
`lib/Model/ScheduleNotification.dart` dosyasındaki fonksiyonları düzenleyerek:
- Bildirim başlığını değiştirebilirsiniz
- Bildirim mesajını değiştirebilirsiniz
- Bildirim sesini değiştirebilirsiniz
- Bildirim ikonunu değiştirebilirsiniz

### Yeni Bildirim Türleri Ekleme
Aynı dosyaya yeni fonksiyonlar ekleyerek farklı bildirim türleri oluşturabilirsiniz.

## Notlar

- Bildirimler cihaz yeniden başlatıldığında kaybolabilir
- Bazı cihazlarda pil optimizasyonu bildirimleri etkileyebilir
- Android 13+ cihazlarda bildirim izinleri ayrıca verilmelidir
