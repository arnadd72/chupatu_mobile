import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👉 TAMBAHAN: Buat baca Firestore
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/order/booking_page.dart';
import 'package:chupatu_mobile/pages/order/custom_service_page.dart';
import 'package:chupatu_mobile/pages/home/review_rating_section.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ServiceDetailPage extends StatelessWidget {
  final String serviceName;
  final dynamic price;
  final String description;
  final String? imageUrl;

  const ServiceDetailPage({
    super.key,
    required this.serviceName,
    required this.price,
    required this.description,
    this.imageUrl,
  });

  // --- 1. LOGIKA GAMBAR HD OTOMATIS ---
  String _getSmartImage(String service) {
    String normalized = service.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
    
    if (normalized.contains('custom')) return 'assets/images/custom_sub.jpg';
    if (normalized.contains('deepclean')) return 'assets/images/deepclean_sub.webp';
    if (normalized.contains('fastclean')) return 'assets/images/fastclean_sub.avif';
    if (normalized.contains('unyellow')) return 'assets/images/unyellow_sub.jpg';
    if (normalized.contains('repair')) return 'assets/images/repair_sub.webp';
    if (normalized.contains('repaint')) return 'assets/images/repaint_sub.webp';
    if (normalized.contains('waterproof')) return 'assets/images/Waterproof_sub.webp';
    if (normalized.contains('pickup')) return 'assets/images/pickup_sub.jpg';
    
    return 'assets/images/custom_sub.jpg';
  }

  // --- 2. LOGIKA DESKRIPSI MARKETING ---
  String _getSmartDescription(String service) {
    String normalized = service.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');

    if (normalized.contains('custom')) {
      return "Layanan perawatan sepatu profesional yang fleksibel dan dapat disesuaikan dengan kebutuhan spesifik sepatu Anda.\n\nDi sini Anda dapat merakit dan menggabungkan beberapa layanan sekaligus (misal: Deep Clean + Waterproof). Klik tombol 'Pesan Sekarang' di bawah untuk mulai merakit paket layanan Anda sendiri!";
    }

    if (normalized.contains('deepclean')) return "Berikan perawatan terbaik untuk sepatu kesayanganmu! Layanan Deep Clean membersihkan debu, noda membandel, dan bakteri hingga ke pori-pori terdalam.\n\nCocok untuk semua bahan (Canvas, Suede, Leather, Nubuck). Hasilnya sepatu bersih total, wangi segar, dan higienis seperti baru kembali.";
    if (normalized.contains('fastclean')) return "Butuh sepatu bersih dadakan buat hangout atau meeting? Fast Clean solusinya! \n\nFokus pembersihan pada bagian Upper dan Midsole yang cepat namun tetap detail. Proses kilat, sepatu langsung glowing dan siap diajak jalan lagi dalam waktu singkat.";
    if (normalized.contains('unyellow')) return "Midsole sepatu menguning bikin gak pede? Jangan dibuang dulu! \n\nTeknik Unyellowing kami ampuh menghilangkan noda oksidasi membandel yang bikin sepatu terlihat kusam. Kami kembalikan warna putih cerah pada sol sepatumu, bikin tampilannya fresh lagi seperti baru beli.";
    if (normalized.contains('repair')) return "Sol sepatu mangap atau jebol saat dipakai? Tenang, serahkan pada ahlinya!\n\nKami melakukan Reglue (pengeleman ulang) dengan lem standar pabrik yang super kuat dan teknik press mesin. Sepatu tempur andalanmu bakal kokoh lagi, siap melangkah jauh tanpa khawatir rusak di jalan.";
    if (normalized.contains('repaint')) return "Warna sepatu pudar termakan usia? Atau bosan dengan warna lama?\n\nLayanan Repaint kami menggunakan cat premium anti-luntur/crack. Bisa kembalikan warna asli agar tajam kembali, atau ganti warna total (Custom Color) sesuai kepribadianmu. Finishing presisi dan tahan lama.";
    if (normalized.contains('waterproof')) return "Lindungi investasimu! Lapisan Nano-Coating transparan yang memberikan efek daun talas pada sepatu.\n\nAir, kopi, saus, atau lumpur gak bakal nempel! Melindungi bahan sepatu dari noda cair agar lebih awet, mudah dibersihkan, dan tetap bernapas. Wajib buat sneakers mahal!";
    if (normalized.contains('pickup')) return "Males keluar rumah macet-macetan? Biar kurir kami yang jemput sepatumu!\n\nLayanan antar-jemput gratis untuk area tertentu dengan minimal transaksi. Kurir ramah, amanah, dan tepat waktu. Kamu cukup duduk manis, sepatu kotor dijemput, pulang-pulang sudah bersih kinclong.";

    return "Layanan perawatan sepatu profesional dengan teknik khusus, bahan pembersih premium, dan peralatan modern untuk memberikan hasil maksimal pada setiap pasang sepatu Anda. Kepuasan pelanggan adalah prioritas utama kami.";
  }

  // --- 3. HELPER HARGA ---
  String _getDisplayPrice() {
    if (price is int) {
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      return formatter.format(price);
    }
    return price.toString();
  }

  int _getIntPrice() {
    if (price is int) return price;
    String str = price.toString();
    if (str.toLowerCase().contains("gratis")) return 0;
    return int.tryParse(str.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final String finalImage = _getSmartImage(serviceName);
    final String finalDescription = _getSmartDescription(serviceName);
    final String displayTitle = serviceName.toLowerCase().contains('custom') ? 'Custom Perawatan' : serviceName;

    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.background,
          body: Stack(
            children: [
              // --- GAMBAR HEADER ---
              Positioned(
                top: 0, left: 0, right: 0,
                height: 400,
                child: Image.asset(
                  finalImage,
                  fit: BoxFit.cover,
                  errorBuilder: (c,e,s) => Container(color: Colors.grey.shade300, child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
                ),
              ),

              // --- TOMBOL BACK ---
              Positioned(
                top: 50, left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6.0), // Nyesuain biar panahnya center
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black),
                    ),
                  ),
                ),
              ),

              // --- KONTEN DETAIL ---
              Positioned(
                top: 330, bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 24),

                      // JUDUL & HARGA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(displayTitle, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textMain))),
                          const SizedBox(width: 10),
                          Text(serviceName.toLowerCase().contains('custom') ? 'Mulai Rp 30rb' : _getDisplayPrice(), style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: theme.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 👉 PERUBAHAN: RATING DINAMIS DARI FIRESTORE
                      Row(
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('reviews')
                                  .where('serviceName', isEqualTo: serviceName)
                                  .snapshots(),
                              builder: (context, snapshot) {

                                // Kondisi 1: Loading
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                      const SizedBox(width: 4),
                                      Text("Menghitung...", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
                                    ],
                                  );
                                }

                                // Kondisi 2: Kosong (Belum ada review)
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return Row(
                                    children: [
                                      Icon(Icons.star_outline_rounded, color: Colors.grey.shade400, size: 20),
                                      const SizedBox(width: 4),
                                      Text("Belum ada ulasan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey.shade400, fontSize: 13)),
                                    ],
                                  );
                                }

                                // Kondisi 3: Ada Review (Hitung rata-rata)
                                int totalReviews = snapshot.data!.docs.length;
                                double totalRating = 0;

                                for (var doc in snapshot.data!.docs) {
                                  var data = doc.data() as Map<String, dynamic>;
                                  totalRating += (data['rating'] ?? 5);
                                }

                                double averageRating = totalRating / totalReviews;

                                // Tombol Review yang bisa di-klik
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AllReviewsPage(serviceName: serviceName)), // PANGGIL CLASS LO DI SINI
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.amber.withOpacity(0.5))
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                            "${averageRating.toStringAsFixed(1)} ($totalReviews Ulasan) >",
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.amber.shade700, fontSize: 12)
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 16),
                            const Icon(Icons.access_time_rounded, color: Colors.blueAccent, size: 18),
                            const SizedBox(width: 4),
                            Text("2-3 Hari", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
                          ]
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      Text("Deskripsi Layanan", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                      const SizedBox(height: 8),

                      // DESKRIPSI MARKETING
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            finalDescription,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: theme.textMain.withOpacity(0.7), height: 1.6),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TOMBOL PESAN
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (serviceName.toLowerCase().contains('custom')) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CustomServicePage()),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingPage(
                                    serviceName: serviceName,
                                    basePrice: _getIntPrice(),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: theme.primary.withOpacity(0.4),
                          ),
                          child: Text("Pesan Sekarang", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}