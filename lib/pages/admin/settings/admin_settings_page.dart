import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chupatu_mobile/main.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  // Variabel Data Admin
  late User? user;
  String adminName = "Admin";
  String adminEmail = "-";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    user = FirebaseAuth.instance.currentUser;
    setState(() {
      adminName = user?.displayName ?? "Admin";
      adminEmail = user?.email ?? "-";
    });
  }

  // Helper untuk menggantikan GlassCard menjadi Container Solid yang super ringan
  Widget _buildSolidCard({required Widget child, required AppThemeData theme, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          // PERUBAHAN: Ganti AdminGlassScaffold jadi Scaffold biasa
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text("Pengaturan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              backgroundColor: theme.surface, // Warna solid
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
              // PERUBAHAN: Hapus flexibleSpace kaca
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SECTION PROFIL ADMIN
                  Text("Profil Admin", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 12),
                  _buildSolidCard(
                    theme: theme,
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                              color: theme.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                              image: user?.photoURL != null ? DecorationImage(image: NetworkImage(user!.photoURL!), fit: BoxFit.cover) : null
                          ),
                          child: user?.photoURL == null ? Icon(Icons.person, size: 30, color: theme.primary) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(adminName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)),
                              Text(adminEmail, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showEditProfileDialog(context, theme),
                          icon: Icon(Icons.edit_rounded, color: theme.primary),
                          tooltip: "Edit Profil",
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 2. SECTION TEMA APLIKASI (Ubah jadi Switch Light/Dark saja)
                  Text("Tampilan Aplikasi", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 12),
                  _buildSolidCard(
                    theme: theme,
                    padding: EdgeInsets.zero,
                    child: SwitchListTile(
                      title: Text("Mode Gelap (Dark Mode)", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain)),
                      subtitle: Text("Gunakan tema gelap untuk kenyamanan mata", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                      value: theme.isDark,
                      activeColor: theme.primary,
                      secondary: Icon(theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: theme.primary),
                      onChanged: (bool isDark) {
                        if (isDark) {
                          ThemeConfig.changeTheme(7); // Dark Modern
                        } else {
                          ThemeConfig.changeTheme(0); // Default Blue
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 3. SECTION PENGATURAN LAIN
                  Text("Sistem & Keamanan", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 12),
                  _buildSolidCard(
                    theme: theme,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsItem(Icons.lock_outline, "Ganti Password", theme, () => _showChangePasswordDialog(context, theme)),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        _buildSettingsItem(Icons.print_outlined, "Setting Printer Struk (Bluetooth)", theme, () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Printer akan aktif saat integrasi Thermal Printer")));
                        }),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        _buildSettingsItem(Icons.info_outline, "Tentang Aplikasi (v1.0.0)", theme, () {
                          showAboutDialog(context: context, applicationName: "Chupatu Admin", applicationVersion: "1.0.0", applicationIcon: const Icon(Icons.local_laundry_service));
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, AppThemeData theme, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: theme.textMain)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  // --- LOGIKA POP-UP EDIT PROFIL ---
  void _showEditProfileDialog(BuildContext context, AppThemeData theme) {
    TextEditingController nameController = TextEditingController(text: adminName);
    showDialog(
      context: context,
      // PERUBAHAN: Hapus efek BackdropFilter blur kaca
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Profil", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: theme.textMain),
          decoration: InputDecoration(
            labelText: "Nama Admin",
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (user != null && nameController.text.isNotEmpty) {
                await user!.updateDisplayName(nameController.text);
                await user!.reload();

                setState(() {
                  adminName = nameController.text;
                  user = FirebaseAuth.instance.currentUser;
                });

                if(context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama Profil berhasil diupdate!")));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white),
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  // --- LOGIKA POP-UP GANTI PASSWORD ---
  void _showChangePasswordDialog(BuildContext context, AppThemeData theme) {
    showDialog(
      context: context,
      // PERUBAHAN: Hapus efek BackdropFilter blur kaca
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Ganti Password", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Untuk keamanan, silakan cek email Anda untuk link reset password.", style: TextStyle(color: theme.textMain)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if(user?.email != null) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                if(context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Link reset password dikirim ke ${user!.email}")));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white),
            child: const Text("Kirim Email"),
          )
        ],
      ),
    );
  }
}