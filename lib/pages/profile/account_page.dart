import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/auth/login_page.dart';
import 'package:chupatu_mobile/pages/profile/profile_page.dart';
import 'package:chupatu_mobile/pages/profile/address_list_page.dart';
import 'package:chupatu_mobile/pages/profile/account_sub_pages.dart'; // Pastikan file ini ada!

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // --- FUNGSI LOGOUT ---
  Future<void> _signOut(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Keluar Akun?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin keluar dan ganti akun?", style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal")
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup Dialog

              try {
                // 1. Logout Firebase
                await FirebaseAuth.instance.signOut();

                // 2. Logout Google (PENTING)
                await GoogleSignIn().signOut();

                // 3. Pindah ke Login
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Gagal logout: $e")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              backgroundColor: theme.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text("Pengaturan Akun", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // --- SECTION 1: PROFIL & ALAMAT ---
                  _buildSectionContainer(theme, [
                    _buildSettingTile(Icons.person_outline_rounded, "Ubah Profil", "Atur identitas dan biodata diri kamu", theme, onTap: () {
                      // HAPUS CONST DISINI BIAR AMAN
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
                    }),
                    _buildDivider(),
                    _buildSettingTile(Icons.storefront_outlined, "Daftar Alamat", "Atur alamat penjemputan layanan sepatu", theme, onTap: () {
                      // HAPUS CONST DISINI BIAR AMAN
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddressListPage()));
                    }),
                  ]),

                  // --- SECTION 2: KEAMANAN & NOTIFIKASI ---
                  _buildSectionContainer(theme, [
                    _buildSettingTile(Icons.shield_outlined, "Keamanan Akun", "Kata sandi, PIN, & verifikasi data", theme, onTap: () {
                      // HAPUS CONST DISINI BIAR AMAN
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SecurityPage()));
                    }),
                    _buildDivider(),
                    _buildSettingTile(Icons.notifications_none_rounded, "Notifikasi", "Atur segala jenis pesan notifikasi", theme, onTap: () {
                      // === INI YANG TADI ERROR, SAYA SUDAH HAPUS 'const'-NYA ===
                      Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationSettingsPage()));
                    }),
                    _buildDivider(),
                    _buildSettingTile(Icons.phonelink_setup_rounded, "Pengaturan Aplikasi", "Tema gelap/terang, bahasa, dan cache", theme, onTap: () {
                      // HAPUS CONST DISINI BIAR AMAN
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AppSettingsPage()));
                    }),
                  ]),

                  // --- SECTION 3: TENTANG APLIKASI ---
                  _buildSectionContainer(theme, [
                    _buildSettingTile(Icons.info_outline_rounded, "Seputar Chupatu", "Syarat & ketentuan, kebijakan privasi, bantuan", theme, onTap: () {
                      // HAPUS CONST DISINI BIAR AMAN
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AboutPage()));
                    }),
                  ]),

                  const SizedBox(height: 20),

                  // --- TOMBOL LOGOUT ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _signOut(context),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: Text("Keluar Akun", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.redAccent),
                            foregroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text("Versi 1.2.1 (Beta)", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        }
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildSectionContainer(AppThemeData theme, List<Widget> children) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(children: children)
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, AppThemeData theme, {required VoidCallback onTap}) {
    return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: theme.primary, size: 24)
        ),
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textMain)),
        subtitle: Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 70, endIndent: 20, thickness: 0.5);
  }
}