import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/home/home_page.dart';
import 'package:chupatu_mobile/pages/order/order_history_page.dart';
import 'package:chupatu_mobile/pages/profile/profile_page.dart';
import 'package:chupatu_mobile/pages/profile/account_page.dart';
import 'package:chupatu_mobile/pages/order/quick_order.dart';
import 'package:chupatu_mobile/pages/home/garage/garage_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const GaragePage(isFromNavbar: true),
    const SizedBox(), // Placeholder untuk tombol tengah
    const OrderHistoryPage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            extendBody: true,

            body: Stack(
              children: [
                // 1. KONTEN UTAMA
                _pages[_currentIndex],

                // 2. FLOATING CARD NAVBAR (Lebih Ramping & Kompak)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    // Margin disesuaikan biar nggak terlalu ngambang
                    margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
                    // Padding diperkecil biar nggak bulky
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavItem(Icons.home_rounded, "Home", 0, theme),
                        _buildNavItem(Icons.inventory_2_rounded, "Garage", 1, theme),

                        // Tombol Tengah Custom (Add Shopping Cart)
                        _buildCenterQuickOrder(context, theme),

                        _buildNavItem(Icons.receipt_long_rounded, "Orders", 3, theme),
                        _buildNavItem(Icons.person_rounded, "Akun", 4, theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  // --- LOGIKA ANIMASI MENU (100% SMOOTH) ---
  Widget _buildNavItem(IconData icon, String label, int index, AppThemeData theme) {
    bool isSelected = _currentIndex == index;
    Color inactiveColor = Colors.grey.shade400;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50, // Lebar di-fix biar pas animasi nggak geser-geser layout sebelahnya
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animasi Ikon
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              // Kasih efek sedikit terangkat ke atas kalau lagi aktif
              padding: EdgeInsets.only(bottom: isSelected ? 2.0 : 0.0),
              child: Icon(
                icon,
                color: isSelected ? theme.primary : inactiveColor,
                size: isSelected ? 24 : 22, // Ukuran ikon lebih proporsional
              ),
            ),

            // Animasi Teks (Smooth Fade & Slide Down)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isSelected ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: isSelected ? 14 : 0, // Tinggi nyesuain secara mulus
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, // Font dikecilin dikit biar nggak sesak
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- TOMBOL TENGAH (QUICK ORDER) ---
  Widget _buildCenterQuickOrder(BuildContext context, AppThemeData theme) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const QuickOrder(),
        );
      },
      child: Container(
        // Ukuran tombol diperkecil biar sejajar manis sama navbar
        height: 46,
        width: 46,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
            color: theme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
        ),
        // Ikon yang lebih masuk akal untuk bikin pesanan cuci
        child: const Icon(
          Icons.add_shopping_cart_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}