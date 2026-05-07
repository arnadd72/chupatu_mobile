import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // TAMBAHAN: Untuk Format Rupiah
import 'package:chupatu_mobile/main.dart';
// IMPORT HALAMAN HISTORY
import 'package:chupatu_mobile/pages/admin/inventory/inventory_history_page.dart';

class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  // Bikin formatter rupiah ala korporat
  final _formatter = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0
  );

  // ==========================================================
  // 1. SMART FORM: BISA UNTUK TAMBAH (CREATE) & EDIT (UPDATE)
  // ==========================================================
  void _showInventorySheet(BuildContext context, AppThemeData theme, {
    String? docId,
    Map<String, dynamic>? existingData
  }) {
    final nameCtrl = TextEditingController(text: existingData?['name'] ?? '');
    final stockCtrl = TextEditingController(
        text: existingData != null ? existingData['stock'].toString() : ''
    );
    final unitCtrl = TextEditingController(text: existingData?['unit'] ?? '');

    // TAMBAHAN: Controller buat nangkep Harga Beli
    final priceCtrl = TextEditingController(
        text: existingData != null ? (existingData['purchasePrice']?.toString() ?? '') : ''
    );

    // Default color biru, kalau edit pakai warna yang ada
    String selectedColor = existingData?['color'] ?? 'blue';

    bool isEditMode = docId != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20
              ),
              decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24))
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2)
                          )
                      )
                  ),
                  const SizedBox(height: 20),
                  Text(
                      isEditMode ? "Edit Barang" : "Tambah Barang",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain
                      )
                  ),
                  const SizedBox(height: 20),

                  // TEXTFIELDS
                  TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: theme.textMain),
                      decoration: _inputDecoration(theme, "Nama Barang (ex: Sabun)")
                  ),
                  const SizedBox(height: 12),

                  // TAMBAHAN: INPUT HARGA BELI
                  TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.textMain),
                      decoration: _inputDecoration(theme, "Harga Beli per Satuan (Rp)")
                  ),
                  const SizedBox(height: 12),

                  // Kalau edit, stok mending di-disable dari form ini
                  // biar admin pakai tombol +/- aja untuk akurasi log.
                  TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      enabled: !isEditMode, // Kunci jika mode edit
                      style: TextStyle(color: !isEditMode ? theme.textMain : Colors.grey),
                      decoration: _inputDecoration(
                          theme,
                          isEditMode ? "Stok (Gunakan tombol +/- di luar)" : "Stok Awal"
                      )
                  ),
                  const SizedBox(height: 12),

                  TextField(
                      controller: unitCtrl,
                      style: TextStyle(color: theme.textMain),
                      decoration: _inputDecoration(theme, "Satuan (ex: Pcs, Liter)")
                  ),
                  const SizedBox(height: 20),

                  // PILIH WARNA IKON BIAR NGGAK BURIK
                  Text(
                      "Pilih Warna Label",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey
                      )
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: ['blue', 'purple', 'orange', 'green', 'red'].map((colorStr) {
                      Color c = _getColorFromString(colorStr);
                      bool isSelected = selectedColor == colorStr;
                      return GestureDetector(
                        onTap: () => setStateSheet(() => selectedColor = colorStr),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isSelected ? c : Colors.transparent,
                                  width: 2
                              )
                          ),
                          child: CircleAvatar(backgroundColor: c, radius: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // TOMBOL SIMPAN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty) return;

                        final payload = {
                          'name': nameCtrl.text.trim(),
                          'unit': unitCtrl.text.trim(),
                          // SIMPAN HARGA BELI JUGA
                          'purchasePrice': int.tryParse(priceCtrl.text) ?? 0,
                          'color': selectedColor,
                          'updatedAt': FieldValue.serverTimestamp(),
                        };

                        if (isEditMode) {
                          await FirebaseFirestore.instance
                              .collection('inventory')
                              .doc(docId)
                              .update(payload);
                        } else {
                          if (stockCtrl.text.isEmpty) return;
                          payload['stock'] = int.parse(stockCtrl.text);
                          payload['createdAt'] = FieldValue.serverTimestamp();

                          await FirebaseFirestore.instance
                              .collection('inventory')
                              .add(payload);
                        }

                        if (mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          )
                      ),
                      child: Text(
                          isEditMode ? "Update Barang" : "Simpan Barang",
                          style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                    ),
                  )
                ],
              ),
            );
          }
      ),
    );
  }

  // ==========================================================
  // 2. FITUR HAPUS BARANG (DENGAN PERINGATAN AMAN)
  // ==========================================================
  void _deleteItem(String docId, String name, AppThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text("Hapus $name?", style: TextStyle(color: theme.textMain)),
        content: Text(
            "Barang ini akan dihapus dari gudang secara permanen.",
            style: TextStyle(color: theme.textMain)
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('inventory')
                  .doc(docId).delete();

              if(mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$name berhasil dihapus."))
              );
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI UPDATE STOK (MODIFIKASI BAWA HARGA UNTUK LOG) ---
  // Kita ganti parameternya dari nerima nama & stock aja, jadi nerima FULL map "item"
  Future<void> _updateStock(String docId, Map<String, dynamic> item, int change) async {
    int currentStock = item['stock'] ?? 0;
    int purchasePrice = item['purchasePrice'] ?? 0;
    String name = item['name'] ?? 'Item';

    int newStock = currentStock + change;
    if (newStock < 0) return;

    // 1. Update stok terbaru di tabel master
    await FirebaseFirestore.instance.collection('inventory').doc(docId).update({
      'stock': newStock
    });

    // 2. Catat Log ke database lengkap dengan harga
    await FirebaseFirestore.instance.collection('inventory_logs').add({
      'itemName': name,
      'amount': change.abs(),
      'priceAtTime': purchasePrice, // Tracking Harga per satuan
      'totalCost': change.abs() * purchasePrice, // Total HPP / Pengeluaran
      'type': change > 0 ? 'in' : 'out',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // HELPER MAPPING WARNA BIAR ELEGAN
  Color _getColorFromString(String colorStr) {
    switch (colorStr) {
      case 'purple': return Colors.purple;
      case 'orange': return Colors.orange;
      case 'green': return Colors.teal;
      case 'red': return Colors.redAccent;
      default: return Colors.blue;
    }
  }

  InputDecoration _inputDecoration(AppThemeData theme, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12)
      ),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.primary),
          borderRadius: BorderRadius.circular(12)
      ),
      disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12)
      ),
    );
  }

  Widget _buildSolidCard({required Widget child, required AppThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)
          )
        ],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "Gudang & Stok",
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24, fontWeight: FontWeight.bold, color: theme.textMain
                              )
                          ),
                          Text(
                              "Monitor bahan baku operasional.",
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.grey, fontSize: 12
                              )
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const InventoryHistoryPage())
                          ),
                          icon: const Icon(Icons.history_rounded, color: Colors.grey),
                          tooltip: "Riwayat Stok",
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showInventorySheet(context, theme),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Tambah"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)
                              )
                          ),
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // LIST BARANG (REALTIME)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('inventory')
                        .orderBy('name').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                            child: Text(
                                "Gudang Kosong",
                                style: GoogleFonts.plusJakartaSans(color: Colors.grey)
                            )
                        );
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

  // ==========================================================
  // DESAIN CARD GUDANG YANG LEBIH PROFESIONAL
  // ==========================================================
  Widget _buildStockCard(String docId, Map<String, dynamic> item, AppThemeData theme) {
    String name = item['name'] ?? 'Item';
    int stock = item['stock'] ?? 0;
    String unit = item['unit'] ?? '';
    int purchasePrice = item['purchasePrice'] ?? 0; // Tarik Data Harga

    bool isLowStock = stock <= 3;

    Color itemColor = _getColorFromString(item['color'] ?? 'blue');

    return _buildSolidCard(
      theme: theme,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon Barang
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.1),
                    shape: BoxShape.circle
                ),
                child: Icon(Icons.inventory_2_rounded, color: itemColor),
              ),
              const SizedBox(width: 16),

              // Nama, Harga Beli, & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain
                        )
                    ),
                    const SizedBox(height: 2),
                    // Tampilkan Harga Beli Disini
                    Text(
                        "Harga Beli: ${_formatter.format(purchasePrice)}",
                        style: GoogleFonts.plusJakartaSans(
                            color: theme.primary, fontSize: 12, fontWeight: FontWeight.w600
                        )
                    ),
                    const SizedBox(height: 6),

                    if (isLowStock)
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)
                          ),
                          child: Text(
                              "⚠️ Stok Menipis",
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold
                              )
                          )
                      )
                    else
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)
                          ),
                          child: Text(
                              "✅ Stok Aman",
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold
                              )
                          )
                      ),
                  ],
                ),
              ),

              // MENU TITIK TIGA (EDIT & DELETE)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                color: theme.surface,
                onSelected: (value) {
                  if (value == 'edit') {
                    _showInventorySheet(context, theme, docId: docId, existingData: item);
                  } else if (value == 'delete') {
                    _deleteItem(docId, name, theme);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: theme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text("Edit Barang", style: TextStyle(color: theme.textMain)),
                        ]
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text("Hapus", style: TextStyle(color: Colors.red)),
                        ]
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 8),

          // ROW BAWAH: INDIKATOR ANGKA & KONTROL +/-
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  "Sisa: $stock $unit",
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold, fontSize: 15, color: theme.textMain
                  )
              ),
              Container(
                decoration: BoxDecoration(
                    color: theme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.2))
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18, color: Colors.redAccent),
                      // NOTE: Parameter yang dilempar sekarang full object 'item'
                      onPressed: () => _updateStock(docId, item, -1),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    Container(width: 1, height: 20, color: Colors.grey.withOpacity(0.3)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18, color: Colors.green),
                      // NOTeE: Parameter yang dilempar sekarang full object 'item'
                      onPressed: () => _updateStock(docId, item, 1),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}