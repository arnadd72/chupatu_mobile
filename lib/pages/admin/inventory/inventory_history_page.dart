import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart';

class InventoryHistoryPage extends StatefulWidget {
  const InventoryHistoryPage({super.key});

  @override
  State<InventoryHistoryPage> createState() => _InventoryHistoryPageState();
}

class _InventoryHistoryPageState extends State<InventoryHistoryPage> {
  String _filter = 'Semua';

  // Tambahkan formatter rupiah
  final _formatter = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text("Riwayat Stok & Biaya", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)),
              backgroundColor: theme.surface,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
            ),
            body: Column(
              children: [
                // --- FILTER CHIPS ---
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Semua', 'Minggu Ini', 'Bulan Ini'].map((filter) {
                      bool isSelected = _filter == filter;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: theme.primary.withOpacity(0.2),
                          backgroundColor: theme.background,
                          labelStyle: TextStyle(
                              color: isSelected ? theme.primary : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? theme.primary : Colors.transparent)
                          ),
                          onSelected: (val) => setState(() => _filter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // --- LIST LOG ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getLogStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada riwayat", style: TextStyle(color: Colors.grey)));

                      var docs = snapshot.data!.docs;

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (c, i) => Divider(color: Colors.grey.withOpacity(0.2)),
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          bool isIn = data['type'] == 'in';

                          // Ambil data harga yang baru kita tambahin
                          int priceAtTime = data['priceAtTime'] ?? 0;
                          int totalCost = data['totalCost'] ?? 0;

                          DateTime date = (data['createdAt'] as Timestamp).toDate();
                          String dateStr = DateFormat('dd MMM, HH:mm').format(date);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isIn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: isIn ? Colors.green : Colors.red, size: 20),
                            ),
                            title: Text(data['itemName'] ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dateStr, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                                // Tampilkan Harga Satuan jika ada harganya
                                if (priceAtTime > 0)
                                  Text(
                                      "@ ${_formatter.format(priceAtTime)}",
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: theme.primary, fontWeight: FontWeight.w600)
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${isIn ? '+' : '-'}${data['amount']}",
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      color: isIn ? Colors.green : Colors.red,
                                      fontSize: 16
                                  ),
                                ),
                                // Tampilkan Total Biaya Transaksi
                                if (totalCost > 0)
                                  Text(
                                    _formatter.format(totalCost),
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600
                                    ),
                                  )
                              ],
                            ),
                          );
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

  Stream<QuerySnapshot> _getLogStream() {
    var ref = FirebaseFirestore.instance.collection('inventory_logs').orderBy('createdAt', descending: true);

    DateTime now = DateTime.now();
    if (_filter == 'Minggu Ini') {
      DateTime lastWeek = now.subtract(const Duration(days: 7));
      return ref.where('createdAt', isGreaterThan: Timestamp.fromDate(lastWeek)).snapshots();
    } else if (_filter == 'Bulan Ini') {
      DateTime lastMonth = now.subtract(const Duration(days: 30));
      return ref.where('createdAt', isGreaterThan: Timestamp.fromDate(lastMonth)).snapshots();
    }

    return ref.snapshots();
  }
}