import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/home/home_page.dart';
import 'package:chupatu_mobile/pages/order/order_history_page.dart';
import 'package:chupatu_mobile/pages/profile/profile_page.dart';
import 'package:chupatu_mobile/pages/profile/account_page.dart';

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
    const AccountPage(), // <--- INI YANG DIUBAH MENJADI ACCOUNT PAGE
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            extendBody: true, // Penting agar background tembus ke bawah navbar

            body: _pages[_currentIndex],

            // --- TOMBOL TENGAH (+) YANG DITURUNKAN ---
            floatingActionButton: Transform.translate(
              offset: const Offset(0, 30), // <--- TURUNKAN 10 PIXEL KE BAWAH
              child: SizedBox(
                width: 55,
                height: 55,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() => _currentIndex = 0);
                  },
                  backgroundColor: theme.primary,
                  // Elevation 0 agar tidak terlihat melayang (flat)
                  elevation: 0,
                  // Highlight elevation 0 agar saat diklik tidak lompat
                  highlightElevation: 0,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),

            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

            // --- NAVBAR ---
            bottomNavigationBar: BottomAppBar(
              color: Colors.white,
              elevation: 15, // Shadow navbar dipertebal biar kontras
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
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