import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationDetailPage extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final String type; // 'promo' atau 'order'

  const NotificationDetailPage({
    super.key,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor = type == 'promo' ? Colors.orange : Colors.blue;
    IconData typeIcon = type == 'promo' ? Icons.discount_rounded : Icons.local_shipping_rounded;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Detail Info", style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Ikon Besar
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, color: typeColor, size: 40),
              ),
            ),
            const SizedBox(height: 24),

            // Waktu
            Text(time, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),

            // Judul
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Isi Pesan
            Text(
              body,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.grey.shade700, height: 1.5),
            ),

            const Spacer(),

            // Tombol Aksi (Misal Promo)
            if (type == 'promo')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Disini bisa diarahkan ke halaman Booking
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Gunakan Promo Sekarang", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}