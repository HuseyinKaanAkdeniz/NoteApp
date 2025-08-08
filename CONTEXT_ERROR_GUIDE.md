# Flutter Context Error Prevention Guide

Bu rehber, Flutter'da sık karşılaşılan "Looking up a deactivated widget's ancestor is unsafe" hatasını önlemek için oluşturulmuştur.

## Hata Nedir?

Bu hata, bir widget'ın dispose edildikten sonra context'e erişmeye çalıştığınızda ortaya çıkar. Genellikle async işlemler sırasında widget'ın dispose edilmesi durumunda oluşur.

## Hata Mesajı
```
bool _debugCheckStateIsActiveForAncestorLookup() {
  throw FlutterError.fromParts(<DiagnosticsNode>[
    ErrorSummary("Looking up a deactivated widget's ancestor is unsafe."),
    ErrorDescription("At this point the state of the widget's element tree is no longer stable."),
    ErrorHint("To safely refer to a widget's ancestor in its dispose() method..."),
  ]);
}
```

## Çözümler

### 1. Context Mounted Kontrolü

Her async işlemden önce ve sonra context'in hala aktif olup olmadığını kontrol edin:

```dart
// ❌ Yanlış Kullanım
Future<void> someAsyncOperation() async {
  await someApiCall();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Success')));
}

// ✅ Doğru Kullanım
Future<void> someAsyncOperation() async {
  await someApiCall();
  if (mounted) { // Widget hala aktif mi?
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Success')));
  }
}
```

### 2. ContextUtils Kullanımı

Projede oluşturulan `ContextUtils` sınıfını kullanın:

```dart
import 'package:noteapplication/Model/context_utils.dart';

// Güvenli SnackBar gösterimi
ContextUtils.showSnackBar(context, SnackBar(content: Text('Success')));

// Güvenli navigasyon
ContextUtils.navigateTo(context, SomePage());

// Güvenli async işlem
final result = await ContextUtils.safeAsyncOperation(
  context: context,
  operation: () async {
    // Async işlemleriniz
    return someResult;
  },
  onContextUnmounted: () => null,
);
```

### 3. SafeContext Extension

BuildContext'e eklenen extension metodlarını kullanın:

```dart
// Güvenli SnackBar
context.showSnackBar(SnackBar(content: Text('Success')));

// Güvenli navigasyon
context.navigateTo(SomePage());

// Güvenli dialog
final result = await context.showSafeDialog(
  builder: (context) => AlertDialog(title: Text('Dialog')),
);
```

## Yaygın Hata Senaryoları

### 1. Async İşlemler Sonrası Context Kullanımı

```dart
// ❌ Yanlış
onPressed: () async {
  await someApiCall();
  Navigator.of(context).pop(); // Hata!
}

// ✅ Doğru
onPressed: () async {
  await someApiCall();
  if (mounted) {
    Navigator.of(context).pop();
  }
}
```

### 2. setState Sonrası Context Kullanımı

```dart
// ❌ Yanlış
Future<void> loadData() async {
  final data = await fetchData();
  setState(() {
    this.data = data;
  });
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded')));
}

// ✅ Doğru
Future<void> loadData() async {
  final data = await fetchData();
  if (!mounted) return;
  setState(() {
    this.data = data;
  });
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded')));
  }
}
```

### 3. Timer veya Stream Kullanımı

```dart
// ❌ Yanlış
Timer.periodic(Duration(seconds: 1), (timer) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Timer')));
});

// ✅ Doğru
Timer.periodic(Duration(seconds: 1), (timer) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Timer')));
  }
});
```

## Bildirim Sistemi İçin Özel Çözümler

### 1. safeNotificationOperation Kullanımı

```dart
// Güvenli bildirim işlemleri
final success = await safeNotificationOperation(() async {
  await showTestNotification();
}, context);
```

### 2. Permission Kontrolü

```dart
// Güvenli izin kontrolü
final hasPermission = await ensureNotificationPermission(context);
```

## Best Practices

### 1. Her Zaman Mounted Kontrolü

```dart
// Her async işlemden önce
if (!mounted) return;

// Her context kullanımından önce
if (mounted) {
  // Context kullanımı
}
```

### 2. Dispose Metodunda Dikkat

```dart
@override
void dispose() {
  // Timer'ları iptal et
  _timer?.cancel();
  // Stream subscription'ları iptal et
  _subscription?.cancel();
  super.dispose();
}
```

### 3. ContextUtils Kullanımı

```dart
// ContextUtils metodlarını tercih edin
ContextUtils.showSnackBar(context, snackBar);
ContextUtils.navigateTo(context, page);
ContextUtils.safeAsyncOperation(context, operation);
```

## Debug İpuçları

### 1. Hata Lokasyonunu Bulma

Hata mesajında stack trace'i takip ederek hangi satırda hata oluştuğunu bulun.

### 2. Widget Lifecycle Kontrolü

```dart
@override
void initState() {
  super.initState();
  print('Widget initialized');
}

@override
void dispose() {
  print('Widget disposed');
  super.dispose();
}
```

### 3. Context Durumu Kontrolü

```dart
print('Context mounted: ${context.mounted}');
print('Widget mounted: $mounted');
```

## Özet

1. **Her zaman `mounted` kontrolü yapın**
2. **ContextUtils sınıfını kullanın**
3. **Async işlemlerden sonra context kontrolü yapın**
4. **Dispose metodunda kaynakları temizleyin**
5. **Timer ve Stream'leri düzgün iptal edin**

Bu kuralları takip ederek context hatalarını önleyebilirsiniz.
