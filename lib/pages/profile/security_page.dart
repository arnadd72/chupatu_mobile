import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';

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
    _checkSecurityStatus();
  }

  // Cek Status PIN dari Firestore
  Future<void> _checkSecurityStatus() async {
    if (user == null) return;

    // Reload user biar status email verified ter-update
    await user!.reload();

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          _isPinEnabled = doc.data()?['isPinEnabled'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error load security: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA GANTI PASSWORD ---
  void _resetPassword() async {
    if (user?.email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link reset password dikirim ke email!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    }
  }

  // --- LOGIKA VERIFIKASI EMAIL ---
  void _sendVerificationEmail() async {
    if (user == null) return;
    try {
      await user!.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link verifikasi dikirim! Cek inbox/spam email."), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    }
  }

  // --- LOGIKA TOGGLE PIN ---
  void _togglePin(bool value) async {
    if (value) {
      // MAU AKTIFKAN -> Minta Bikin PIN Baru
      _showPinDialog(isCreating: true);
    } else {
      // MAU MATIKAN -> Konfirmasi PIN Lama dlu (biar aman)
      _showPinDialog(isCreating: false, isDisabling: true);
    }
  }

  // --- DIALOG INPUT PIN ---
  void _showPinDialog({required bool isCreating, bool isDisabling = false}) {
    String inputPin = "";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isCreating ? "Buat PIN Baru" : "Masukkan PIN", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCreating
                    ? "Masukkan 6 digit angka untuk keamanan transaksi."
                    : "Verifikasi PIN Anda untuk melanjutkan.",
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) => inputPin = val,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (inputPin.length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN harus 6 digit!")));
                  return;
                }

                Navigator.pop(context); // Tutup dialog dulu

                if (isCreating) {
                  // SIMPAN PIN KE FIRESTORE
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                    'securityPin': inputPin,
                    'isPinEnabled': true,
                  });
                  setState(() => _isPinEnabled = true);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN Keamanan Aktif!"), backgroundColor: Colors.green));
                } else if (isDisabling) {
                  // CEK PIN LAMA DULU
                  final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
                  String savedPin = doc.data()?['securityPin'] ?? "";

                  if (inputPin == savedPin) {
                    // MATIKAN PIN
                    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                      'isPinEnabled': false,
                    });
                    setState(() => _isPinEnabled = false);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN Dinonaktifkan."), backgroundColor: Colors.orange));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN Salah!"), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text("Konfirmasi"),
            ),
          ],
        );
      },
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
              padding: const EdgeInsets.all(20),
              children: [
                // --- SECTION 1: PASSWORD & EMAIL ---
                Text("Login & Verifikasi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.lock_reset, color: Colors.blue)),
                        title: Text("Ubah Kata Sandi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                        subtitle: Text("Kirim link reset ke email", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        onTap: _resetPassword,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isEmailVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: Icon(isEmailVerified ? Icons.verified_user : Icons.warning_amber_rounded, color: isEmailVerified ? Colors.green : Colors.orange)),
                        title: Text("Verifikasi Data (Email)", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                        subtitle: Text(isEmailVerified ? "Akun Terverifikasi" : "Email belum diverifikasi", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isEmailVerified ? Colors.green : Colors.red)),
                        trailing: isEmailVerified
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : ElevatedButton(
                          onPressed: _sendVerificationEmail,
                          style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(60, 30)),
                          child: const Text("Verifikasi", style: TextStyle(fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- SECTION 2: PIN TRANSAKSI ---
                Text("Keamanan Transaksi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.dialpad_rounded, color: theme.primary)),
                        title: Text("PIN Pembayaran", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                        subtitle: Text("Wajibkan PIN saat bayar", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                        activeColor: theme.primary,
                        value: _isPinEnabled,
                        onChanged: (val) => _togglePin(val),
                      ),
                      if (_isPinEnabled) ...[
                        const Divider(height: 1),
                        ListTile(
                          title: Text("Ubah PIN", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: theme.textMain)),
                          trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
                          onTap: () => _showPinDialog(isCreating: true), // Timpa PIN lama
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
          );
        }
    );
  }
}