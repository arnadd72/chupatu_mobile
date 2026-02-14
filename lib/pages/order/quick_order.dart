import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // WAJIB: Import Firestore
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/pages/order/booking_page.dart';

class QuickOrder extends StatelessWidget {
  const QuickOrder({super.key});

  // --- FUNGSI 1: TAMPILKAN PILIHAN UTAMA (DARI FIREBASE) ---
  void _showServiceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),

              Text("Pilih Layanan", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // --- AMBIL DATA DARI FIREBASE ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('services').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    // 1. Loading State
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // 2. Empty State
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("Belum ada layanan tersedia", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
                    }

                    var allDocs = snapshot.data!.docs;

                    // LOGIKA: Jika layanan > 6, kita tampilkan 5 + Tombol "Lainnya"
                    // Jika layanan <= 6, kita tampilkan semua
                    bool showMoreButton = allDocs.length > 6;
                    int itemCount = showMoreButton ? 6 : allDocs.length;

                    return GridView.builder(
                      itemCount: itemCount,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4, // Sedikit lebih kotak biar muat gambar
                      ),
                      itemBuilder: (context, index) {
                        // LOGIKA TOMBOL "LAINNYA" (Index ke-5 jika data banyak)
                        if (showMoreButton && index == 5) {
                          return InkWell(
                            onTap: () {
                              Navigator.pop(context); // Tutup sheet ini
                              // Kirim sisa data (mulai dari index 5 ke atas) ke fungsi berikutnya
                              _showMoreServices(context, allDocs.sublist(5));
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.grid_view_rounded, size: 32, color: Colors.black87),
                                  const SizedBox(height: 8),
                                  Text("Lainnya", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text("${allDocs.length - 5} lagi", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          );
                        }

                        // TAMPILKAN KARTU LAYANAN
                        var data = allDocs[index].data() as Map<String, dynamic>;
                        return _buildServiceCard(context, data);
                      },
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- FUNGSI 2: TAMPILKAN SISA LAYANAN ---
  void _showMoreServices(BuildContext context, List<QueryDocumentSnapshot> remainingDocs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),

              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () {
                      Navigator.pop(context);
                      _showServiceSelector(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text("Layanan Lainnya", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: GridView.builder(
                  itemCount: remainingDocs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, index) {
                    var data = remainingDocs[index].data() as Map<String, dynamic>;
                    return _buildServiceCard(context, data);
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET KARTU LAYANAN DINAMIS ---
  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> data) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String name = data['name'] ?? 'Layanan';
    int price = data['price'] ?? 0;
    String? imageUrl = data['imageUrl']; // URL Foto dari Firebase Storage

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Tutup Sheet
        // Tutup Quick Order Dialog Awal (Jika ada) - Opsional, tergantung struktur navigasi
        // Navigator.pop(context);

        // Masuk Booking Page dengan Data Database
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingPage(
              serviceName: name,
              basePrice: price,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GAMBAR / IKON
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  image: (imageUrl != null && imageUrl.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null
              ),
              // Jika tidak ada gambar, tampilkan ikon default
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? Icon(Icons.local_laundry_service_rounded, size: 28, color: Colors.blue.shade700)
                  : null,
            ),
            const SizedBox(height: 12),

            // TEKS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
                price == 0 ? "Tanya Admin" : currencyFormatter.format(price),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI KAMERA (TETAP) ---
  Future<void> _openCamera(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Foto berhasil diambil: ${photo.name}"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),

          Text("Mau layanan apa bos?", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),

          // MENU 1: BOOKING ORDER (Buka Sheet Layanan Dinamis)
          _buildMenuItem(
            context,
            icon: Icons.add_circle_outline_rounded,
            title: "Booking Order",
            subtitle: "Pilih layanan manual.",
            color: Colors.blueAccent,
            onTap: () {
              Navigator.pop(context); // Tutup dialog awal biar ga numpuk
              _showServiceSelector(context); // Buka selector layanan
            },
          ),

          const SizedBox(height: 12),

          // MENU 2: KAMERA
          _buildMenuItem(
            context,
            icon: Icons.camera_alt_outlined,
            title: "Cek Kondisi (AI)",
            subtitle: "Foto sepatu, biar kami analisa.",
            color: Colors.purpleAccent,
            onTap: () => _openCamera(context),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 4), Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600))])),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}