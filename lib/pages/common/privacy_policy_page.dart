import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Tema (Sama dengan Terms & Conditions)
    const Color primaryBlue = Color(0xFF0606F9);
    const Color accentCyan = Color(0xFF00D4FF);
    const Color textDark = Color(0xFF0B0F19);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // ============================================================
          // 1. BACKGROUND (Mesh Gradient & Glass)
          // ============================================================
          Positioned(
            top: -100, left: -50,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [primaryBlue.withOpacity(0.3), Colors.transparent], radius: 0.7)),
            ),
          ),
          Positioned(
            bottom: -100, right: -50,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [accentCyan.withOpacity(0.3), Colors.transparent], radius: 0.7)),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.white.withOpacity(0.1)),
            ),
          ),

          // ============================================================
          // 2. KONTEN UTAMA
          // ============================================================
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Kebijakan Privasi',
                        style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
                      ),
                    ],
                  ),
                ),

                // Area Scroll Konten
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, primaryBlue, accentCyan]),
                      boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15))],
                    ),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(30)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('1. Pendahuluan', primaryBlue),
                              _buildSectionContent('Privasi Anda sangat penting bagi kami. Kebijakan Privasi ini menjelaskan bagaimana Chupatu mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda saat menggunakan aplikasi kami.'),
                              const SizedBox(height: 20),

                              _buildSectionTitle('2. Informasi yang Kami Kumpulkan', primaryBlue),
                              _buildSectionContent('Kami mengumpulkan informasi yang Anda berikan secara langsung, seperti:\n• Nama dan Alamat Email (saat registrasi).\n• Nomor Telepon dan Alamat Lengkap (untuk keperluan antar-jemput kurir).\n• Foto Sepatu (untuk bukti kondisi barang).\n• Data Pembayaran (diproses secara aman melalui Midtrans/Pihak Ketiga).'),
                              const SizedBox(height: 20),

                              _buildSectionTitle('3. Penggunaan Data', primaryBlue),
                              _buildSectionContent('Data yang kami kumpulkan semata-mata digunakan untuk:\n• Memproses pesanan cuci/reparasi sepatu Anda.\n• Menghubungi Anda terkait status pesanan atau kendala pengiriman.\n• Meningkatkan kualitas layanan dan keamanan aplikasi.'),
                              const SizedBox(height: 20),

                              _buildSectionTitle('4. Pembagian Data dengan Pihak Ketiga', primaryBlue),
                              _buildSectionContent('Kami tidak pernah menjual data Anda. Kami hanya membagikan informasi penting kepada mitra kerja kami (seperti kurir pengiriman dan penyedia gerbang pembayaran/payment gateway) sebatas untuk keperluan pemrosesan layanan Anda.'),
                              const SizedBox(height: 20),

                              _buildSectionTitle('5. Keamanan Data', primaryBlue),
                              _buildSectionContent('Kami menggunakan sistem keamanan berbasis cloud (Firebase) yang dilindungi oleh enkripsi standar industri untuk menjaga data akun dan riwayat transaksi Anda dari akses yang tidak sah.'),
                              const SizedBox(height: 20),

                              _buildSectionTitle('6. Hak Pengguna', primaryBlue),
                              _buildSectionContent('Anda berhak untuk mengakses, memperbarui, atau meminta penghapusan akun dan data pribadi Anda dari server kami kapan saja melalui menu pengaturan akun atau dengan menghubungi layanan pelanggan kami.'),

                              const SizedBox(height: 40),
                              Center(
                                child: Text(
                                  'Terakhir Diperbarui: Desember 2025',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: color, letterSpacing: -0.5));
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(content, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600, height: 1.6), textAlign: TextAlign.justify),
    );
  }
}