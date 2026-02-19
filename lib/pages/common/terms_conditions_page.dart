import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Tema (Konsisten dengan Login/Register Page)
    const Color primaryBlue = Color(0xFF0606F9);
    const Color accentCyan = Color(0xFF00D4FF);
    const Color textDark = Color(0xFF0B0F19);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // ============================================================
          // 1. REVOLUTIONARY BACKGROUND (Mesh Gradient)
          // ============================================================
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primaryBlue.withOpacity(0.3), Colors.transparent],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentCyan.withOpacity(0.3), Colors.transparent],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          // Glass Overlay
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
                // Header: Tombol Back & Judul
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
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Terms & Conditions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content Area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    padding: const EdgeInsets.all(2), // Gradient Border width
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, primaryBlue, accentCyan],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('1. Pengantar', primaryBlue),
                              _buildSectionContent(
                                  'Selamat datang di Chupatu! Syarat dan Ketentuan ini mengatur penggunaan layanan perawatan sepatu kami. Dengan menggunakan aplikasi kami, Anda menyetujui persyaratan ini sepenuhnya.'
                              ),
                              const SizedBox(height: 20),

                              _buildSectionTitle('2. Layanan & Ekspektasi', primaryBlue),
                              _buildSectionContent(
                                  'Chupatu menyediakan layanan cuci, reparasi, dan restorasi sepatu premium. Kami berusaha memberikan hasil terbaik, namun hasil akhir sangat bergantung pada kondisi awal, usia, dan bahan sepatu Anda. Noda membandel yang sudah meresap (seperti tinta atau getah) mungkin tidak bisa 100% hilang.'
                              ),
                              const SizedBox(height: 20),

                              _buildSectionTitle('3. Estimasi Waktu (Turnaround Time)', primaryBlue),
                              _buildSectionContent(
                                  'Waktu pengerjaan standar adalah 2-4 hari kerja tergantung jenis layanan. Keterlambatan dapat terjadi pada *peak season* (musim hujan/liburan) atau jika sepatu membutuhkan penanganan khusus.'
                              ),
                              const SizedBox(height: 20),

                              _buildSectionTitle('4. Layanan Antar-Jemput (Delivery)', primaryBlue),
                              _buildSectionContent(
                                  'Kami menyediakan layanan antar-jemput sesuai area cakupan. Pastikan Anda berada di lokasi saat kurir kami tiba. Kegagalan penjemputan/pengantaran akibat pelanggan tidak dapat dihubungi dapat dikenakan biaya tambahan.'
                              ),
                              const SizedBox(height: 20),

                              _buildSectionTitle('5. Tanggung Jawab & Kerusakan', primaryBlue),
                              _buildSectionContent(
                                  'Kami menangani sepatu Anda dengan sangat hati-hati. Namun, Chupatu tidak bertanggung jawab atas kerusakan yang diakibatkan oleh usia sepatu (seperti sol hancur/getas), cacat pabrik, atau material yang sudah lapuk sebelum proses pencucian.'
                              ),
                              const SizedBox(height: 20),

                              _buildSectionTitle('6. Garansi Cuci Ulang', primaryBlue),
                              _buildSectionContent(
                                  'Jika Anda merasa hasil cuci kurang maksimal karena kelalaian pihak kami, klaim garansi cuci ulang dapat dilakukan maksimal 1x24 jam setelah sepatu diterima, dengan menyertakan foto dan belum pernah dipakai keluar.'
                              ),
                              const SizedBox(height: 20),

                              _buildSectionTitle('7. Barang Tidak Diambil', primaryBlue),
                              _buildSectionContent(
                                  'Sepatu yang telah selesai dikerjakan namun tidak diklaim/diambil oleh pelanggan dalam waktu 30 hari sejak pemberitahuan selesai, bukan lagi menjadi tanggung jawab Chupatu, dan kami berhak menyumbangkan atau membuang barang tersebut.'
                              ),
                              const SizedBox(height: 20),

                              _buildSectionTitle('8. Pembayaran', primaryBlue),
                              _buildSectionContent(
                                  'Pembayaran dilakukan secara aman melalui aplikasi (Midtrans) atau Cash on Delivery (COD). Harga yang tertera adalah final. Layanan yang sudah berjalan tidak dapat dibatalkan atau di-refund.'
                              ),

                              const SizedBox(height: 40),
                              Center(
                                child: Text(
                                  'Terakhir Diperbarui: Oktober 2024',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                    fontStyle: FontStyle.italic,
                                  ),
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
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        content,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
          height: 1.6,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}