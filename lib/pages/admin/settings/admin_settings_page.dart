import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/admin/widgets/admin_glass_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return AdminGlassScaffold(
            appBar: AppBar(
              title: Text("Pengaturan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black87)),
              backgroundColor: Colors.white.withOpacity(0.5),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              flexibleSpace: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SECTION PROFIL ADMIN (DATA ASLI)
                  Text("Profil Admin", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 12),
                  GlassCard(
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
                              Text(adminName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
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

                  // 2. SECTION TEMA APLIKASI
                  Text("Tampilan Aplikasi", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Pilih Tema Warna", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: ThemeConfig.themes.asMap().entries.map((entry) {
                            int index = entry.key;
                            AppThemeData item = entry.value;
                            bool isSelected = theme.name == item.name;

                            return GestureDetector(
                              onTap: () => ThemeConfig.changeTheme(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  color: item.primary,
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                  boxShadow: [BoxShadow(color: item.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 3. SECTION PENGATURAN LAIN
                  Text("Sistem & Keamanan", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsItem(Icons.lock_outline, "Ganti Password", () => _showChangePasswordDialog(context, theme)),
                        const Divider(height: 1),
                        _buildSettingsItem(Icons.print_outlined, "Setting Printer Struk (Bluetooth)", () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Printer akan aktif saat integrasi Thermal Printer")));
                        }),
                        const Divider(height: 1),
                        _buildSettingsItem(Icons.info_outline, "Tentang Aplikasi (v1.0.0)", () {
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

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  // --- LOGIKA POP-UP EDIT PROFIL (UPDATE KE FIREBASE) ---
  void _showEditProfileDialog(BuildContext context, AppThemeData theme) {
    TextEditingController nameController = TextEditingController(text: adminName);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Edit Profil", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Nama Admin", border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                // UPDATE KE FIREBASE
                if (user != null && nameController.text.isNotEmpty) {
                  await user!.updateDisplayName(nameController.text);
                  await user!.reload(); // Refresh data user

                  // Update Tampilan Lokal
                  setState(() {
                    adminName = nameController.text;
                    // Jika perlu update user object lagi
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
      ),
    );
  }

  // --- LOGIKA POP-UP GANTI PASSWORD ---
  void _showChangePasswordDialog(BuildContext context, AppThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Ganti Password", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text("Untuk keamanan, silakan cek email Anda untuk link reset password."),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
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
      ),
    );
  }
}