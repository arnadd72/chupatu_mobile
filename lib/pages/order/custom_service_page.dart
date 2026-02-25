import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart'; // Import tema
import 'package:chupatu_mobile/pages/order/booking_page.dart'; // Pastikan path BookingPage ini benar ya Bos

class CustomServicePage extends StatefulWidget {
  const CustomServicePage({super.key});

  @override
  State<CustomServicePage> createState() => _CustomServicePageState();
}

class _CustomServicePageState extends State<CustomServicePage> {
  // Menyimpan layanan yang diceklis user
  List<Map<String, dynamic>> _selectedServices = [];
  int _totalPrice = 0;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Fungsi saat user klik salah satu layanan
  void _toggleService(Map<String, dynamic> service) {
    setState(() {
      final int index = _selectedServices.indexWhere((s) => s['id'] == service['id']);

      if (index >= 0) {
        // Jika sudah ada, hapus dari list (Uncheck)
        _selectedServices.removeAt(index);
        _totalPrice -= (service['price'] as int);
      } else {
        // Jika belum ada, tambahkan ke list (Check)
        _selectedServices.add(service);
        _totalPrice += (service['price'] as int);
      }
    });
  }

  // --- INI FUNGSI YANG SEMPAT HILANG BOS ---
  // Fungsi untuk lanjut ke halaman Order (BookingPage)
  void _proceedToOrder() {
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih minimal 1 layanan terlebih dahulu!")),
      );
      return;
    }

    // Gabungkan nama layanan yang dipilih (Misal: Deep Clean + Waterproof)
    String combinedNames = _selectedServices.map((s) => s['name']).join(' + ');

    // Arahkan ke halaman BookingPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(
          // Sesuaikan parameter ini kalau di BookingPage butuh data lain
          serviceName: "Custom: $combinedNames",
          basePrice: _totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text("Custom Perawatan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              backgroundColor: theme.surface,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pilih Paketmu Sendiri 🛠️", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textMain)),
                      const SizedBox(height: 8),
                      Text("Pilih satu atau lebih layanan yang sepatu Anda butuhkan.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                    ],
                  ),
                ),

                // LIST LAYANAN DARI FIRESTORE
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('services').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("Belum ada layanan tersedia."));
                      }

                      var docs = snapshot.data!.docs;

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: docs.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;

                          Map<String, dynamic> serviceData = {
                            'id': docs[index].id,
                            'name': data['name'] ?? 'Layanan',
                            'price': data['price'] ?? 0,
                          };

                          bool isSelected = _selectedServices.any((s) => s['id'] == serviceData['id']);

                          return GestureDetector(
                            onTap: () => _toggleService(serviceData),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: isSelected ? theme.primary.withOpacity(0.1) : theme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? theme.primary : Colors.grey.withOpacity(0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)
                                  ]
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected ? theme.primary : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isSelected ? theme.primary : Colors.grey),
                                    ),
                                    child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                  ),
                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(serviceData['name'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)),
                                        const SizedBox(height: 4),
                                        Text(currencyFormatter.format(serviceData['price']), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // BOTTOM BAR: TOTAL HARGA & TOMBOL LANJUT
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Total Biaya", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                            Text(
                              currencyFormatter.format(_totalPrice),
                              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primary),
                            ),
                            Text("${_selectedServices.length} Layanan dipilih", style: GoogleFonts.plusJakartaSans(fontSize: 10, color: theme.textMain)),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _proceedToOrder, // <-- SEKARANG SUDAH AMAN!
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text("Lanjut", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        }
    );
  }
}