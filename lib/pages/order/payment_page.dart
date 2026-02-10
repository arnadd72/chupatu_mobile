import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chupatu_mobile/main.dart'; // Import Tema

class PaymentPage extends StatefulWidget {
  // Data yang dikirim dari Booking Page
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
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // State Pembayaran
  String _selectedPaymentMethod = 'COD'; // Default Cash
  final TextEditingController _promoController = TextEditingController();
  
  int _deliveryFee = 0;
  int _discountAmount = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Hitung Ongkir: Kalau Antar-Jemput aktif, kena 15rb (Dummy Logic)
    if (widget.isDelivery) {
      _deliveryFee = 15000;
    }
  }

  // --- LOGIKA PROMO CODE ---
  void _applyPromo() {
    // Dummy Promo Code
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

  // --- LOGIKA FINAL: SIMPAN KE FIRESTORE ---
  Future<void> _processPaymentAndOrder() async {
    setState(() => _isProcessing = true);
    final user = FirebaseAuth.instance.currentUser;
    int totalPrice = (widget.basePrice + _deliveryFee) - _discountAmount;

    try {
      String? imageUrl;
      
      // 1. Upload Foto (Jika ada)
      if (widget.shoeImageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('order_images')
            .child('${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(widget.shoeImageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      // 2. Simpan ke Firestore
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user?.uid,
        'customerName': user?.displayName ?? 'Guest',
        'phoneNumber': widget.phoneNumber,  
        'serviceName': widget.serviceName,
        'category': widget.category,
        'shoeDetail': widget.shoeDetail,
        'notes': widget.notes,
        
        // Data Harga & Pembayaran
        'basePrice': widget.basePrice,
        'deliveryFee': _deliveryFee,
        'discount': _discountAmount,
        'totalPrice': totalPrice,
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': _selectedPaymentMethod == 'Midtrans' ? 'Pending Payment' : 'Unpaid (COD)',
        
        'status': 'Pending',
        'isDelivery': widget.isDelivery,
        'pickupDate': widget.pickupDate, 
        'pickupTime': widget.pickupTime,
        'mainAddress': widget.mainAddress,
        'detailAddress': widget.detailAddress,
        'shoeImageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isProcessing = false);
        // Tampilkan Sukses & Kembali ke Home
        _showSuccessDialog();
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memproses: $e"), backgroundColor: Colors.red));
      }
    }
  }

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
            Text("Pesanan Diterima!"),
          ],
        ),
        content: Text(
          _selectedPaymentMethod == 'COD' 
          ? "Kurir kami akan segera menjemput sepatu kamu. Siapkan uang tunai saat penjemputan ya!"
          : "Silakan selesaikan pembayaran via Midtrans (Simulasi). Orderan sudah masuk ke sistem.",
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Tutup Dialog
                Navigator.of(context).pop(); // Tutup Payment Page
                Navigator.of(context).pop(); // Tutup Booking Page -> Balik Home
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("Kembali ke Home"),
            ),
          )
        ],
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
                // --- 1. RINGKASAN ORDER ---
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

                // --- 2. KODE PROMO ---
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

                // --- 3. METODE PEMBAYARAN ---
                _buildSectionTitle("Metode Pembayaran", theme),
                _buildPaymentOption("COD", "Bayar Tunai saat Dijemput", Icons.money, theme),
                const SizedBox(height: 12),
                _buildPaymentOption("Midtrans", "E-Wallet / Transfer Bank (Otomatis)", Icons.credit_card, theme),
              ],
            ),
          ),

          // --- BOTTOM BAR: TOMBOL BAYAR ---
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: theme.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPaymentAndOrder,
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

  // --- WIDGET HELPER ---
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
                  Text(id == 'COD' ? 'Cash on Delivery (COD)' : 'Online Payment', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
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