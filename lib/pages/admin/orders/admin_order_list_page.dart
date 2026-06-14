import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/admin/orders/admin_order_detail_page.dart';

class AdminOrderListPage extends StatefulWidget {
  const AdminOrderListPage({super.key});

  @override
  State<AdminOrderListPage> createState() => _AdminOrderListPageState();
}

class _AdminOrderListPageState extends State<AdminOrderListPage> {
  String _selectedStatusFilter = 'Semua Status';
  String _selectedMemberFilter = 'Semua Member';

  final List<String> _statusFilters = [
    'Semua Status',
    'Pending',
    'Confirmed',
    'Picked Up',
    'Processing',
    'Ready',
    'Delivery',
    'Done',
    'Cancelled'
  ];

  final List<String> _memberFilters = [
    'Semua Member',
    'Member Pro',
    'Member Reguler'
  ];

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

                    // FILTER ROW DROPDOWNS
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedStatusFilter,
                            items: _statusFilters,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedStatusFilter = val);
                            },
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedMemberFilter,
                            items: _memberFilters,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedMemberFilter = val);
                            },
                            theme: theme,
                          ),
                        ),
                      ],
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

                    var docs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String status = data['status'] ?? 'Pending';
                      bool isPro = data['isProMemberUsed'] == true;

                      // Cek Filter Status
                      bool matchStatus = true;
                      if (_selectedStatusFilter != 'Semua Status') {
                        matchStatus = status == _selectedStatusFilter;
                      }

                      // Cek Filter Member
                      bool matchMember = true;
                      if (_selectedMemberFilter == 'Member Pro') {
                        matchMember = isPro;
                      } else if (_selectedMemberFilter == 'Member Reguler') {
                        matchMember = !isPro;
                      }

                      return matchStatus && matchMember;
                    }).toList();

                    // MENGURUTKAN: Member PRO di posisi teratas
                    docs.sort((a, b) {
                      bool isProA = (a.data() as Map<String, dynamic>)['isProMemberUsed'] ?? false;
                      bool isProB = (b.data() as Map<String, dynamic>)['isProMemberUsed'] ?? false;
                      
                      if (isProA && !isProB) return -1;
                      if (!isProA && isProB) return 1;
                      // Jika sama-sama Pro atau Reguler, biarkan berdasarkan tanggal (sudah diurutkan Firestore)
                      return 0;
                    });

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

  // WIDGET DROPDOWN FILTER
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required AppThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          dropdownColor: theme.surface,
          style: GoogleFonts.plusJakartaSans(
            color: theme.textMain,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }

  // WIDGET KARTU ORDER
  Widget _buildOrderCard(String docId, Map<String, dynamic> data, AppThemeData theme) {
    String status = data['status'] ?? 'Unknown';
    Color statusColor = _getStatusColor(status);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    int price = data['totalPrice'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AdminOrderDetailPage(docId: docId, data: data)));
        },
        // PERUBAHAN: Mengganti GlassCard dengan Container solid yang support Dark Mode
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
          ),
          child: Row(
            children: [
              // FOTO SEPATU
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                    color: theme.background, // PERUBAHAN: Warna dasar kotak gambar
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
                        Text(data['serviceName'] ?? 'Layanan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain)),
                        Text(currencyFormatter.format(price), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(data['customerName'] ?? 'Customer', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                        if (data['isProMemberUsed'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade400]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text("PRO", style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          )
                        ],
                      ],
                    ),
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
              Icon(Icons.chevron_right, color: theme.textMain.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}