import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chupatu_mobile/main.dart'; // Untuk ThemeConfig

// ==========================================
// 1. HALAMAN KEAMANAN AKUN (Ubah Password)
// ==========================================
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(title: Text("Keamanan Akun", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)), backgroundColor: theme.surface, elevation: 0, iconTheme: IconThemeData(color: theme.textMain)),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ubah Kata Sandi", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 8),
                  Text("Kami akan mengirimkan tautan (link) ke email Anda (${user?.email ?? '-'}) untuk mereset kata sandi dengan aman.", style: GoogleFonts.plusJakartaSans(color: Colors.grey, height: 1.5)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (user?.email != null) {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Email reset password telah dikirim!"), backgroundColor: Colors.green));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("Kirim Email Reset Sandi", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          );
        }
    );
  }
}

// ==========================================
// 2. HALAMAN NOTIFIKASI
// ==========================================
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}
class _NotificationPageState extends State<NotificationPage> {
  bool promoNotif = true;
  bool orderNotif = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(title: Text("Notifikasi", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)), backgroundColor: theme.surface, elevation: 0, iconTheme: IconThemeData(color: theme.textMain)),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SwitchListTile(
                  title: Text("Update Status Pesanan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                  subtitle: Text("Notifikasi saat sepatu dijemput, dicuci, dan selesai", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                  activeColor: theme.primary,
                  value: orderNotif,
                  onChanged: (val) => setState(() => orderNotif = val),
                ),
                const Divider(),
                SwitchListTile(
                  title: Text("Promo & Diskon", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                  subtitle: Text("Dapatkan info potongan harga terbaru", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                  activeColor: theme.primary,
                  value: promoNotif,
                  onChanged: (val) => setState(() => promoNotif = val),
                ),
              ],
            ),
          );
        }
    );
  }
}

// ==========================================
// 3. HALAMAN PENGATURAN APLIKASI (UBAH TEMA)
// ==========================================
class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, currentTheme, child) {
          return Scaffold(
            backgroundColor: currentTheme.background,
            appBar: AppBar(title: Text("Pengaturan Aplikasi", style: GoogleFonts.plusJakartaSans(color: currentTheme.textMain, fontWeight: FontWeight.bold)), backgroundColor: currentTheme.surface, elevation: 0, iconTheme: IconThemeData(color: currentTheme.textMain)),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text("Tema Tampilan (Color Theme)", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: currentTheme.textMain)),
                const SizedBox(height: 16),
                ...ThemeConfig.themes.asMap().entries.map((entry) {
                  int index = entry.key;
                  AppThemeData themeData = entry.value;
                  bool isSelected = currentTheme.name == themeData.name;

                  return GestureDetector(
                    onTap: () => ThemeConfig.changeTheme(index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: themeData.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? themeData.primary : Colors.grey.withOpacity(0.2), width: isSelected ? 2 : 1),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(width: 24, height: 24, decoration: BoxDecoration(color: themeData.primary, shape: BoxShape.circle)),
                              const SizedBox(width: 16),
                              Text(themeData.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: themeData.textMain, fontSize: 16)),
                            ],
                          ),
                          if (isSelected) Icon(Icons.check_circle_rounded, color: themeData.primary)
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }
    );
  }
}

// ==========================================
// 4. HALAMAN SEPUTAR CHUPATU
// ==========================================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(title: Text("Seputar Chupatu", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)), backgroundColor: theme.surface, elevation: 0, iconTheme: IconThemeData(color: theme.textMain)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dry_cleaning_rounded, size: 80, color: theme.primary),
                    const SizedBox(height: 16),
                    Text("Chupatu Mobile", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textMain)),
                    const SizedBox(height: 8),
                    Text("Layanan cuci sepatu terbaik, antar-jemput langsung ke depan pintu Anda.", textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: Colors.grey, height: 1.5)),
                    const SizedBox(height: 32),
                    OutlinedButton(onPressed: (){}, child: const Text("Syarat & Ketentuan")),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: (){}, child: const Text("Kebijakan Privasi")),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}