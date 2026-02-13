import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chupatu_mobile/pages/order/booking_page.dart';

class QuickOrder extends StatelessWidget {
  const QuickOrder({super.key});

  // --- DATA LENGKAP SEMUA LAYANAN (Total 8) ---
  final List<Map<String, dynamic>> _allServices = const [
    {'name': 'Deep Clean', 'price': 35000, 'icon': Icons.water_drop_rounded, 'color': Colors.blue},
    {'name': 'Fast Clean', 'price': 25000, 'icon': Icons.timer_rounded, 'color': Colors.orange},
    {'name': 'Unyellowing', 'price': 50000, 'icon': Icons.wb_sunny_rounded, 'color': Colors.amber},
    {'name': 'Repair', 'price': 60000, 'icon': Icons.build_rounded, 'color': Colors.grey},
    {'name': 'Repaint', 'price': 120000, 'icon': Icons.format_paint_rounded, 'color': Colors.purple},
    // --- Batas 5 Teratas ---
    {'name': 'Waterproof', 'price': 40000, 'icon': Icons.umbrella_rounded, 'color': Colors.teal},
    {'name': 'Custom', 'price': 0, 'icon': Icons.edit_note_rounded, 'color': Colors.pink}, // Harga 0 = Tanya Admin
    {'name': 'Pickup', 'price': 15000, 'icon': Icons.delivery_dining_rounded, 'color': Colors.green},
  ];

  // --- FUNGSI 1: TAMPILKAN PILIHAN UTAMA (5 + LAINNYA) ---
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

              Text("Pilih Layanan Dulu", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Expanded(
                child: GridView.builder(
                  itemCount: 6, // Kita paksa cuma 6 slot (5 Layanan + 1 Tombol Lainnya)
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    // LOGIKA SLOT KE-6 (POJOK KANAN BAWAH)
                    if (index == 5) {
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context); // Tutup sheet ini dulu
                          _showMoreServices(context); // Buka sheet "Lainnya"
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
                              Text("Lihat semua", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      );
                    }

                    // TAMPILKAN 5 LAYANAN PERTAMA
                    final service = _allServices[index];
                    return _buildServiceCard(context, service);
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- FUNGSI 2: TAMPILKAN SISA LAYANAN (YANG DISEMBUNYIKAN) ---
  void _showMoreServices(BuildContext context) {
    // Ambil sisa layanan mulai dari index ke-5 sampai habis
    final List<Map<String, dynamic>> remainingServices = _allServices.sublist(5);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5, // Gak perlu terlalu tinggi
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
                      Navigator.pop(context); // Tutup sheet ini
                      _showServiceSelector(context); // Balik ke menu utama
                    },
                  ),
                  const SizedBox(width: 8),
                  Text("Layanan Lainnya", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: GridView.builder(
                  itemCount: remainingServices.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    return _buildServiceCard(context, remainingServices[index]);
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET KARTU LAYANAN (Supaya gak ngetik ulang) ---
  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Tutup Service Picker
        Navigator.pop(context); // Tutup Quick Order Menu Awal

        // Masuk Booking Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingPage(
              serviceName: service['name'],
              basePrice: service['price'],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: (service['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (service['color'] as Color).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(service['icon'], size: 32, color: service['color']),
            const SizedBox(height: 8),
            Text(service['name'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(
                service['price'] == 0 ? "Hubungi Admin" : "Rp ${service['price']}",
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade700)
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI KAMERA (SAMA SEPERTI SEBELUMNYA) ---
  Future<void> _openCamera(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      Navigator.pop(context);
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

          _buildMenuItem(
            context,
            icon: Icons.add_circle_outline_rounded,
            title: "Booking Order",
            subtitle: "Pilih layanan manual.",
            color: Colors.blueAccent,
            onTap: () => _showServiceSelector(context),
          ),

          const SizedBox(height: 12),

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