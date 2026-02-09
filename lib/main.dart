import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// --- IMPORT DARI STRUKTUR BARU (Sesuai Gambar) ---
import 'package:chupatu_mobile/config/firebase_options.dart';
import 'package:chupatu_mobile/pages/auth/landing_page.dart';
// Jika nanti butuh import halaman lain, uncomment di bawah:
// import 'package:chupatu_mobile/pages/home/home_page.dart';
// import 'package:chupatu_mobile/pages/auth/login_page.dart';

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
    // 2. Midnight Dark
    AppThemeData(
      name: 'Midnight Dark',
      primary: const Color(0xFF4F46E5),
      secondary: const Color(0xFF00D4FF),
      background: const Color(0xFF0F172A),
      surface: const Color(0xFF1E293B),
      textMain: Colors.white,
      isDark: true,
    ),
    // 3. Gold Luxury
    AppThemeData(
      name: 'Gold Luxury',
      primary: const Color(0xFFD4AF37),
      secondary: const Color(0xFFF4E08F),
      background: const Color(0xFF121212),
      surface: const Color(0xFF2C2C2C),
      textMain: const Color(0xFFFFD700),
      isDark: true,
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
  ];

  // SAKLAR TEMA GLOBAL
  static final ValueNotifier<AppThemeData> currentTheme = ValueNotifier(themes[0]);

  static void changeTheme(int index) {
    currentTheme.value = themes[index];
  }
}

// ============================================================
// 2. MAIN FUNCTION
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ChupatuApp());
}

class ChupatuApp extends StatelessWidget {
  const ChupatuApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Membungkus dengan ValueListenableBuilder agar aplikasi rebuild saat tema ganti
    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, themeData, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Chupatu Mobile',
          
          // Konfigurasi Tema Dinamis
          theme: ThemeData(
            useMaterial3: true,
            brightness: themeData.isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: themeData.background,
            primaryColor: themeData.primary,
            
            // Color Scheme modern
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeData.primary,
              brightness: themeData.isDark ? Brightness.dark : Brightness.light,
              primary: themeData.primary,
              secondary: themeData.secondary,
              surface: themeData.surface,
            ),
            
            // Warna teks default
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: themeData.textMain),
              titleLarge: TextStyle(color: themeData.textMain),
            ),
            
            // Tema AppBar
            appBarTheme: AppBarTheme(
              backgroundColor: themeData.surface,
              surfaceTintColor: Colors.transparent, 
              titleTextStyle: TextStyle(color: themeData.textMain, fontSize: 20, fontWeight: FontWeight.bold),
              iconTheme: IconThemeData(color: themeData.textMain),
            ),
            
            // Tema Card
            cardTheme: CardThemeData(
              color: themeData.surface,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          
          // Arahkan ke Landing Page (Halaman Awal)
          home: const LandingPage(),
        );
      },
    );
  }
}