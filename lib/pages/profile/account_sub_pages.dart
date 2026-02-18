import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';

// ==========================================
// 1. HALAMAN KEAMANAN AKUN (Password & PIN)
// ==========================================
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isPinEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  // Ambil status PIN dari Database
  Future<void> _loadSecuritySettings() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          _isPinEnabled = doc.data()?['isPinEnabled'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error load settings: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Pop-up buat PIN atau Masukkan PIN
  void _showPinDialog({required bool isCreating, bool isDisabling = false}) {
    String inputPin = "";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isCreating ? "Buat PIN Baru" : "Konfirmasi PIN",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isCreating ? "Masukkan 6 digit angka untuk keamanan." : "Masukkan PIN lama untuk menonaktifkan.",
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => inputPin = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (inputPin.length != 6) return;
              Navigator.pop(context);

              if (isCreating) {
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                  'securityPin': inputPin,
                  'isPinEnabled': true,
                });
                setState(() => _isPinEnabled = true);
              } else if (isDisabling) {
                final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
                if (doc.data()?['securityPin'] == inputPin) {
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'isPinEnabled': false});
                  setState(() => _isPinEnabled = false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN Salah!"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEmailVerified = user?.emailVerified ?? false;

    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            title: Text("Keamanan Akun", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)),
            backgroundColor: theme.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.textMain),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // --- VERIFIKASI DATA ---
              Text("Verifikasi Data", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(isEmailVerified ? Icons.verified : Icons.warning_amber_rounded,
                        color: isEmailVerified ? Colors.green : Colors.orange),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Status Akun", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                          Text(isEmailVerified ? "Email Terverifikasi" : "Email Belum Diverifikasi",
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (!isEmailVerified)
                      TextButton(
                        onPressed: () => user?.sendEmailVerification(),
                        child: const Text("Verifikasi Sekarang"),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- PASSWORD (VERSI PERBAIKAN) ---
              Text("Kata Sandi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              ListTile(
                tileColor: theme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.lock_outline),
                title: Text("Ubah Password", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                subtitle: const Text("Kirim link reset ke email", style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  // Pastikan email tidak null
                  if (user?.email == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Email tidak ditemukan!"), backgroundColor: Colors.red)
                    );
                    return;
                  }

                  try {
                    // Pakai await supaya sistem nunggu proses selesai
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Link reset dikirim ke ${user!.email}! Cek inbox atau spam."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    // Menangani error spesifik dari Firebase
                    String pesanError = "Gagal mengirim email";
                    if (e.code == 'too-many-requests') pesanError = "Terlalu banyak permintaan. Coba lagi nanti.";
                    if (e.code == 'network-request-failed') pesanError = "Koneksi internet bermasalah.";

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(pesanError), backgroundColor: Colors.red),
                      );
                    }
                    print("Error Reset Pass: ${e.code} - ${e.message}");
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),

              // --- PIN KEAMANAN ---
              Text("PIN Transaksi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text("Aktifkan PIN", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                      subtitle: const Text("Wajibkan PIN saat pembayaran", style: TextStyle(fontSize: 12)),
                      value: _isPinEnabled,
                      activeColor: theme.primary,
                      onChanged: (val) {
                        if (val) _showPinDialog(isCreating: true);
                        else _showPinDialog(isCreating: false, isDisabling: true);
                      },
                    ),
                    if (_isPinEnabled) const Divider(height: 1),
                    if (_isPinEnabled)
                      ListTile(
                        title: const Text("Ganti PIN"),
                        trailing: const Icon(Icons.edit, size: 18),
                        onTap: () => _showPinDialog(isCreating: true),
                      )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 2. HALAMAN PENGATURAN NOTIFIKASI
// ==========================================
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool orderNotif = true;
  bool promoNotif = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
                title: Text("Pengaturan Notifikasi", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)),
                backgroundColor: theme.surface,
                elevation: 0,
                iconTheme: IconThemeData(color: theme.textMain)
            ),
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
// 3. HALAMAN PENGATURAN APLIKASI
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
            appBar: AppBar(
                title: Text("Pengaturan Aplikasi", style: GoogleFonts.plusJakartaSans(color: currentTheme.textMain, fontWeight: FontWeight.bold)),
                backgroundColor: currentTheme.surface,
                elevation: 0,
                iconTheme: IconThemeData(color: currentTheme.textMain)
            ),
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
            appBar: AppBar(
                title: Text("Seputar Chupatu", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)),
                backgroundColor: theme.surface,
                elevation: 0,
                iconTheme: IconThemeData(color: theme.textMain)
            ),
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
                    Text(
                        "Layanan cuci sepatu terbaik, antar-jemput langsung ke depan pintu Anda.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey, height: 1.5)
                    ),
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