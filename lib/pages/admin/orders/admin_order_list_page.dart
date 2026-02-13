import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/admin/orders/admin_order_detail_page.dart';
// IMPORT TEMA KACA
import 'package:chupatu_mobile/pages/admin/widgets/admin_glass_theme.dart';

class AdminOrderListPage extends StatefulWidget {
  const AdminOrderListPage({super.key});

  @override
  State<AdminOrderListPage> createState() => _AdminOrderListPageState();
}

class _AdminOrderListPageState extends State<AdminOrderListPage> {
  String _selectedFilter = 'Semua'; // Filter Default

  // Helper Warna Status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Confirmed': return Colors.blue;
      case 'Picked Up': return Colors.purple;
      case 'Processing': return Colors.indigo;
      case 'Ready': return Colors.teal;
      case 'Delivery': return Colors.deepPurple;
      case 'Done': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Column(
            children: [
              // 1. HEADER & FILTER CHIPS
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Daftar Pesanan", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textMain)),
                    const SizedBox(height: 16),

                    // FILTER HORIZONTAL
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Semua', theme),
                          _buildFilterChip('Pending', theme),
                          _buildFilterChip('Proses', theme), // Gabungan Picked Up, Processing, Ready, Delivery
                          _buildFilterChip('Selesai', theme), // Done
                          _buildFilterChip('Batal', theme),   // Cancelled
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. LIST PESANAN (STREAM)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("Belum ada data", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
                    }

                    // LOGIKA FILTERING DATA
                    var docs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String status = data['status'] ?? 'Pending';

                      if (_selectedFilter == 'Semua') return true;
                      if (_selectedFilter == 'Pending') return status == 'Pending' || status == 'Confirmed';
                      if (_selectedFilter == 'Proses') return ['Picked Up', 'Processing', 'Ready', 'Delivery'].contains(status);
                      if (_selectedFilter == 'Selesai') return status == 'Done';
                      if (_selectedFilter == 'Batal') return status == 'Cancelled';
                      return true;
                    }).toList();

                    if (docs.isEmpty) {
                      return Center(child: Text("Tidak ada pesanan di kategori ini", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        return _buildOrderCard(docs[index].id, data, theme);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }
    );
  }

  // WIDGET TOMBOL FILTER
  Widget _buildFilterChip(String label, AppThemeData theme) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? theme.primary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 12
          ),
        ),
      ),
    );
  }

  // WIDGET KARTU ORDER (VERSI LIST)
  Widget _buildOrderCard(String docId, Map<String, dynamic> data, AppThemeData theme) {
    String status = data['status'] ?? 'Unknown';
    Color statusColor = _getStatusColor(status);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    int price = data['totalPrice'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard( // Pakai Tema Kaca
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AdminOrderDetailPage(docId: docId, data: data)));
        },
        child: Row(
          children: [
            // FOTO SEPATU
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  image: data['shoeImageUrl'] != null
                      ? DecorationImage(image: NetworkImage(data['shoeImageUrl']), fit: BoxFit.cover)
                      : null
              ),
              child: data['shoeImageUrl'] == null ? const Icon(Icons.shopping_bag_outlined, color: Colors.grey) : null,
            ),
            const SizedBox(width: 16),

            // INFO TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(data['serviceName'] ?? 'Layanan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(currencyFormatter.format(price), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(data['customerName'] ?? 'Customer', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 8),

                  // BADGE STATUS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(status.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                  )
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}