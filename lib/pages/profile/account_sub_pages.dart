import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/common/terms_conditions_page.dart';
import 'package:chupatu_mobile/pages/common/privacy_policy_page.dart';

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

  // --- LOGIKA POP-UP OTP BISA DIPAKAI UNTUK PASSWORD & PIN ---
  // Parameter isForPassword: true (Ubah Password), false (Lupa PIN)
  void _showOtpResetDialog(AppThemeData theme, {required bool isForPassword}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    String? phoneNumber;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      phoneNumber = doc.data()?['phoneNumber'] ?? doc.data()?['phone'];
    } catch (e) {
      debugPrint("Gagal ambil nomor: $e");
    }

    if (!mounted) return;
    Navigator.pop(context);

    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nomor WhatsApp belum diatur di Profil!"), backgroundColor: Colors.red)
      );
      return;
    }

    String inputOtp = "";
    String? localError;
    bool isOtpSent = false;
    bool isSending = false;
    String? generatedOtp;

    String dialogTitle = isForPassword ? "Verifikasi Ubah Password" : "Verifikasi Reset PIN";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: theme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(dialogTitle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isOtpSent) ...[
                  Text(
                      "Klik tombol di bawah untuk mengirim 6 digit kode OTP ke nomor WhatsApp Anda:\n\n$phoneNumber",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5)
                  ),
                ] else ...[
                  Text("Masukkan 6 digit kode yang kami kirim ke WhatsApp Anda.", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextField(
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10, color: theme.textMain),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: theme.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      inputOtp = val;
                      if (localError != null) setModalState(() => localError = null);
                    },
                  ),
                ],
                if (localError != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(localError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))
                  ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey))
              ),
              if (!isOtpSent)
                ElevatedButton(
                   onPressed: isSending ? null : () async {
                    setModalState(() { isSending = true; localError = null; });

                    var rnd = math.Random();
                    generatedOtp = (rnd.nextInt(900000) + 100000).toString();

                    String formattedPhone = phoneNumber!;
                    if (formattedPhone.startsWith('0')) {
                      formattedPhone = '62${formattedPhone.substring(1)}';
                    }

                    try {
                      // Ambil Fonnte token dari Firestore (tidak disimpan di kode)
                      final configDoc = await FirebaseFirestore.instance
                          .collection('system_settings')
                          .doc('config')
                          .get();
                      final fonnteToken = configDoc.data()?['fonnteToken'] ?? '';

                      if (fonnteToken.isEmpty) {
                        debugPrint("=================================");
                        debugPrint("MODE TESTING - OTP ANDA: $generatedOtp");
                        debugPrint("=================================");
                        setModalState(() {
                          isOtpSent = true;
                          isSending = false;
                          localError = "Mode Testing: Token Fonnte belum diatur Admin. Cek terminal VS Code.";
                        });
                        return;
                      }

                      final response = await http.post(
                        Uri.parse('https://api.fonnte.com/send'),
                        headers: {
                          'Authorization': fonnteToken,
                        },
                        body: {
                          'target': formattedPhone,
                          'message': '*Chupatu Mobile*\n\nKode OTP Anda adalah: *$generatedOtp*\n\n_Jangan berikan kode ini kepada siapapun._',
                        },
                      );

                      if (response.statusCode == 200) {
                        setModalState(() { isOtpSent = true; isSending = false; });
                        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kode OTP berhasil dikirim!"), backgroundColor: Colors.green));
                      } else {
                        debugPrint("=================================");
                        debugPrint("MODE TESTING - OTP ANDA: $generatedOtp");
                        debugPrint("=================================");
                        setModalState(() {
                          isOtpSent = true;
                          isSending = false;
                          localError = "Mode Testing: Buka terminal VS Code untuk melihat kode OTP.";
                        });
                      }
                    } catch (e) {
                      debugPrint("=================================");
                      debugPrint("MODE TESTING - OTP ANDA: $generatedOtp");
                      debugPrint("=================================");
                      setModalState(() {
                        isOtpSent = true;
                        isSending = false;
                        localError = "Mode Testing: Buka terminal VS Code untuk melihat kode OTP.";
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Kirim OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    if (inputOtp.length != 6) return;

                    if (inputOtp == generatedOtp) {
                      Navigator.pop(ctx);

                      // KONDISI SETELAH OTP BENAR:
                      if (isForPassword) {
                        // 1. JIKA UNTUK UBAH PASSWORD
                        if (user?.email == null) return;
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                          if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text("Link reset dikirim ke ${user!.email}! Silakan cek email Anda."), backgroundColor: Colors.green));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
                        }
                      } else {
                        // 2. JIKA UNTUK RESET PIN
                        _showPinDialog(isCreating: true);
                      }

                    } else {
                      setModalState(() => localError = "Kode OTP Salah!");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text("Verifikasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showPinDialog({required bool isCreating, bool isDisabling = false}) {
    String inputPin = "";
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text(isCreating ? "Buat PIN Baru" : "Konfirmasi PIN", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(isCreating ? "Masukkan 6 digit angka untuk keamanan." : "Masukkan PIN lama untuk menonaktifkan.", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 24),
                TextField(
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, letterSpacing: 15, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: "",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: localError != null ? Colors.red : Colors.transparent)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: localError != null ? Colors.red : const Color(0xFF0606F9))),
                  ),
                  onChanged: (val) {
                    inputPin = val;
                    if (localError != null) setModalState(() => localError = null);
                  },
                ),
                if (localError != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text(localError!, style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (inputPin.length != 6) return;

                      if (isCreating) {
                        Navigator.pop(ctx);
                        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                          'securityPin': inputPin,
                          'isPinEnabled': true,
                        });
                        setState(() => _isPinEnabled = true);
                        if(mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text("PIN Berhasil Disimpan!"), backgroundColor: Colors.green));
                      } else if (isDisabling) {
                        final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
                        if (doc.data()?['securityPin'] == inputPin) {
                          Navigator.pop(ctx);
                          await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'isPinEnabled': false});
                          setState(() => _isPinEnabled = false);
                          if(mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text("PIN Berhasil Dinonaktifkan."), backgroundColor: Colors.orange));
                        } else {
                          setModalState(() => localError = "PIN Salah! Silakan coba lagi.");
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0606F9), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
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
              Text("Verifikasi Data", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(isEmailVerified ? Icons.verified : Icons.warning_amber_rounded, color: isEmailVerified ? Colors.green : Colors.orange),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Status Akun", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                          Text(isEmailVerified ? "Email Terverifikasi" : "Email Belum Diverifikasi", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (!isEmailVerified)
                      TextButton(onPressed: () => user?.sendEmailVerification(), child: const Text("Verifikasi Sekarang"))
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text("Kata Sandi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              ListTile(
                tileColor: theme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.lock_outline),
                title: Text("Ubah Password", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                subtitle: const Text("Kirim link reset ke email", style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                // --- PERUBAHAN: Tambah Pop-up Konfirmasi Sebelum Kirim Email ---
                onTap: () {
                  if (user?.email == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Email tidak ditemukan!"), backgroundColor: Colors.red)
                    );
                    return;
                  }

                  // 1. Munculkan Pop-up Konfirmasi Dulu
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: theme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text("Ubah Password", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                      content: Text(
                        "Apakah Anda yakin ingin mengirim link reset password ke email ${user!.email}?",
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13, height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx); // Tutup dialog konfirmasi

                            // 2. Munculkan loading sebentar saat ngirim
                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (loadingCtx) => const Center(child: CircularProgressIndicator())
                            );

                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                              if (context.mounted) {
                                Navigator.pop(context); // Tutup loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Link reset dikirim ke ${user!.email}! Silakan cek email Anda."), backgroundColor: Colors.green)
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context); // Tutup loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Gagal mengirim link: $e"), backgroundColor: Colors.red)
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Kirim Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
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

                    // --- FITUR GANTI/LUPA PIN MENGGUNAKAN OTP WA ---
                    if (_isPinEnabled) const Divider(height: 1),
                    if (_isPinEnabled)
                      ListTile(
                        title: Text("Ganti / Lupa PIN?", style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.lock_reset_rounded, size: 20, color: Colors.redAccent),
                        onTap: () => _showOtpResetDialog(theme, isForPassword: false),
                      ),
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              orderNotif = data['orderNotif'] ?? true;
              promoNotif = data['promoNotif'] ?? true;
              _isLoading = false;
            });
          }
          return;
        }
      } catch (e) {
        debugPrint("Gagal memuat pengaturan: $e");
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSetting(String key, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        key: value,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(title: Text("Pengaturan Notifikasi", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)), backgroundColor: theme.surface, elevation: 0, iconTheme: IconThemeData(color: theme.textMain)),
            body: _isLoading
                ? Center(child: CircularProgressIndicator(color: theme.primary))
                : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SwitchListTile(title: Text("Update Status Pesanan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)), subtitle: Text("Notifikasi saat sepatu dijemput, dicuci, dan selesai", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)), activeColor: theme.primary, value: orderNotif, onChanged: (val) { setState(() => orderNotif = val); _saveSetting('orderNotif', val); }),
                const Divider(),
                SwitchListTile(title: Text("Promo & Diskon", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)), subtitle: Text("Dapatkan info potongan harga terbaru", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)), activeColor: theme.primary, value: promoNotif, onChanged: (val) { setState(() => promoNotif = val); _saveSetting('promoNotif', val); }),
              ],
            ),
          );
        }
    );
  }
}

