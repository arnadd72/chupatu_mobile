import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart'; 
import 'package:chupatu_mobile/pages/order/booking_page.dart'; // Navigasi selanjutnya

class ServiceDetailPage extends StatelessWidget {
  final String serviceName;
  final int price;
  final String description;
  final String imageUrl; // Foto ilustrasi layanan

  const ServiceDetailPage({
    super.key,
    required this.serviceName,
    required this.price,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.background,
          body: Stack(
            children: [
              // --- GAMBAR HEADER (FULL SCREEN ATAS) ---
              Positioned(
                top: 0, left: 0, right: 0,
                height: 350,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
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
                      child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
                    ),
                    Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.share_rounded, size: 20)),
                  ],
                ),
              ),

              // --- KONTEN DETAIL (TIKET PUTIH DI BAWAH) ---
              Positioned(
                top: 300, bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GARIS INDIKATOR
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 24),
                      
                      // JUDUL & HARGA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(serviceName, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textMain))),
                          Text(currencyFormatter.format(price), style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: theme.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // RATING & REVIEW (DUMMY)
                      Row(children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text("4.8 (120 Reviews)", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time_rounded, color: Colors.blue, size: 18),
                        const SizedBox(width: 4),
                        Text("2-3 Hari", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                      ]),
                      const SizedBox(height: 24),

                      // DESKRIPSI
                      Text("Deskripsi Layanan", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            description,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey.shade600, height: 1.6),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // TOMBOL BOOKING
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // NAVIGASI KE BOOKING PAGE (BAWA DATA)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingPage(serviceName: serviceName, basePrice: price),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
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