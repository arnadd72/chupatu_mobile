import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart';
// IMPORT TEMA KACA (Pastikan path import ini sesuai)
import 'package:chupatu_mobile/pages/admin/widgets/admin_glass_theme.dart';

class AdminPOSPage extends StatefulWidget {
  const AdminPOSPage({super.key});

  @override
  State<AdminPOSPage> createState() => _AdminPOSPageState();
}

class _AdminPOSPageState extends State<AdminPOSPage> {
  // Dummy Data Layanan
  final List<Map<String, dynamic>> services = [
    {'name': 'Deep Clean', 'price': 35000, 'icon': Icons.cleaning_services},
    {'name': 'Fast Clean', 'price': 25000, 'icon': Icons.timer},
    {'name': 'Unyellowing', 'price': 50000, 'icon': Icons.wb_sunny},
    {'name': 'Repaint', 'price': 120000, 'icon': Icons.format_paint},
    {'name': 'Repair', 'price': 45000, 'icon': Icons.build},
    {'name': 'Leather Care', 'price': 60000, 'icon': Icons.favorite},
  ];

  Map<String, dynamic>? selectedService;
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Kasir (Walk-in)", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textMain)),
                const SizedBox(height: 8),
                Text("Input pesanan pelanggan yang datang langsung.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                const SizedBox(height: 20),

                // 1. INPUT NAMA PELANGGAN (GLASS STYLE)
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      icon: Icon(Icons.person_outline, color: theme.primary),
                      hintText: "Nama Pelanggan (Contoh: Budi)",
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. GRID PILIH LAYANAN
                Expanded(
                  child: GridView.builder(
                    itemCount: services.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final item = services[index];
                      bool isSelected = selectedService == item;

                      return GestureDetector(
                        onTap: () => setState(() => selectedService = item),
                        child: GlassCard( // KARTU LAYANAN KACA
                          padding: EdgeInsets.zero, // Reset padding biar custom
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isSelected ? theme.primary.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected ? Border.all(color: theme.primary, width: 2) : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(item['icon'], size: 32, color: isSelected ? theme.primary : Colors.grey),
                                const SizedBox(height: 8),
                                Text(item['name'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: isSelected ? theme.primary : Colors.black87)),
                                Text(currencyFormatter.format(item['price']), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 3. TOMBOL PROSES (TOTAL)
                const SizedBox(height: 20),
                if (selectedService != null)
                  GlassCard(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Bayar", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54)),
                            Text(
                              currencyFormatter.format(selectedService!['price']),
                              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primary),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            if (_nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi nama pelanggan dulu!")));
                              return;
                            }
                            // Disini logika simpan ke Firebase (Future Development)
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pesanan ${selectedService!['name']} utk ${_nameController.text} Berhasil Dibuat!")));

                            // Reset Form
                            setState(() {
                              selectedService = null;
                              _nameController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Buat Order", style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          );
        }
    );
  }
}