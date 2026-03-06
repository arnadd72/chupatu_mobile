import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Import wajib untuk bahasa
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- TAMBAHAN: Import FCM

import 'package:chupatu_mobile/pages/welcome_page.dart';
import 'package:chupatu_mobile/config/firebase_options.dart';
import 'package:chupatu_mobile/pages/auth/landing_page.dart';
import 'package:chupatu_mobile/pages/main_page.dart';
import 'package:chupatu_mobile/pages/admin/dashboard/admin_home_page.dart';

// ============================================================
// KONFIGURASI BAHASA (LANGUAGE CONFIG)
// ============================================================
class LanguageConfig {
  // Default bahasa Indonesia
  static final ValueNotifier<Locale> currentLocale = ValueNotifier(const Locale('id', 'ID'));

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
    // 1. Default Blue
    AppThemeData(
      name: 'Default Blue',
      primary: const Color(0xFF0606F9),
      secondary: const Color(0xFF00D4FF),
      background: const Color(0xFFF8F9FD),
      surface: Colors.white,
      textMain: const Color(0xFF0B0F19),
      isDark: false,
    ),
    // 3. Gold Luxury
    AppThemeData(
      name: 'Gold Luxury',
      primary: const Color(0xFFD4AF37), // Emas Premium
      secondary: const Color(0xFFE5C05C), // Emas Terang (Biar nyala)
      background: const Color(0xFFFDFBF7), // Putih Tulang / Krem sangat halus
      surface: const Color(0xFFFFFFFF), // Putih Bersih (Snow)
      textMain: const Color(0xFF1A1A24),
      isDark: false,
    ),
    // 4. Nature Green
    AppThemeData(
      name: 'Nature Fresh',
      primary: const Color(0xFF10B981),
      secondary: const Color(0xFF34D399),
      background: const Color(0xFFECFDF5),
      surface: Colors.white,
      textMain: const Color(0xFF064E3B),
      isDark: false,
    ),

    // --- TEMA BARU DITAMBAHKAN ---

    // 5. Neumorphism (Soft Grey, Low Contrast)
    AppThemeData(
      name: 'Neumorphism',
      primary: const Color(0xFF55677d),
      secondary: const Color(0xFF7b8fa1),
      background: const Color(0xFFE0E5EC),
      surface: const Color(0xFFE0E5EC),
      textMain: const Color(0xFF4A5568),
      isDark: false,
    ),

    // 6. Glassmorphism (Deep Purple, Blur Base)
    AppThemeData(
      name: 'Glassmorphism',
      primary: const Color(0xFFD946EF),
      secondary: const Color(0xFF8B5CF6),
      background: const Color(0xFF2D1B69),
      surface: const Color(0xFF442A8B),
      textMain: Colors.white,
      isDark: true,
    ),

    // 7. Immersive 3D (Neon Green, True Black)
    AppThemeData(
      name: 'Immersive 3D',
      primary: const Color(0xFF00FF94),
      secondary: const Color(0xFF00B8D4),
      background: const Color(0xFF000000),
      surface: const Color(0xFF111111),
      textMain: const Color(0xFFEEEEEE),
      isDark: true,
    ),

    // 8. Retro (Paper/Cream, Vintage Orange)
    AppThemeData(
      name: 'Retro Style',
      primary: const Color(0xFFFF6B6B),
      secondary: const Color(0xFFE17055),
      background: const Color(0xFFF7F1E3),
      surface: const Color(0xFFFFEAA7),
      textMain: const Color(0xFF2D3436),
      isDark: false,
    ),

    // 9. Dark Modern (Sleek Grey, Electric Blue)
    AppThemeData(
      name: 'Dark Modern',
      primary: const Color(0xFF2979FF),
      secondary: const Color(0xFF00E5FF),
      background: const Color(0xFF181818),
      surface: const Color(0xFF252525),
      textMain: Colors.white,
      isDark: true,
    ),
  ];

  static final ValueNotifier<AppThemeData> currentTheme = ValueNotifier(themes[0]);

  static void changeTheme(int index) {
    if (index >= 0 && index < themes.length) {
      currentTheme.value = themes[index];
    }
  }
}

// ============================================================
// 2. MAIN FUNCTION & BACKGROUND HANDLER
// ============================================================

// --- TAMBAHAN: PENJAGA NOTIF SAAT APLIKASI DITUTUP ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase jalan di background
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Notif masuk pas app ditutup: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- TAMBAHAN: Daftarin penjaga notif background ---
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
                brightness: themeData.isDark ? Brightness.dark : Brightness.light,
                scaffoldBackgroundColor: themeData.background,
                primaryColor: themeData.primary,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: themeData.primary,
                  brightness: themeData.isDark ? Brightness.dark : Brightness.light,
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
                  titleTextStyle: TextStyle(color: themeData.textMain, fontSize: 20, fontWeight: FontWeight.bold),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) {
          return const LandingPage();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
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