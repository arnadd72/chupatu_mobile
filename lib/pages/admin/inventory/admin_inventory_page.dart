import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/main.dart';
// IMPORT TEMA KACA
import 'package:chupatu_mobile/pages/admin/widgets/admin_glass_theme.dart';

class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  // Dummy Data Stok
  List<Map<String, dynamic>> inventory = [
    {'name': 'Sabun Sepatu (Liter)', 'stock': 2, 'unit': 'L', 'color': Colors.blue},
    {'name': 'Parfum Sepatu', 'stock': 12, 'unit': 'Btl', 'color': Colors.purple},
    {'name': 'Plastik Packing', 'stock': 45, 'unit': 'Pcs', 'color': Colors.orange},
    {'name': 'Sikat Kasar', 'stock': 8, 'unit': 'Pcs', 'color': Colors.brown},
    {'name': 'Cat Hitam', 'stock': 1, 'unit': 'Kaleng', 'color': Colors.black},
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Gudang & Stok", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textMain)),
                        Text("Monitor persediaan bahan baku.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                      ],
                    ),
                    // Tombol Tambah Barang (Glass Button)
                    Container(
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                          onPressed: (){
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Tambah Barang (Coming Soon)")));
                          },
                          icon: Icon(Icons.add, color: theme.primary, size: 28)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // LIST BARANG
                Expanded(
                  child: ListView.separated(
                    itemCount: inventory.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = inventory[index];
                      return _buildStockCard(item, theme);
                    },
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  Widget _buildStockCard(Map<String, dynamic> item, AppThemeData theme) {
    bool isLowStock = item['stock'] <= 3; // Peringatan kalau stok <= 3

    return GlassCard(
      child: Row(
        children: [
          // Ikon Barang
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: item['color'].withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_rounded, color: item['color']),
          ),
          const SizedBox(width: 16),

          // Nama & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                if (isLowStock)
                  Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text("Stok Menipis!", style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))
                  )
                else
                  Text("Stok Aman", style: GoogleFonts.plusJakartaSans(color: Colors.green, fontSize: 12)),
              ],
            ),
          ),

          // Kontrol Plus Minus
          Container(
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2))
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18, color: Colors.grey),
                  onPressed: () => setState(() { if (item['stock'] > 0) item['stock']--; }),
                  constraints: const BoxConstraints(), // Biar icon button gak makan tempat
                  padding: const EdgeInsets.all(8),
                ),
                Text("${item['stock']} ${item['unit']}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                IconButton(
                  icon: Icon(Icons.add, size: 18, color: theme.primary),
                  onPressed: () => setState(() => item['stock']++),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}