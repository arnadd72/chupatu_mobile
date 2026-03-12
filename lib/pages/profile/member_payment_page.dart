import 'dart:convert'; // WAJIB: Untuk decode API
import 'dart:async'; // Untuk StreamSubscription (CCTV)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:http/http.dart' as http; // WAJIB: Untuk nembak API Laravel
import 'package:url_launcher/url_launcher.dart'; // WAJIB: Buka browser Mayar

class MemberPaymentPage extends StatefulWidget {
  final VoidCallback onPaymentSuccess;

  const MemberPaymentPage({super.key, required this.onPaymentSuccess});

  @override
  State<MemberPaymentPage> createState() => _MemberPaymentPageState();
}

class _MemberPaymentPageState extends State<MemberPaymentPage> {
  bool _isProcessing = false;
  int _selectedMethod = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  // Variabel untuk nyimpen "CCTV" Firestore
  StreamSubscription<DocumentSnapshot>? _paymentSubscription;

  // 👇 GANTI PAKE LINK NGROK LARAVEL LO 👇
  final String apiUrl = "https://malik-pseudomonocyclic-misti.ngrok-free.dev/api/create-mayar-payment";

  // Jangan lupa matiin CCTV kalau halaman ditutup
  @override
  void dispose() {
    _paymentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text("Pembayaran Member", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              backgroundColor: theme.surface,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rincian Pesanan", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.textMain.withOpacity(0.1)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: const Color(0xFFFFD700).withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.star, color: Color(0xFFFFD700), size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Chupatu PRO Member", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)),
                              Text("Langganan 1 Bulan", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text("Rp 49.000", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text("Informasi Pembayaran", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: theme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                              "Anda akan diarahkan ke halaman pembayaran aman Mayar.id (Support QRIS, VA, E-Wallet)",
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: theme.textMain)
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : () => _processPayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: _isProcessing
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Lanjutkan Pembayaran", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  // --- LOGIKA PROSES PEMBAYARAN VIA MAYAR ---
  void _processPayment(BuildContext context) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Harus login dulu!"), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      String orderId = "PRO-" + DateTime.now().millisecondsSinceEpoch.toString();

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'firebase_uid': user?.uid ?? '',
          'amount': 49000,
          'customer_name': user?.displayName ?? 'Member Chupatu',
          'customer_email': user?.email ?? 'user@chupatu.com',
          'customer_mobile': '081234567890',
          'description': 'Langganan Chupatu Member Pro (1 Bulan)'
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['success'] == true && data['payment_link'] != null) {
          String paymentUrl = data['payment_link'];

          // 👉 PERBAIKAN 1: Pakai inAppBrowserView biar tombol 'X' muncul
          if (await launchUrl(
            Uri.parse(paymentUrl),
            mode: LaunchMode.inAppBrowserView,
          )) {

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Menunggu pembayaran diselesaikan..."),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 5),
                  )
              );
            }

            // Pasang "CCTV" ke Firestore untuk mantau perubahan memberType
            _paymentSubscription = FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .snapshots()
                .listen((snapshot) {

              if (snapshot.exists) {
                var userData = snapshot.data() as Map<String, dynamic>;

                // Kalau webhook udah sukses ngubah jadi 'Pro'
                if (userData['memberType'] == 'Pro') {
                  // 1. Matiin CCTV biar ga dobel-dobel
                  _paymentSubscription?.cancel();

                  // 👉 PERBAIKAN 2: Tutup otomatis WebView Mayar-nya!
                  closeInAppWebView();

                  // 3. Munculin Pop-Up Sukses!
                  if (mounted) {
                    _showSuccessDialog(context);
                  }
                }
              }
            });

          } else {
            throw Exception('Gagal membuka browser pembayaran');
          }
        } else {
          throw Exception(data['message'] ?? 'Gagal mendapatkan link dari Mayar');
        }
      } else {
        throw Exception("Error Mayar: ${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/trophy.json',
              height: 120,
              repeat: false,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.check_circle, color: Colors.green, size: 80),
            ),
            const SizedBox(height: 16),
            Text("Pembayaran Berhasil!", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Selamat! Akun Anda kini sudah PRO.", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup Dialog
                  Navigator.pop(context); // Kembali ke halaman sebelumnya
                  widget.onPaymentSuccess(); // Panggil callback buat refresh data
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("OK, Mantap"),
              ),
            )
          ],
        ),
      ),
    );
  }
}