import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chupatu_mobile/main.dart'; 

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // LOGIKA CANCEL: Hanya boleh jika status masih Pending atau Confirmed
  Future<void> _cancelOrder(String docId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Batalkan Pesanan?"),
        content: const Text("Yakin ingin membatalkan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tidak")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('bookings').doc(docId).update({'status': 'Cancelled'});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Ya, Batalkan"),
          )
        ],
      ),
    );
  }

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
        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            title: Text("Pesanan Saya", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
            backgroundColor: theme.surface,
            elevation: 0,
            automaticallyImplyLeading: false, // Hilangkan tombol back jika di navbar
            bottom: TabBar(
              controller: _tabController,
              labelColor: theme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: theme.primary,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              tabs: const [Tab(text: "Dalam Proses"), Tab(text: "Riwayat")],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(isActive: true, theme: theme),
              _buildOrderList(isActive: false, theme: theme),
            ],
          ),
        );
      }
    );
  }

  Widget _buildOrderList({required bool isActive, required AppThemeData theme}) {
    if (_uid == null) return const Center(child: Text("Login required"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: _uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

        // Filter Manual Client-Side (Agar lebih fleksibel)
        final filteredDocs = snapshot.data!.docs.where((doc) {
          String status = (doc.data() as Map)['status'] ?? 'Pending';
          if (isActive) {
            // Tab Aktif: Semua KECUALI Done & Cancelled
            return status != 'Done' && status != 'Cancelled';
          } else {
            // Tab Riwayat: HANYA Done & Cancelled
            return status == 'Done' || status == 'Cancelled';
          }
        }).toList();

        if (filteredDocs.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            return _buildCard(filteredDocs[index].id, filteredDocs[index].data() as Map<String, dynamic>, theme);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 60, color: Colors.grey.shade300), const SizedBox(height: 10), Text("Tidak ada data", style: GoogleFonts.plusJakartaSans(color: Colors.grey))]));
  }

  Widget _buildCard(String docId, Map<String, dynamic> data, AppThemeData theme) {
    String status = data['status'] ?? 'Unknown';
    Color color = _getStatusColor(status);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    // Tombol cancel hanya muncul jika Pending atau Confirmed
    bool canCancel = (status == 'Pending' || status == 'Confirmed');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['serviceName'] ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)),
              Text("#${docId.substring(0, 6).toUpperCase()}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
            ]),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: color)))
          ]),
          const Divider(height: 24),
          Row(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey)), 
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['shoeDetail'] ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain), maxLines: 1), Text("Total: ${currency.format(data['totalPrice'] ?? 0)}", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: theme.primary, fontWeight: FontWeight.w700))])),
          ]),
          if (canCancel) ...[
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => _cancelOrder(docId), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), foregroundColor: Colors.red), child: const Text("Batalkan Pesanan")))
          ]
        ],
      ),
    );
  }
}