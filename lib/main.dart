import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Import wajib untuk bahasa
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- TAMBAHAN: Import FCM
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chupatu_mobile/pages/welcome_page.dart';
import 'package:chupatu_mobile/config/firebase_options.dart';
import 'package:chupatu_mobile/pages/auth/landing_page.dart';
import 'package:chupatu_mobile/pages/main_page.dart';
import 'package:chupatu_mobile/pages/admin/dashboard/admin_home_page.dart';
import 'package:chupatu_mobile/services/notification_service.dart'; // Import NotificationService

// ============================================================
// KONFIGURASI BAHASA (LANGUAGE CONFIG)
// ============================================================
class LanguageConfig {
  // Default bahasa Indonesia
  static final ValueNotifier<Locale> currentLocale =
      ValueNotifier(const Locale('id', 'ID'));

  static void changeLanguage(String langCode) {
    if (langCode == 'id') {
      currentLocale.value = const Locale('id', 'ID');
    } else {
      currentLocale.value = const Locale('en', 'US');
    }
  }
}

// ============================================================
// 1. KONFIGURASI TEMA (THEME CONFIG)
// ============================================================

class AppThemeData {
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textMain;
  final bool isDark;

  AppThemeData({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textMain,
    required this.isDark,
  });
}

class ThemeConfig {
  static final List<AppThemeData> themes = [
    // 1. Default Cyan (Satu-satunya tema)
    AppThemeData(
      name: 'Cyan',
      primary: const Color(0xFF22D3EE), // Warna utama sesuai permintaanmu
      secondary: const Color(
          0xFF06B6D4), // Cyan yang sedikit lebih gelap untuk variasi
      background: const Color(
          0xFFECFEFF), // Putih kebiruan sangat muda untuk background
      surface: Colors.white,
      textMain: const Color(
          0xFF083344), // Biru gelap (hampir hitam) agar teks mudah dibaca
      isDark: false,
    ),
  ];

  static final ValueNotifier<AppThemeData> currentTheme =
      ValueNotifier(themes[0]);

  static void changeTheme(int index) {
    if (index >= 0 && index < themes.length) {
      currentTheme.value = themes[index];
    }
  }
}

// ============================================================
// 2. MAIN FUNCTION, BACKGROUND HANDLER & LOCAL NOTIFICATIONS
// ============================================================

// --- TAMBAHAN: PENJAGA NOTIF SAAT APLIKASI DITUTUP ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase jalan di background
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Notif masuk pas app ditutup: ${message.messageId}");
}

// OPTIMASI: Fungsi inisialisasi berat dipisah agar tidak memblokir render pertama UI.
// Akan dipanggil dari WelcomePage secara asynchronous selagi animasi berjalan.
Future<void> initAppServices() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // --- TAMBAHAN: Daftarin penjaga notif background ---
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // --- TAMBAHAN: Inisialisasi Notification Service ---
    final notificationService = NotificationService();
    await notificationService.init();

    // Atur opsi presentasi notifikasi saat aplikasi di foreground
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Dengerin notifikasi saat aplikasi lagi kebuka (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        notificationService.showNotification(
          id: notification.hashCode,
          title: notification.title ?? 'Notifikasi Baru',
          body: notification.body ?? '',
        );
      }
    });
  } catch (e) {
    debugPrint("Init Error: $e");
  }
}

void main() {
  // OPTIMASI: Jangan await fungsi berat di sini, agar Flutter langsung
  // me-render UI secepat kilat (mengurangi blank screen/lag di hp spek rendah).
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChupatuApp());
}

class ChupatuApp extends StatelessWidget {
  const ChupatuApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 1. LISTENER UNTUK BAHASA (BARU) ---
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageConfig.currentLocale,
      builder: (context, currentLocale, child) {
        // --- 2. LISTENER UNTUK TEMA (BAWAAN BOS) ---
        return ValueListenableBuilder<AppThemeData>(
          valueListenable: ThemeConfig.currentTheme,
          builder: (context, themeData, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Chupatu Mobile',

              // --- SETTING BAHASA BERFUNGSI DISINI ---
              locale: currentLocale,
              supportedLocales: const [
                Locale('id', 'ID'), // Indonesia
                Locale('en', 'US'), // Inggris
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // ----------------------------------------

              theme: ThemeData(
                useMaterial3: true,
                brightness:
                    themeData.isDark ? Brightness.dark : Brightness.light,
                scaffoldBackgroundColor: themeData.background,
                primaryColor: themeData.primary,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: themeData.primary,
                  brightness:
                      themeData.isDark ? Brightness.dark : Brightness.light,
                  primary: themeData.primary,
                  secondary: themeData.secondary,
                  surface: themeData.surface,
                ),
                textTheme: TextTheme(
                  bodyMedium: TextStyle(color: themeData.textMain),
                  titleLarge: TextStyle(color: themeData.textMain),
                ),
                appBarTheme: AppBarTheme(
                  backgroundColor: themeData.surface,
                  surfaceTintColor: Colors.transparent,
                  titleTextStyle: TextStyle(
                      color: themeData.textMain,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  iconTheme: IconThemeData(color: themeData.textMain),
                ),
                cardTheme: CardThemeData(
                  color: themeData.surface,
                  surfaceTintColor: Colors.transparent,
                ),
              ),

              // --- LOGIC AUTH WRAPPER ---
              home: const WelcomePage(),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// 3. AUTH WRAPPER (Pengatur Lalu Lintas Login)
// ============================================================

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor:
                Color(0xFFFAFAFA), // Atau sesuaikan warna background lo
            body: SizedBox(),
          );
        }

        if (!snapshot.hasData) {
          return const LandingPage();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              String role = userSnapshot.data!.get('role') ?? 'user';

              if (role == 'admin') {
                return const AdminHomePage();
              } else {
                return const MainPage();
              }
            }

            return const LandingPage();
          },
        );
      },
    );
  }
}
