import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/home/home_page.dart';
import 'package:chupatu_mobile/pages/order/order_history_page.dart';
import 'package:chupatu_mobile/pages/profile/profile_page.dart';
import 'package:chupatu_mobile/pages/profile/account_page.dart';
import 'package:chupatu_mobile/pages/order/quick_order.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const Center(child: Text("Garage Page (Segera Hadir)")),
    const SizedBox(),
    const OrderHistoryPage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            extendBody: true, // Background tembus ke bawah

            body: _pages[_currentIndex],

            // --- BAGIAN 1: TOMBOL TENGAH (+) ---
            // Transform.translate KITA HAPUS, diganti logika lokasi di bawah
            floatingActionButton: SizedBox(
              width: 55,
              height: 55,
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => const QuickOrder(),
                  );
                },
                backgroundColor: theme.primary,
                elevation: 0,
                highlightElevation: 0,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),

            // --- BAGIAN 2: LOKASI CUSTOM (RAHASIANYA DISINI) ---
            floatingActionButtonLocation: const CenterDockedWithOffset(offsetY: 30),

            // --- NAVBAR ---
            bottomNavigationBar: BottomAppBar(
              color: theme.surface,
              elevation: 15,
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              // Tambahkan notch ini supaya background navbar "menghindar" dari tombol
              //shape: const CircularNotchedRectangle(),
              //notchMargin: 8.0,
              child: SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_rounded, "Home", 0, theme),
                    _buildNavItem(Icons.inventory_2_outlined, "Garage", 1, theme),

                    const SizedBox(width: 48), // Spasi tengah

                    _buildNavItem(Icons.receipt_long_rounded, "Orders", 3, theme),
                    _buildNavItem(Icons.person_rounded, "Akun", 4, theme),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, AppThemeData theme) {
    bool isSelected = _currentIndex == index;
    Color inactiveColor = Colors.grey.shade400;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                icon,
                color: isSelected ? theme.primary : inactiveColor,
                size: 26
            ),
            const SizedBox(height: 4),
            Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.primary : inactiveColor
                )
            )
          ],
        ),
      ),
    );
  }
}

// --- BAGIAN 3: CLASS TAMBAHAN (Taruh di paling bawah file ini) ---
// Class ini fungsinya menghitung posisi tombol supaya BENAR-BENAR TURUN (Sensor + Gambar)
class CenterDockedWithOffset extends FloatingActionButtonLocation {
  final double offsetY; // Berapa pixel mau diturunkan

  const CenterDockedWithOffset({this.offsetY = 0});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // 1. Hitung posisi Tengah Horizontal (X)
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;

    // 2. Hitung posisi Vertikal (Y) Standar
    final double standardY = scaffoldGeometry.contentBottom - scaffoldGeometry.floatingActionButtonSize.height / 2.0;

    // 3. Tambahkan Offset yang anda inginkan (Turun 30px)
    final double fabY = standardY + offsetY;

    return Offset(fabX, fabY);
  }
}