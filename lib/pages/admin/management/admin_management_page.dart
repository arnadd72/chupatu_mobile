import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/main.dart';

// --- IMPORT HALAMAN ADMIN ---
import 'package:chupatu_mobile/pages/admin/management/manage_services_page.dart';
import 'package:chupatu_mobile/pages/admin/management/manage_promo_page.dart';
import 'package:chupatu_mobile/pages/admin/management/finance_report_page.dart';
import 'package:chupatu_mobile/pages/admin/management/customer_list_page.dart';
// TAMBAHAN: Import Halaman Review yang baru kita buat
import 'package:chupatu_mobile/pages/admin/management/admin_review_page.dart';

class AdminManagementPage extends StatelessWidget {
  const AdminManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Pusat Kontrol",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textMain
                      )
                  ),
                  const SizedBox(height: 8),
                  Text(
                      "Atur semua operasional Chupatu dari sini.",
                      style: GoogleFonts.plusJakartaSans(color: Colors.grey)
                  ),
                  const SizedBox(height: 24),

                  // GRID MENU
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      // 1. MANAJEMEN LAYANAN
                      _buildAdminMenuCard(
                        context,
                        theme: theme,
                        title: "Layanan",
                        subtitle: "Tambah/Edit Layanan & Harga",
                        icon: Icons.cleaning_services_rounded,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ManageServicesPage())
                          );
                        },
                      ),

                      // 2. KODE PROMO & NOTIF
                      _buildAdminMenuCard(
                        context,
                        theme: theme,
                        title: "Promo & Notif",
                        subtitle: "Broadcast & Kode Kupon",
                        icon: Icons.campaign_rounded,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ManagePromoPage())
                          );
                        },
                      ),

                      // 3. LAPORAN KEUANGAN
                      _buildAdminMenuCard(
                        context,
                        theme: theme,
                        title: "Keuangan",
                        subtitle: "Grafik Pendapatan & Laporan",
                        icon: Icons.pie_chart_rounded,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FinanceReportPage())
                          );
                        },
                      ),

                      // 4. DATA PELANGGAN
                      _buildAdminMenuCard(
                        context,
                        theme: theme,
                        title: "Pelanggan",
                        subtitle: "Database User Lengkap",
                        icon: Icons.people_alt_rounded,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CustomerListPage())
                          );
                        },
                      ),

                      // 5. MONITOR ULASAN (FITUR BARU)
                      _buildAdminMenuCard(
                        context,
                        theme: theme,
                        title: "Ulasan",
                        subtitle: "Pantau & Balas Review",
                        icon: Icons.star_rate_rounded,
                        color: Colors.amber, // Warna emas cocok untuk rating
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminReviewPage())
                          );
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

  Widget _buildAdminMenuCard(
      BuildContext context,
      {required AppThemeData theme,
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap}
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.textMain
                )
            ),
            const SizedBox(height: 4),
            Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis
            ),
          ],
        ),
      ),
    );
  }
}