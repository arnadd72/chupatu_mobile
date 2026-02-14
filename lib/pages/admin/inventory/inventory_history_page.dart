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
  String _filter = 'Semua'; // Pilihan: Semua, Minggu Ini, Bulan Ini

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text("Riwayat Stok", style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            body: Column(
              children: [
                // --- FILTER CHIPS ---
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
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
                          labelStyle: TextStyle(color: isSelected ? theme.primary : Colors.grey),
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
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada riwayat"));

                      var docs = snapshot.data!.docs;

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (c, i) => const Divider(),
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          bool isIn = data['type'] == 'in'; // Masuk (Hijau) atau Keluar (Merah)

                          DateTime date = (data['createdAt'] as Timestamp).toDate();
                          String dateStr = DateFormat('dd MMM, HH:mm').format(date);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: isIn ? Colors.green : Colors.red, size: 20),
                            ),
                            title: Text(data['itemName'] ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                            subtitle: Text(dateStr, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                            trailing: Text(
                              "${isIn ? '+' : '-'}${data['amount']}",
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: isIn ? Colors.green : Colors.red,
                                  fontSize: 16
                              ),
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

  // Logika Filter Query Firestore
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