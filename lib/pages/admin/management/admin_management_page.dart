import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/main.dart';

// --- IMPORT HALAMAN ADMIN ---
import 'package:chupatu_mobile/pages/admin/management/manage_services_page.dart';
import 'package:chupatu_mobile/pages/admin/management/manage_promo_page.dart';
import 'package:chupatu_mobile/pages/admin/management/finance_report_page.dart';
import 'package:chupatu_mobile/pages/admin/management/customer_list_page.dart';

class AdminManagementPage extends StatelessWidget {
  const AdminManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F6FA),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pusat Kontrol", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Atur semua operasional Chupatu dari sini.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                  const SizedBox(height: 24),

                  // GRID MENU
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1, // Kotak agak lebar
                    children: [
                      // 1. MANAJEMEN LAYANAN
                      _buildAdminMenuCard(
                        context,
                        title: "Layanan",
                        subtitle: "Tambah/Edit Layanan & Harga",
                        icon: Icons.cleaning_services_rounded,
                        color: Colors.blue,
                        onTap: () {
                          // --- NAVIGASI KE LAYANAN ---
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageServicesPage()));
                        },
                      ),

                      // 2. KODE PROMO & NOTIF
                      _buildAdminMenuCard(
                        context,
                        title: "Promo & Notif",
                        subtitle: "Broadcast & Kode Kupon",
                        icon: Icons.campaign_rounded,
                        color: Colors.orange,
                        onTap: () {
                          // --- NAVIGASI KE PROMO ---
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePromoPage()));
                        },
                      ),

                      // 3. LAPORAN KEUANGAN
                      _buildAdminMenuCard(
                        context,
                        title: "Keuangan",
                        subtitle: "Grafik Pendapatan & Laporan",
                        icon: Icons.pie_chart_rounded,
                        color: Colors.green,
                        onTap: () {
                          // --- NAVIGASI KE KEUANGAN ---
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const FinanceReportPage()));
                        },
                      ),

                      // 4. DATA PELANGGAN
                      _buildAdminMenuCard(
                        context,
                        title: "Pelanggan",
                        subtitle: "Database User Lengkap",
                        icon: Icons.people_alt_rounded,
                        color: Colors.purple,
                        onTap: () {
                          // --- NAVIGASI KE PELANGGAN ---
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerListPage()));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildAdminMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}