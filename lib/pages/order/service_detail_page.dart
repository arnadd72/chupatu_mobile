import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/order/booking_page.dart';

class ServiceDetailPage extends StatelessWidget {
  final String serviceName;
  final dynamic price;
  final String description; // Kita terima, tapi nanti kita timpa dengan yang lebih bagus
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
    switch (service.toLowerCase()) {
      case 'deep clean': return 'https://images.unsplash.com/photo-1600185365926-3a6d3de3dddb?auto=format&fit=crop&q=80&w=1000';
      case 'fast clean': return 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?auto=format&fit=crop&q=80&w=1000';
      case 'unyellowing': return 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?auto=format&fit=crop&q=80&w=1000';
      case 'repair': return 'https://images.unsplash.com/photo-1581102854955-455b8045a557?auto=format&fit=crop&q=80&w=1000';
      case 'repaint': return 'https://images.unsplash.com/photo-1552346154-21d32810aba3?auto=format&fit=crop&q=80&w=1000';
      case 'waterproof': return 'https://images.unsplash.com/photo-1543508282-6319a3e2621f?auto=format&fit=crop&q=80&w=1000';
      case 'custom': return 'https://images.unsplash.com/photo-1515955656352-a1fa3ffcd111?auto=format&fit=crop&q=80&w=1000';
      case 'pickup': return 'https://images.unsplash.com/photo-1616406432452-07bc59280cd3?auto=format&fit=crop&q=80&w=1000';
      default: return 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&q=80&w=1000';
    }
  }

  // --- 2. LOGIKA DESKRIPSI MARKETING (BARU) ---
  String _getSmartDescription(String service) {
    switch (service.toLowerCase()) {
      case 'deep clean':
        return "Berikan perawatan terbaik untuk sepatu kesayanganmu! Layanan Deep Clean membersihkan debu, noda membandel, dan bakteri hingga ke pori-pori terdalam.\n\nCocok untuk semua bahan (Canvas, Suede, Leather, Nubuck). Hasilnya sepatu bersih total, wangi segar, dan higienis seperti baru kembali.";

      case 'fast clean':
        return "Butuh sepatu bersih dadakan buat hangout atau meeting? Fast Clean solusinya! \n\nFokus pembersihan pada bagian Upper dan Midsole yang cepat namun tetap detail. Proses kilat, sepatu langsung glowing dan siap diajak jalan lagi dalam waktu singkat.";

      case 'unyellowing':
        return "Midsole sepatu menguning bikin gak pede? Jangan dibuang dulu! \n\nTeknik Unyellowing kami ampuh menghilangkan noda oksidasi membandel yang bikin sepatu terlihat kusam. Kami kembalikan warna putih cerah pada sol sepatumu, bikin tampilannya fresh lagi seperti baru beli.";

      case 'repair':
        return "Sol sepatu mangap atau jebol saat dipakai? Tenang, serahkan pada ahlinya!\n\nKami melakukan Reglue (pengeleman ulang) dengan lem standar pabrik yang super kuat dan teknik press mesin. Sepatu tempur andalanmu bakal kokoh lagi, siap melangkah jauh tanpa khawatir rusak di jalan.";

      case 'repaint':
        return "Warna sepatu pudar termakan usia? Atau bosan dengan warna lama?\n\nLayanan Repaint kami menggunakan cat premium anti-luntur/crack. Bisa kembalikan warna asli agar tajam kembali, atau ganti warna total (Custom Color) sesuai kepribadianmu. Finishing presisi dan tahan lama.";

      case 'waterproof':
        return "Lindungi investasimu! Lapisan Nano-Coating transparan yang memberikan efek daun talas pada sepatu.\n\nAir, kopi, saus, atau lumpur gak bakal nempel! Melindungi bahan sepatu dari noda cair agar lebih awet, mudah dibersihkan, dan tetap bernapas. Wajib buat sneakers mahal!";

      case 'custom':
        return "Ekspresikan gayamu! Jasa lukis sepatu custom oleh artist berpengalaman.\n\nBisa request gambar karakter, pola abstrak, atau tulisan nama. Menggunakan cat khusus yang fleksibel dan tidak pecah. Bikin sepatumu jadi satu-satunya di dunia (Limited Edition punya kamu sendiri!).";

      case 'pickup':
        return "Males keluar rumah macet-macetan? Biar kurir kami yang jemput sepatumu!\n\nLayanan antar-jemput gratis untuk area tertentu dengan minimal transaksi. Kurir ramah, amanah, dan tepat waktu. Kamu cukup duduk manis, sepatu kotor dijemput, pulang-pulang sudah bersih kinclong.";

      default:
        return "Layanan perawatan sepatu profesional dengan teknik khusus, bahan pembersih premium, dan peralatan modern untuk memberikan hasil maksimal pada setiap pasang sepatu Anda. Kepuasan pelanggan adalah prioritas utama kami.";
    }
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

    // PANGGIL DESKRIPSI MARKETING DISINI
    final String finalDescription = _getSmartDescription(serviceName);

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
                child: Image.network(
                  finalImage,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator()));
                  },
                  errorBuilder: (c,e,s) => Container(color: Colors.grey.shade300, child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
                ),
              ),

              // --- TOMBOL BACK & SHARE ---
              Positioned(
                top: 50, left: 20, right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black),
                      ),
                    ),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
                      child: const Icon(Icons.share_rounded, size: 20, color: Colors.black),
                    ),
                  ],
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
                          Expanded(child: Text(serviceName, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textMain))),
                          const SizedBox(width: 10),
                          Text(_getDisplayPrice(), style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: theme.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // RATING
                      Row(children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text("4.8 (120 Reviews)", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time_rounded, color: Colors.blueAccent, size: 18),
                        const SizedBox(width: 4),
                        Text("2-3 Hari", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
                      ]),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      Text("Deskripsi Layanan", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                      const SizedBox(height: 8),

                      // DESKRIPSI MARKETING DISINI
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            finalDescription, // <-- Pakai teks marketing kita
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
                            int intPrice = _getIntPrice();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingPage(serviceName: serviceName, basePrice: intPrice),
                              ),
                            );
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