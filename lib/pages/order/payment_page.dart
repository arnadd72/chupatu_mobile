import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Untuk StreamSubscription
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/order/order_history_page.dart';

// Untuk nembak API & Buka Webview
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends StatefulWidget {
  final String serviceName;
  final int basePrice;
  final String category;
  final String shoeDetail;
  final String notes;
  final DateTime pickupDate;
  final String pickupTime;
  final bool isDelivery;
  final String mainAddress;
  final String detailAddress;
  final String phoneNumber;
  final File? shoeImageFile;
  final String? shoeImageUrl;
  final GeoPoint? customerLocation;

  const PaymentPage({
    super.key,
    required this.serviceName,
    required this.basePrice,
    required this.category,
    required this.shoeDetail,
    required this.notes,
    required this.pickupDate,
    required this.pickupTime,
    required this.isDelivery,
    required this.mainAddress,
    required this.detailAddress,
    required this.phoneNumber,
    this.shoeImageFile,
    this.shoeImageUrl,
    this.customerLocation,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentMethod = 'COD';
  final TextEditingController _promoController = TextEditingController();

  int _deliveryFee = 0;
  int _discountAmount = 0;
  bool _isProcessing = false;

  // Variabel CCTV dan URL Laravel
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  final String apiUrl = "https://malik-pseudomonocyclic-misti.ngrok-free.dev/api/create-mayar-payment";

  @override
  void initState() {
    super.initState();
    if (widget.isDelivery) {
      _deliveryFee = 15000;
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _applyPromo() {
    if (_promoController.text.toUpperCase() == 'CHUPATUHEBAT') {
      setState(() {
        _discountAmount = 10000;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kode Promo Berhasil! Hemat Rp 10.000"), backgroundColor: Colors.green));
    } else {
      setState(() => _discountAmount = 0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kode Promo Tidak Valid"), backgroundColor: Colors.red));
    }
  }

  // --- LOGIKA UTAMA TRANSAKSI ---
  Future<void> _processPaymentAndOrder() async {
    setState(() => _isProcessing = true);
    final user = FirebaseAuth.instance.currentUser;
    int totalPrice = (widget.basePrice + _deliveryFee) - _discountAmount;

    try {
      // 1. Simpan data awal ke Firestore dulu (Status: Pending Payment / Unpaid)
      DocumentReference newOrderRef = await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user?.uid,
        'customerName': user?.displayName ?? 'Guest',
        'phoneNumber': widget.phoneNumber,
        'serviceName': widget.serviceName,
        'category': widget.category,
        'shoeDetail': widget.shoeDetail,
        'notes': widget.notes,
        'basePrice': widget.basePrice,
        'deliveryFee': _deliveryFee,
        'discount': _discountAmount,
        'totalPrice': totalPrice,
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': _selectedPaymentMethod == 'Mayar' ? 'Pending Payment' : 'Unpaid (COD)',
        'status': 'Pending',
        'isDelivery': widget.isDelivery,
        'pickupDate': widget.pickupDate,
        'pickupTime': widget.pickupTime,
        'mainAddress': widget.mainAddress,
        'detailAddress': widget.detailAddress,
        'shoeImageUrl': widget.shoeImageUrl ?? '',
        'customerLocation': widget.customerLocation,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Cek apakah bayar pakai Mayar atau COD
      if (_selectedPaymentMethod == 'Mayar') {
        // Panggil fungsi proses Mayar
        await _processMayarPayment(newOrderRef.id, totalPrice, user);
      } else {
        // Kalau COD, langsung sukses
        if (mounted) {
          setState(() => _isProcessing = false);
          _showSuccessDialog();
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memproses: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- LOGIKA PEMBAYARAN MAYAR (DIPERBARUI) ---
  Future<void> _processMayarPayment(String orderId, int totalAmount, User? user) async {
    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'firebase_uid': user?.uid ?? '',
          'amount': totalAmount,
          'customer_name': user?.displayName ?? 'Customer Chupatu',
          'customer_email': user?.email ?? 'user@chupatu.com',
          'customer_mobile': widget.phoneNumber,
          'description': 'Pembayaran Layanan: ${widget.serviceName}',
          'payment_type': 'service'
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['success'] == true && data['payment_link'] != null) {
          String paymentUrl = data['payment_link'];

          // 1. Simpan Link ke Firestore
          await FirebaseFirestore.instance.collection('bookings').doc(orderId).update({
            'paymentUrl': paymentUrl,
          });

          if (mounted) {
            setState(() => _isProcessing = false);

            // 👉 PERBAIKAN: Arahkan langsung ke History Page, jangan di-pop ke Home!
            // Ini bakal ngehapus tumpukan halaman Checkout, dan naruh History Page di atas.
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
                  (route) => route.isFirst, // Sisakan halaman paling dasar (MainPage) aja
            );

            // 3. Buka Mayar
            launchUrl(
              Uri.parse(paymentUrl),
              mode: LaunchMode.inAppBrowserView,
            );
          }

        } else {
          throw Exception(data['message'] ?? 'Gagal mendapatkan link dari Mayar');
        }
      } else {
        throw Exception("Error Mayar: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal proses Mayar: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- DIALOG BARU: JIKA USER NUTUP BROWSER TAPI BELUM LUNAS ---
  void _showPendingPaymentDialog(String paymentUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // Ga bisa ditutup sembarangan klik luar
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.access_time_filled, color: Colors.orange, size: 60),
            SizedBox(height: 10),
            Text("Menunggu Pembayaran", textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
          ],
        ),
        content: const Text(
          "Pesanan kamu sudah tersimpan, tapi belum dibayar.\n\nJika kamu tidak sengaja menutup halaman pembayaran Mayar, kamu bisa melanjutkannya lewat tombol di bawah ini.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Coba buka lagi link Mayar-nya
                    launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0606F9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: const Text("Buka Lagi Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Keluar Payment Page
                  Navigator.of(context).pop(); // Balik ke Home

                  // Nanti kalau lo udah bikin halaman "Daftar Pesanan",
                  // lo bisa arahin usernya ke situ pakai Navigator.push()
                },
                child: const Text("Bayar Nanti (Kembali ke Beranda)", style: TextStyle(color: Colors.grey)),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- DIALOG SUKSES (TIDAK BERUBAH BANYAK) ---
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Pembayaran Berhasil!"),
          ],
        ),
        content: Text(
          _selectedPaymentMethod == 'COD'
              ? "Kurir kami akan segera menjemput sepatu kamu. Siapkan uang tunai saat penjemputan ya!"
              : "Lunas! Orderan kamu sudah masuk ke sistem dan akan segera kami proses secepatnya.",
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Tutup dialog sukses
                Navigator.of(context).pop(); // Tutup PaymentPage
                Navigator.of(context).pop(); // Tutup BookingPage kembali ke Home
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("Selesai & Mantap"),
            ),
          )
        ],
      ),
    );
  }

  // --- FITUR: CEK PIN SEBELUM TRANSAKSI ---
  Future<void> _handlePaymentAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      bool isPinEnabled = data['isPinEnabled'] ?? false;
      String savedPin = data['securityPin'] ?? "";

      if (!isPinEnabled) {
        await _processPaymentAndOrder();
        return;
      }

      setState(() => _isProcessing = false);
      _showPinVerificationSheet(savedPin);

    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    }
  }

  // --- MODAL INPUT PIN ---
  void _showPinVerificationSheet(String correctPin) {
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
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text("Konfirmasi PIN", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Masukkan 6 digit PIN keamanan Anda.", style: TextStyle(fontSize: 13, color: Colors.grey)),
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
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: localError != null ? Colors.red : Colors.transparent)
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: localError != null ? Colors.red : const Color(0xFF0606F9))
                    ),
                  ),
                  onChanged: (val) {
                    inputPin = val;
                    if (localError != null) {
                      setModalState(() => localError = null);
                    }
                  },
                ),

                if (localError != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        localError!,
                        style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (inputPin == correctPin) {
                        Navigator.pop(ctx);
                        _processPaymentAndOrder(); // Lanjut ke proses pembayaran
                      } else {
                        setModalState(() {
                          localError = "PIN Salah! Silakan coba lagi.";
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0606F9),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text("Konfirmasi & Bayar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    int totalPrice = (widget.basePrice + _deliveryFee) - _discountAmount;

    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text("Pembayaran", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              backgroundColor: theme.surface,
              iconTheme: IconThemeData(color: theme.textMain),
              elevation: 0,
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Rincian Pesanan", theme),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        _buildSummaryRow("Layanan", widget.serviceName, theme, isBold: true),
                        const SizedBox(height: 8),
                        _buildSummaryRow("Harga Dasar", currencyFormatter.format(widget.basePrice), theme),
                        const SizedBox(height: 8),
                        _buildSummaryRow("Biaya Antar-Jemput", _deliveryFee == 0 ? "Gratis" : currencyFormatter.format(_deliveryFee), theme),
                        if (_discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow("Diskon Promo", "- ${currencyFormatter.format(_discountAmount)}", theme, color: Colors.green),
                        ],
                        const Divider(height: 24),
                        _buildSummaryRow("Total Pembayaran", currencyFormatter.format(totalPrice), theme, isBold: true, fontSize: 18, color: theme.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Kode Promo", theme),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          style: GoogleFonts.plusJakartaSans(color: theme.textMain),
                          decoration: InputDecoration(
                            hintText: "Punya kode promo?",
                            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: theme.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _applyPromo,
                        style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
                        child: const Text("Pakai"),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Metode Pembayaran", theme),
                  _buildPaymentOption("COD", "Bayar Tunai saat Dijemput", Icons.money, theme),
                  const SizedBox(height: 12),
                  // Ubah Midtrans jadi Mayar
                  _buildPaymentOption("Mayar", "E-Wallet / Transfer Bank (Otomatis)", Icons.credit_card, theme),
                ],
              ),
            ),

            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: theme.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePaymentAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text("Bayar ${currencyFormatter.format(totalPrice)}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildSectionTitle(String title, AppThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)));
  }

  Widget _buildSummaryRow(String label, String value, AppThemeData theme, {bool isBold = false, double fontSize = 14, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: fontSize, color: Colors.grey.shade600)),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? theme.textMain)),
      ],
    );
  }

  Widget _buildPaymentOption(String id, String subtitle, IconData icon, AppThemeData theme) {
    bool isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary.withOpacity(0.05) : theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? theme.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: isSelected ? theme.primary : Colors.grey)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(id == 'COD' ? 'Cash on Delivery (COD)' : 'Online Payment (Mayar)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: theme.primary),
          ],
        ),
      ),
    );
  }
}