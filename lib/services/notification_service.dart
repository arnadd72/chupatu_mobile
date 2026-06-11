import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Buat instance singleton agar tidak terduplikasi
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// FASE 1: Inisialisasi (Dipanggil sekali di fungsi main() saat aplikasi hidup)
  Future<void> init() async {
    // Tentukan icon notifikasi bawaan Android (biasanya @mipmap/ic_launcher)
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // (Opsional) Jika ada iOS, tambahkan DarwinInitializationSettings di sini
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    // Lakukan inisialisasi menggunakan named parameter `settings:`
    await _plugin.initialize(
      initSettings,
      // Jika ingin mendeteksi klik notifikasi untuk berpindah halaman
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle klik notifikasi di sini jika diperlukan
      },
    );
  }

  /// FASE 2: Meminta Izin (Dipanggil di layar awal atau saat user pertama kali menekan tombol)
  Future<void> requestPermission() async {
    // Hanya berjalan di Android 13 (API 33) ke atas
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// FASE 3: Menampilkan Notifikasi Pop-up (Bisa dipanggil kapanpun)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Konfigurasi "Channel" khusus Android (Wajib ada di Android 8.0+)
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'main_channel_id',           // ID channel unik aplikasi
      'Main Notifications',        // Nama channel (terlihat di setting HP user)
      channelDescription: 'Notifikasi utama aplikasi',
      importance: Importance.max,  // .max agar muncul Pop-up (Heads-up)
      priority: Priority.high,     // .high agar notif ada di urutan teratas
      ticker: 'ticker',
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Tampilkan notifikasinya
    await _plugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}
