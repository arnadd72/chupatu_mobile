import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Untuk StreamSubscription
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart'; // WAJIB UNTUK HITUNG JARAK
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

  // Variabel untuk Dynamic Pricing
  bool _isLoadingFee = true;
  bool _isProMember = false;
  double _distanceKm = 0.0;

  // Variabel Sinkronisasi Firestore & Pembayaran
  bool _isMayarActive = true;
  bool _isCodActive = true;
  String _paymentMethod = 'manual';

  // Variabel CCTV dan URL Laravel
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  final String apiUrl = "https://malik-pseudomonocyclic-misti.ngrok-free.dev/api/create-mayar-payment";

  @override
  void initState() {
    super.initState();
    // PERBAIKAN: Gak lagi hardcode 15.000, panggil fungsi cerdas!
    _calculateDynamicFee();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _promoController.dispose(); // Best practice: dispose controller
    super.dispose();
  }

  // ==========================================================
  // FITUR: KALKULASI ONGKIR DINAMIS & CEK MEMBER PRO
  // ==========================================================
  Future<void> _calculateDynamicFee() async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      // 1. Tarik parameter setting sistem TERLEBIH DAHULU agar metode pembayaran (Mayar) selalu ter-sync
      final settingsDoc = await FirebaseFirestore.instance.collection('system_settings').doc('config').get();
      
      double storeLat = -7.4357;
      double storeLng = 109.2505;
      int baseDeliveryFee = 5000;
      double baseDistanceKm = 3.0;
      int extraFeePerKm = 2000;
      int freeDeliveryMinOrder = 50000;
      bool isDeliveryActive = true;

      if (settingsDoc.exists) {
        final settingsData = settingsDoc.data()!;
        storeLat = (settingsData['storeLat'] as num?)?.toDouble() ?? -7.4357;
        storeLng = (settingsData['storeLng'] as num?)?.toDouble() ?? 109.2505;
        baseDeliveryFee = (settingsData['baseDeliveryFee'] as num?)?.toInt() ?? 5000;
        baseDistanceKm = (settingsData['baseDistanceKm'] as num?)?.toDouble() ?? 3.0;
        extraFeePerKm = (settingsData['extraFeePerKm'] as num?)?.toInt() ?? 2000;
        freeDeliveryMinOrder = (settingsData['freeDeliveryMinOrder'] as num?)?.toInt() ?? 50000;
        isDeliveryActive = settingsData['isDeliveryActive'] as bool? ?? true;
        
        // Sync payment configurations
        _isMayarActive = settingsData['isMayarActive'] as bool? ?? true;
        _paymentMethod = settingsData['paymentMethod'] as String? ?? 'manual';
        _isCodActive = settingsData['isCodActive'] as bool? ?? true;
      }

      // 2. Cek Status Member Pro di Firestore
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          _isProMember = (data['memberType'] == 'Pro' || data['role'] == 'Pro');
        }
      }

      // Fungsi Helper untuk menyimpan state ongkir dan default payment
      void applyState(int fee) {
        if (mounted) {
          setState(() {
            _deliveryFee = fee;
            _isLoadingFee = false;
            if (_paymentMethod == 'mayar' && _isMayarActive) {
              _selectedPaymentMethod = 'Mayar';
            } else {
              _selectedPaymentMethod = 'COD';
            }
          });
        }
      }

      // 3. Logika Early Returns
      // Jika pesanan bukan Antar Jemput (Hanya Jemput)
      if (!widget.isDelivery) {
        applyState(0);
        return;
      }

      // Jika Pro, otomatis ongkir GRATIS
      if (_isProMember) {
        applyState(0);
        return;
      }

      // Jika fitur Antar-Jemput dimatikan admin
      if (!isDeliveryActive) {
        applyState(0);
        return;
      }

      // 4. Hitung Jarak Jika Bukan Pro (Menggunakan koordinat Alamat dari BookingPage)
      if (widget.customerLocation != null) {
        // Menghitung jarak dalam meter
        double distanceInMeters = Geolocator.distanceBetween(
            storeLat,
            storeLng,
            widget.customerLocation!.latitude,
            widget.customerLocation!.longitude
        );

        _distanceKm = distanceInMeters / 1000;

        // Logika Harga Dinamis dari Firestore
        int calculatedFee = baseDeliveryFee;
        if (_distanceKm > baseDistanceKm) {
          int extraKm = (_distanceKm - baseDistanceKm).ceil(); // Pembulatan ke atas
          calculatedFee += (extraKm * extraFeePerKm);
        }

        // Cek gratis ongkir min order
        if (widget.basePrice >= freeDeliveryMinOrder) {
          calculatedFee = 0;
        }

        applyState(calculatedFee);
      } else {
        // Fallback jika customerLocation gagal dikirim
        applyState(baseDeliveryFee);
      }
    } catch (e) {
      debugPrint("Gagal menghitung ongkir: $e");
      if (mounted) {
        setState(() {
          _deliveryFee = 15000; // Fallback jika terjadi error
          _isLoadingFee = false;
          // Pastikan payment method tetap ter-set meski error
          if (_paymentMethod == 'mayar' && _isMayarActive) {
            _selectedPaymentMethod = 'Mayar';
          } else {
            _selectedPaymentMethod = 'COD';
          }
        });
      }
    }
  }

  Future<void> _applyPromo() async {
    final promoInput = _promoController.text.trim().toUpperCase();
    if (promoInput.isEmpty) return;

    try {
      final settingsDoc = await FirebaseFirestore.instance.collection('system_settings').doc('config').get();
      if (settingsDoc.exists) {
        final settingsData = settingsDoc.data()!;
        final activePromoCode = (settingsData['promoCode'] as String?)?.trim().toUpperCase() ?? 'CHUPATUHEBAT';
        final activePromoDiscount = (settingsData['promoDiscount'] as num?)?.toInt() ?? 10000;

        if (promoInput == activePromoCode) {
          setState(() {
            _discountAmount = activePromoDiscount;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Kode Promo Berhasil! Hemat Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(activePromoDiscount)}"),
            backgroundColor: Colors.green,
          ));
          return;
        }
      }
      
      setState(() => _discountAmount = 0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kode Promo Tidak Valid"), backgroundColor: Colors.red));
    } catch (e) {
      debugPrint("Gagal memproses promo: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memproses promo. Coba lagi."), backgroundColor: Colors.red));
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
        // TAMBAHAN: Simpan histori jarak dan penggunaan benefit Pro
        'isProMemberUsed': _isProMember,
        'distanceKm': _distanceKm,
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

  // --- LOGIKA PEMBAYARAN MAYAR ---
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
          String? mayarPaymentId = data['mayar_payment_id'];

          // 1. Simpan Link + Mayar Payment ID ke Firestore
          await FirebaseFirestore.instance.collection('bookings').doc(orderId).update({
            'paymentUrl': paymentUrl,
            'mayarPaymentId': mayarPaymentId ?? '',
          });

          if (mounted) {
            setState(() => _isProcessing = false);

            // 2. Buka Mayar di browser dan tunggu user kembali
            await launchUrl(
              Uri.parse(paymentUrl),
              mode: LaunchMode.inAppBrowserView,
            );

            // 3. Setelah user kembali dari browser, langsung cek status ke API Mayar
            //    (Plan B: bypass webhook, polling langsung)
            if (mayarPaymentId != null && mayarPaymentId.isNotEmpty) {
              await _pollPaymentStatus(orderId, mayarPaymentId, user);
            } else {
              // Fallback: langsung navigasi ke order history
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
                  (route) => route.isFirst,
                );
              }
            }
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

  // --- FITUR BARU: POLLING STATUS PEMBAYARAN ---
  // Setelah user kembali dari browser Mayar, kita tanya server:
  // "Hei, ini invoice udah dibayar belum?" → Jika sudah, update Firestore.
  Future<void> _pollPaymentStatus(String orderId, String mayarPaymentId, User? user) async {
    if (!mounted) return;

    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Mengecek status pembayaran...",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
            ),
          ],
        ),
      ),
    );

    // Polling: coba cek sampai 5x dengan jeda 3 detik
    String finalStatus = 'unpaid';
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 3));

      try {
        final checkUrl = apiUrl.replaceAll('create-mayar-payment', 'check-payment-status');
        var checkResponse = await http.post(
          Uri.parse(checkUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'order_id': orderId,
            'mayar_payment_id': mayarPaymentId,
            'firebase_uid': user?.uid ?? '',
            'payment_type': 'service',
          }),
        );

        if (checkResponse.statusCode == 200) {
          var checkData = jsonDecode(checkResponse.body);
          debugPrint("Poll #${i + 1}: status = ${checkData['status']}");

          if (checkData['status'] == 'paid') {
            finalStatus = 'paid';
            break;
          }
        }
      } catch (e) {
        debugPrint("Poll error: $e");
      }
    }

    // Tutup dialog loading
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    if (finalStatus == 'paid') {
      // Sukses bayar! Tampilkan dialog sukses
      if (mounted) {
        _showSuccessDialog();
      }
    } else {
      // Belum terdeteksi bayar, navigasi ke halaman riwayat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jika Anda sudah membayar, status akan otomatis terupdate dalam beberapa saat."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
          (route) => route.isFirst,
        );
      }
    }
  }

  // --- DIALOG BARU: JIKA USER NUTUP BROWSER TAPI BELUM LUNAS ---
  void _showPendingPaymentDialog(String paymentUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text("Bayar Nanti (Kembali ke Beranda)", style: TextStyle(color: Colors.grey)),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- DIALOG SUKSES ---
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
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
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
                        _processPaymentAndOrder();
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
            // Tampilkan loading screen jika ongkir masih dihitung Firestore
            body: _isLoadingFee
                ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text("Menghitung biaya antar-jemput...", style: GoogleFonts.plusJakartaSans(color: theme.textMain))
              ],
            ))
                : SingleChildScrollView(
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

                        // PERUBAHAN UI: Tampilkan detail Pro Member atau Hitungan Jarak
                        _buildSummaryRow(
                            "Biaya Antar-Jemput",
                            _isProMember
                                ? "Gratis (Member Pro)"
                                : (_deliveryFee == 0 ? "Gratis" : "${currencyFormatter.format(_deliveryFee)} (${_distanceKm.toStringAsFixed(1)} KM)"),
                            theme,
                            color: _isProMember ? Colors.blue : null
                        ),

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
                  if (_isCodActive) ...[
                    _buildPaymentOption("COD", "Bayar Tunai saat Dijemput (COD)", Icons.money, theme),
                  ],
                  if (_isCodActive && (_paymentMethod == 'mayar' && _isMayarActive)) ...[
                    const SizedBox(height: 12),
                  ],
                  if (_paymentMethod == 'mayar' && _isMayarActive) ...[
                    _buildPaymentOption("Mayar", "E-Wallet / Transfer Bank (Otomatis)", Icons.credit_card, theme),
                  ],
                ],
              ),
            ),

            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: theme.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Tombol di-disable saat masih loading fee atau processing
                  onPressed: (_isProcessing || _isLoadingFee) ? null : _handlePaymentAuth,
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