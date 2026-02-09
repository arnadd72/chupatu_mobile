import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; 
// PENTING: Import main.dart untuk mengambil Tema
import 'package:chupatu_mobile/main.dart'; 

class MemberPaymentPage extends StatefulWidget {
  final VoidCallback onPaymentSuccess; // Callback: Fungsi yang dipanggil kalau bayar sukses

  const MemberPaymentPage({super.key, required this.onPaymentSuccess});

  @override
  State<MemberPaymentPage> createState() => _MemberPaymentPageState();
}

class _MemberPaymentPageState extends State<MemberPaymentPage> {
  bool _isProcessing = false; // Loading state saat proses bayar
  int _selectedMethod = 0; // 0: Gopay, 1: OVO, 2: Dana

  @override
  Widget build(BuildContext context) {
    // Menggunakan ValueListenableBuilder agar tampilan mengikuti Tema dari main.dart
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
                // 1. KARTU RINCIAN PESANAN
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

                // 2. PILIHAN METODE PEMBAYARAN
                Text("Pilih Metode Pembayaran", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                const SizedBox(height: 16),
                _buildPaymentMethod(0, "Gopay", theme),
                _buildPaymentMethod(1, "OVO", theme),
                _buildPaymentMethod(2, "Dana", theme),

                const SizedBox(height: 40),

                // 3. TOMBOL BAYAR
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
                        : Text("Bayar Rp 49.000", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // Widget Item Metode Pembayaran (Bisa diklik)
  Widget _buildPaymentMethod(int index, String name, AppThemeData theme) {
    bool isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? theme.primary : Colors.grey.withOpacity(0.2), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: isSelected ? theme.primary : Colors.grey), 
            const SizedBox(width: 16),
            Expanded(child: Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: theme.textMain))),
            if (isSelected) Icon(Icons.check_circle, color: theme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  // Logika Proses Pembayaran
  void _processPayment(BuildContext context) async {
    setState(() => _isProcessing = true);
    
    // 1. Simulasi Loading 2 Detik (Pura-pura connect ke bank)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 2. Tampilkan Dialog Sukses
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animasi Lottie (Pastikan file ada, atau pakai Icon fallback)
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
                  Navigator.pop(context); // Tutup Halaman Payment
                  
                  // 3. JALANKAN FUNGSI DARI PARENT (Update Status di ProfilePage)
                  widget.onPaymentSuccess(); 
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