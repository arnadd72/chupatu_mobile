import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';
// IMPORT HALAMAN HISTORY
import 'package:chupatu_mobile/pages/admin/inventory/inventory_history_page.dart';

class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {

  // --- FUNGSI TAMBAH BARANG BARU ---
  void _showAddDialog(BuildContext context, AppThemeData theme) {
    final nameCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final unitCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface, // Background adaptif
        title: Text("Tambah Barang", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                style: TextStyle(color: theme.textMain),
                decoration: InputDecoration(
                  labelText: "Nama Barang (ex: Sabun)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                )
            ),
            TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.textMain),
                decoration: InputDecoration(
                  labelText: "Stok Awal",
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                )
            ),
            TextField(
                controller: unitCtrl,
                style: TextStyle(color: theme.textMain),
                decoration: InputDecoration(
                  labelText: "Satuan (ex: Pcs, Liter)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && stockCtrl.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('inventory').add({
                  'name': nameCtrl.text,
                  'stock': int.parse(stockCtrl.text),
                  'unit': unitCtrl.text,
                  'color': 'blue',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if(mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white),
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  // --- FUNGSI UPDATE STOK (+/-) ---
  Future<void> _updateStock(String docId, String name, int currentStock, int change) async {
    int newStock = currentStock + change;
    if (newStock < 0) return;

    await FirebaseFirestore.instance.collection('inventory').doc(docId).update({
      'stock': newStock
    });

    await FirebaseFirestore.instance.collection('inventory_logs').add({
      'itemName': name,
      'amount': change.abs(),
      'type': change > 0 ? 'in' : 'out',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Helper Custom Card (Pengganti GlassCard)
  Widget _buildSolidCard({required Widget child, required AppThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: child,
    );
  }

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
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Gudang & Stok", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textMain)),
                        Text("Monitor bahan baku.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                      ],
                    ),
                    Row(
                      children: [
                        // Tombol History
                        IconButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryHistoryPage())),
                          icon: const Icon(Icons.history_rounded, color: Colors.grey),
                          tooltip: "Riwayat Stok",
                        ),
                        // Tombol Tambah
                        Container(
                          decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), shape: BoxShape.circle),
                          child: IconButton(
                              onPressed: () => _showAddDialog(context, theme), // Kirim theme ke dialog
                              icon: Icon(Icons.add, color: theme.primary, size: 28)
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // LIST BARANG (REALTIME)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('inventory').orderBy('name').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text("Gudang Kosong", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
                      }

                      var docs = snapshot.data!.docs;

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          return _buildStockCard(docs[index].id, data, theme);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  Widget _buildStockCard(String docId, Map<String, dynamic> item, AppThemeData theme) {
    int stock = item['stock'] ?? 0;
    bool isLowStock = stock <= 3;

    Color itemColor = Colors.blue;
    if (item['color'] == 'purple') itemColor = Colors.purple;
    if (item['color'] == 'orange') itemColor = Colors.orange;

    return _buildSolidCard( // PERUBAHAN: Pakai SolidCard
      theme: theme,
      child: Row(
        children: [
          // Ikon Barang
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: itemColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_rounded, color: itemColor),
          ),
          const SizedBox(width: 16),

          // Nama & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? 'Item', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)), // Warna adaptif
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
                color: theme.background, // PERUBAHAN: Background tombol +/-
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2))
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18, color: Colors.grey),
                  onPressed: () => _updateStock(docId, item['name'], stock, -1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                Text("$stock ${item['unit'] ?? ''}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain)), // Warna teks adaptif
                IconButton(
                  icon: Icon(Icons.add, size: 18, color: theme.primary),
                  onPressed: () => _updateStock(docId, item['name'], stock, 1),
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