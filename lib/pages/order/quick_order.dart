import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/pages/order/booking_page.dart';

class QuickOrder extends StatelessWidget {
  const QuickOrder({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      width: double.infinity,
      // Proteksi tinggi maksimal biar nggak tembus layar
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garis Handle Bottom Sheet
          Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text("Pilih Layanan Chupatu",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          Text("Pilih layanan perawatan sepatu terbaik untukmu.",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),

          // Pake Flexible biar List bisa di-scroll dengan aman
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("Belum ada layanan.")));
                }

                var services = snapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: services.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    var data = services[index].data() as Map<String, dynamic>;
                    String name = data['name'] ?? 'Layanan';
                    int price = data['price'] ?? 0;

                    // AMBIL URL GAMBAR DARI FIRESTORE
                    String imageUrl = data['imageUrl'] ?? '';

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context); // Tutup bottom sheet
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BookingPage(
                                    serviceName: name, basePrice: price)));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8)
                            ]),
                        child: Row(
                          children: [
                            // GAMBAR LAYANAN DENGAN PROTEKSI ERROR
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                  imageUrl,
                                  width: 70, height: 70, fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) =>
                                      _buildPlaceholder())
                                  : _buildPlaceholder(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black87)),
                                      const SizedBox(height: 6),
                                      Text(currencyFormatter.format(price),
                                          style: GoogleFonts.plusJakartaSans(
                                              color: Colors.blueAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                    ])),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 16, color: Colors.grey.shade300)
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Widget bantuan kalau gambar kosong/gagal dimuat
  Widget _buildPlaceholder() {
    return Container(
        width: 70, height: 70,
        color: Colors.blueAccent.withOpacity(0.1),
        child: const Icon(Icons.cleaning_services_rounded,
            color: Colors.blueAccent));
  }
}