// ==========================================
// 3. HALAMAN PENGATURAN APLIKASI (CACHE & BAHASA AKTIF)
// ==========================================
class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  String _cacheSize = "Menghitung...";

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true).forEach((entity) {
          if (entity is File) totalSize += entity.lengthSync();
        });
      }
      if (mounted) {
        setState(() {
          _cacheSize = "${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cacheSize = "0.00 MB");
    }
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
        await tempDir.create();
      }
      await _calculateCacheSize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cache berhasil dibersihkan!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus cache: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildSectionHeader(String title, AppThemeData theme) {
    return Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey));
  }

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
            iconTheme: IconThemeData(color: currentTheme.textMain),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionHeader("Pilih Tema Aplikasi", currentTheme),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.8,
                ),
                itemCount: ThemeConfig.themes.length,
                itemBuilder: (context, index) {
                  final themeData = ThemeConfig.themes[index];
                  bool isSelected = currentTheme.name == themeData.name;
                  return GestureDetector(
                    onTap: () => ThemeConfig.changeTheme(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeData.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? themeData.primary : Colors.grey.withOpacity(0.2), width: isSelected ? 2 : 1),
                        boxShadow: [if (isSelected) BoxShadow(color: themeData.primary.withOpacity(0.2), blurRadius: 8)],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 32, height: 32, decoration: BoxDecoration(color: themeData.primary, shape: BoxShape.circle), child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null),
                          const SizedBox(height: 8),
                          Text(themeData.name, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: themeData.textMain)),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
              _buildSectionHeader("Bahasa / Language", currentTheme),
              const SizedBox(height: 12),

              ValueListenableBuilder<Locale>(
                  valueListenable: LanguageConfig.currentLocale,
                  builder: (context, currentLocale, _) {
                    String activeLang = currentLocale.languageCode;

                    return Container(
                      decoration: BoxDecoration(color: currentTheme.surface, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          ListTile(
                            onTap: () => LanguageConfig.changeLanguage("id"),
                            leading: Icon(Icons.language, color: activeLang == "id" ? currentTheme.primary : Colors.grey),
                            title: Text("Bahasa Indonesia", style: GoogleFonts.plusJakartaSans(color: currentTheme.textMain, fontSize: 14)),
                            trailing: activeLang == "id" ? Icon(Icons.radio_button_checked, color: currentTheme.primary) : const Icon(Icons.radio_button_off, color: Colors.grey),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            onTap: () => LanguageConfig.changeLanguage("en"),
                            leading: Icon(Icons.language, color: activeLang == "en" ? currentTheme.primary : Colors.grey),
                            title: Text("English (US)", style: GoogleFonts.plusJakartaSans(color: currentTheme.textMain, fontSize: 14)),
                            trailing: activeLang == "en" ? Icon(Icons.radio_button_checked, color: currentTheme.primary) : const Icon(Icons.radio_button_off, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
              ),

              const SizedBox(height: 32),
              _buildSectionHeader("Penyimpanan & Cache", currentTheme),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: currentTheme.surface, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(Icons.storage_rounded, color: currentTheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Cache Aplikasi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: currentTheme.textMain)),
                          Text(_cacheSize, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _clearCache,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), foregroundColor: Colors.red, elevation: 0),
                      child: const Text("Bersihkan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
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
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TermsConditionsPage()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: theme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          child: Text("Syarat & Ketentuan", style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold))
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: theme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          child: Text("Kebijakan Privasi", style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold))
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}