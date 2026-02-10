import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:google_sign_in/google_sign_in.dart'; 
import 'package:chupatu_mobile/main.dart'; 
import 'package:chupatu_mobile/pages/auth/landing_page.dart';
import 'package:chupatu_mobile/pages/admin/admin_order_detail_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  Future<void> _handleLogout() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pop(context); 
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingPage()), (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal Logout: $e")));
      }
    }
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
            automaticallyImplyLeading: false,
            backgroundColor: theme.surface,
            elevation: 0,
            title: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) { if (value == 'logout') _showLogoutConfirmDialog(); },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'Profile', child: Row(children: [Icon(Icons.person_outline, color: theme.textMain, size: 20), const SizedBox(width: 12), Text('Edit Profil Toko', style: GoogleFonts.plusJakartaSans(color: theme.textMain))])),
                PopupMenuItem<String>(value: 'logout', child: Row(children: [const Icon(Icons.logout, color: Colors.red, size: 20), const SizedBox(width: 12), Text('Keluar Akun', style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.bold))])),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(backgroundColor: theme.primary.withOpacity(0.2), child: Icon(Icons.admin_panel_settings, color: theme.primary)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text("Admin Dashboard", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)), const SizedBox(width: 4), Icon(Icons.arrow_drop_down, color: theme.textMain, size: 18)]), Text("Chupatu Semarang", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey))]),
                ],
              ),
            ),
            actions: [
              IconButton(onPressed: (){}, icon: Icon(Icons.qr_code_scanner, color: theme.textMain)),
              IconButton(onPressed: (){}, icon: Icon(Icons.chat_bubble_outline_rounded, color: theme.textMain)),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState(theme);

              final docs = snapshot.data!.docs;
              
              // --- 1. PERBAIKAN LOGIKA STATISTIK ---
              int totalOrders = docs.length;
              
              // Perlu Proses = Status 'Pending' atau 'Confirmed'
              int pendingOrders = docs.where((doc) {
                String s = (doc.data() as Map)['status'] ?? '';
                return s == 'Pending' || s == 'Confirmed';
              }).length;

              // Sedang Dicuci = Status 'Picked Up', 'Processing', 'Ready', 'Delivery'
              int processOrders = docs.where((doc) {
                String s = (doc.data() as Map)['status'] ?? '';
                return ['Picked Up', 'Processing', 'Ready', 'Delivery'].contains(s);
              }).length;

              // --- 2. PERBAIKAN PENDAPATAN (HANYA YANG 'DONE') ---
              int revenue = docs.fold(0, (sum, doc) {
                var data = doc.data() as Map<String, dynamic>;
                if (data['status'] == 'Done') {
                  return sum + (data['totalPrice'] as int? ?? 0);
                }
                return sum;
              });

              final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Overview Hari Ini", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                    const SizedBox(height: 16),
                    Row(children: [_buildStatCard("Total Order", "$totalOrders", Icons.inbox, Colors.blue, theme), const SizedBox(width: 12), _buildStatCard("Perlu Proses", "$pendingOrders", Icons.priority_high_rounded, Colors.orange, theme)]),
                    const SizedBox(height: 12),
                    Row(children: [_buildStatCard("Sedang Dicuci", "$processOrders", Icons.local_laundry_service_rounded, Colors.purple, theme), const SizedBox(width: 12), _buildStatCard("Pendapatan", currencyFormatter.format(revenue), Icons.monetization_on, Colors.green, theme)]),
                    const SizedBox(height: 30),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Order Terbaru", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)), TextButton(onPressed: () {}, child: Text("Lihat Semua", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)))]),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length > 10 ? 10 : docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        String docId = docs[index].id;
                        return _buildOrderCard(docId, data, theme, context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: theme.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildNavItem(Icons.dashboard, "Home", _selectedIndex == 0, theme, 0), _buildNavItem(Icons.list_alt, "Orders", _selectedIndex == 1, theme, 1), _buildNavItem(Icons.qr_code_scanner, "Scan", _selectedIndex == 2, theme, 2), _buildNavItem(Icons.person, "Profile", _selectedIndex == 3, theme, 3)])),
        );
      }
    );
  }

  void _showLogoutConfirmDialog() { showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Konfirmasi"), content: const Text("Yakin ingin keluar?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")), ElevatedButton(onPressed: () { Navigator.pop(ctx); _handleLogout(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Keluar"))])); }
  Widget _buildEmptyState(AppThemeData theme) { return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade200), const SizedBox(height: 16), Text("Belum ada pesanan", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey))])); }
  Widget _buildStatCard(String title, String value, IconData icon, Color color, AppThemeData theme) { return Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)], border: Border.all(color: color.withOpacity(0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)), const SizedBox(height: 12), Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis), Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey))]))); }

  Widget _buildOrderCard(String docId, Map<String, dynamic> data, AppThemeData theme, BuildContext context) {
    String status = data['status'] ?? 'Unknown';
    Color statusColor = _getStatusColor(status); 
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    int price = data['totalPrice'] ?? data['basePrice'] ?? 0;
    Color cardBackground = Color.lerp(Colors.white, statusColor, 0.1)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("#${docId.substring(0, 6).toUpperCase()}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)))
          ]),
          const Divider(height: 24),
          Row(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), image: data['shoeImageUrl'] != null ? DecorationImage(image: NetworkImage(data['shoeImageUrl']), fit: BoxFit.cover) : null), child: data['shoeImageUrl'] == null ? const Icon(Icons.shopping_bag_outlined, color: Colors.grey) : null),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['serviceName'] ?? 'Layanan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              Text(data['customerName'] ?? 'Customer', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade700)),
            ])),
            Text(currencyFormatter.format(price), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () { 
              Navigator.push(context, MaterialPageRoute(builder: (context) => AdminOrderDetailPage(docId: docId, data: data)));
            }, style: OutlinedButton.styleFrom(side: BorderSide(color: statusColor), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text("Detail", style: GoogleFonts.plusJakartaSans(color: statusColor, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 8),
            // TOMBOL PROSES (SAMA, BIAR ADMIN KE DETAIL UNTUK LEBIH AMAN)
            Expanded(child: ElevatedButton(onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => AdminOrderDetailPage(docId: docId, data: data)));
            }, style: ElevatedButton.styleFrom(backgroundColor: statusColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text("Proses", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)))),
          ])
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, AppThemeData theme, int index) { return GestureDetector(onTap: () => setState(() => _selectedIndex = index), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: isActive ? theme.primary : Colors.grey.shade400, size: 24), const SizedBox(height: 4), Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? theme.primary : Colors.grey.shade400))])); }
}