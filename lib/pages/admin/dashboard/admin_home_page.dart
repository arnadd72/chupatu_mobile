import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/auth/landing_page.dart';

// --- IMPORT FILE PENDUKUNG ---
import 'package:chupatu_mobile/pages/admin/orders/admin_order_detail_page.dart';
import 'package:chupatu_mobile/pages/admin/dashboard/admin_chat_page.dart';
import 'package:chupatu_mobile/pages/admin/management/admin_management_page.dart';
import 'package:chupatu_mobile/pages/admin/widgets/admin_glass_theme.dart'; // Tetap di-import meski tidak dipakai disini agar tidak error jika ada ref lain
import 'package:chupatu_mobile/pages/admin/orders/admin_order_list_page.dart';
import 'package:chupatu_mobile/pages/admin/pos/admin_pos_page.dart';
import 'package:chupatu_mobile/pages/admin/inventory/admin_inventory_page.dart';
import 'package:chupatu_mobile/pages/admin/settings/admin_settings_page.dart';
import 'package:chupatu_mobile/pages/admin/management/finance_report_page.dart';
import 'package:chupatu_mobile/pages/admin/dashboard/admin_scan_page.dart';

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
    String s = status.toLowerCase();
    if (['pending', 'menunggu'].contains(s)) return Colors.orange;
    if (['confirmed', 'diterima'].contains(s)) return Colors.blue;
    if (['picked up', 'di jemput'].contains(s)) return Colors.purple;
    if (['processing', 'diproses', 'cuci'].contains(s)) return Colors.indigo;
    if (['ready', 'selesai cuci'].contains(s)) return Colors.teal;
    if (['delivery', 'diantar'].contains(s)) return Colors.deepPurple;
    if (['done', 'selesai'].contains(s)) return Colors.green;
    if (['cancelled', 'batal'].contains(s)) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName ?? "Admin";

    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {

          final List<Widget> pages = [
            _buildDashboardHome(theme),
            const AdminOrderListPage(),
            const AdminPOSPage(),
            const AdminInventoryPage(),
            const AdminManagementPage(),
          ];

          // PERUBAHAN: Gunakan Scaffold biasa (Bukan AdminGlassScaffold) agar super ringan
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: theme.surface, // Warna solid
              elevation: 0,
              // PERUBAHAN: Hapus flexibleSpace kaca (BackdropFilter)

              title: PopupMenuButton<String>(
                offset: const Offset(0, 50),
                color: theme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutConfirmDialog();
                  } else if (value == 'settings') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSettingsPage())).then((_) => setState((){}));
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'settings', child: Row(children: [Icon(Icons.settings_outlined, color: theme.textMain, size: 20), const SizedBox(width: 12), Text('Pengaturan', style: GoogleFonts.plusJakartaSans(color: theme.textMain))])),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(value: 'logout', child: Row(children: [const Icon(Icons.logout, color: Colors.red, size: 20), const SizedBox(width: 12), Text('Keluar Akun', style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.bold))])),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primary.withOpacity(0.2),
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null ? Icon(Icons.person, color: theme.primary) : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text("Halo, ", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey)),
                          Text(displayName, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textMain)),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 18)
                        ]),
                      ],
                    ),
                  ],
                ),
              ),

              actions: [
                // --- PERUBAHAN: TOMBOL SWITCH LIGHT/DARK KHUSUS ADMIN ---
                IconButton(
                  tooltip: "Ubah Mode Layar",
                  icon: Icon(
                    theme.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: theme.primary,
                  ),
                  onPressed: () {
                    if (theme.isDark) {
                      ThemeConfig.changeTheme(0); // 0 = Default Blue (Light Mode)
                    } else {
                      ThemeConfig.changeTheme(7); // 8 = Dark Modern (Dark Mode)
                    }
                  },
                ),
                IconButton(
                    tooltip: "Scan Barcode Sepatu",
                    onPressed: (){ Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScanPage())); },
                    icon: Icon(Icons.qr_code_scanner_rounded, color: theme.textMain)
                ),
                IconButton(
                    tooltip: "Chat Pelanggan",
                    onPressed: (){ Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminChatPage())); },
                    icon: Icon(Icons.chat_bubble_outline_rounded, color: theme.textMain)
                ),
                const SizedBox(width: 8),
              ],
            ),

            body: pages[_selectedIndex],

            // PERUBAHAN: Navbar solid tanpa blur kaca
            bottomNavigationBar: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.dashboard_rounded, "Home", _selectedIndex == 0, theme, 0),
                  _buildNavItem(Icons.receipt_long_rounded, "Orders", _selectedIndex == 1, theme, 1),
                  _buildNavItem(Icons.point_of_sale_rounded, "Kasir", _selectedIndex == 2, theme, 2),
                  _buildNavItem(Icons.inventory_2_rounded, "Gudang", _selectedIndex == 3, theme, 3),
                  _buildNavItem(Icons.admin_panel_settings_rounded, "Kelola", _selectedIndex == 4, theme, 4),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildDashboardHome(AppThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("Database Kosong / Belum Terhubung", style: TextStyle(color: theme.textMain))
              ]
          ));
        }

        final allDocs = snapshot.data!.docs;
        int totalDocsCount = allDocs.length;

        int incomingOrders = allDocs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String s = (data['status'] ?? '').toString().toLowerCase();
          return ['pending', 'confirmed', 'menunggu konfirmasi'].contains(s);
        }).length;

        int washingOrders = allDocs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String s = (data['status'] ?? '').toString().toLowerCase();
          return ['picked up', 'processing', 'ongoing', 'sedang dicuci'].contains(s);
        }).length;

        int readyOrders = allDocs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String s = (data['status'] ?? '').toString().toLowerCase();
          return ['ready', 'delivery', 'siap diambil'].contains(s);
        }).length;

        int revenue = allDocs.fold(0, (sum, doc) {
          var data = doc.data() as Map<String, dynamic>;
          String s = (data['status'] ?? '').toString().toLowerCase();

          if (s == 'done' || s == 'selesai') {
            var rawPrice = data['totalPrice'] ?? data['price'] ?? data['cost'] ?? 0;
            int price = 0;
            if (rawPrice is int) price = rawPrice;
            if (rawPrice is String) price = int.tryParse(rawPrice) ?? 0;
            if (rawPrice is double) price = rawPrice.toInt();
            return sum + price;
          }
          return sum;
        });

        final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ringkasan Toko", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.withOpacity(0.2))),
                    child: Text("Total Data: $totalDocsCount", style: TextStyle(fontSize: 10, color: theme.textMain)),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // --- GRID STATISTIK ---
              Row(
                children: [
                  _buildStatCard("Order Masuk", "$incomingOrders", Icons.inbox_rounded, Colors.orange, theme),
                  const SizedBox(width: 12),
                  _buildStatCard("Sedang Dicuci", "$washingOrders", Icons.local_laundry_service_rounded, Colors.blue, theme),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard("Siap Ambil", "$readyOrders", Icons.check_circle_outline_rounded, Colors.teal, theme),
                  const SizedBox(width: 12),
                  // CARD PENDAPATAN
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const FinanceReportPage()));
                      },
                      // PERUBAHAN: Mengganti GlassCard dengan Container solid yang ringan
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.monetization_on_rounded, color: Colors.green, size: 20),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.5))),
                                  child: const Icon(Icons.info_outline, size: 12, color: Colors.grey),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(currencyFormatter.format(revenue), style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text("Total Pendapatan", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('inventory')
                    .where('stock', isLessThanOrEqualTo: 3)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3))
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Perhatian: Stok Menipis!", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.red)),
                              Text(
                                  "${snapshot.data!.docs.length} barang perlu restock segera.",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.red.shade700)
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedIndex = 3);
                          },
                          child: const Text("Cek", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("Order Terbaru", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                TextButton(
                    onPressed: () => setState(() => _selectedIndex = 1),
                    child: Text("Lihat Semua", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.primary))
                )
              ]),
              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allDocs.length > 3 ? 3 : allDocs.length,
                itemBuilder: (context, index) {
                  var data = allDocs[index].data() as Map<String, dynamic>;
                  String docId = allDocs[index].id;
                  return _buildCompactOrderCard(docId, data, theme, context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmDialog() { showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: ThemeConfig.currentTheme.value.surface, title: Text("Konfirmasi", style: TextStyle(color: ThemeConfig.currentTheme.value.textMain)), content: Text("Yakin ingin keluar?", style: TextStyle(color: ThemeConfig.currentTheme.value.textMain)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")), ElevatedButton(onPressed: () { Navigator.pop(ctx); _handleLogout(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Keluar"))])); }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, AppThemeData theme) {
    return Expanded(
      // PERUBAHAN: Mengganti GlassCard dengan Container solid yang ringan
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(icon, color: color, size: 20)
                  ),
                  const SizedBox(height: 12),
                  Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey))
                ]
            )
        )
    );
  }

  Widget _buildCompactOrderCard(String docId, Map<String, dynamic> data, AppThemeData theme, BuildContext context) {
    String status = (data['status'] ?? 'Unknown').toString();
    Color statusColor = _getStatusColor(status);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    var rawPrice = data['totalPrice'] ?? data['basePrice'] ?? data['price'] ?? 0;
    int price = 0;
    if (rawPrice is int) price = rawPrice;
    if (rawPrice is String) price = int.tryParse(rawPrice) ?? 0;
    if (rawPrice is double) price = rawPrice.toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AdminOrderDetailPage(docId: docId, data: data)));
        },
        // PERUBAHAN: Mengganti GlassCard dengan Container solid yang ringan
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  image: data['shoeImageUrl'] != null ? DecorationImage(image: NetworkImage(data['shoeImageUrl']), fit: BoxFit.cover) : null,
                ),
                child: data['shoeImageUrl'] == null ? const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['serviceName'] ?? 'Layanan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textMain)),
                    Text(data['customerName'] ?? 'Pelanggan', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(currencyFormatter.format(price), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textMain)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(status.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold, color: statusColor)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, AppThemeData theme, int index) {
    return GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? theme.primary : Colors.grey.shade500, size: 24),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? theme.primary : Colors.grey.shade500))
            ]
        )
    );
  }
}