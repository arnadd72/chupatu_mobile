import 'dart:ui';
import 'package:flutter/material.dart';

// 1. SCAFFOLD KACA (BACKGROUND UTAMA)
class AdminGlassScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const AdminGlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Supaya body nyatu sama background
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // LAYER 1: GRADIENT BACKGROUND (Warni-warni)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0EAFF), // Biru Muda banget
                  Color(0xFFFFE8E8), // Pink Muda
                  Color(0xFFE8FFF4), // Hijau Muda
                  Color(0xFFF3E8FF), // Ungu Muda
                ],
              ),
            ),
          ),

          // LAYER 2: BULATAN-BULATAN ABSTRAK (Biar Kaca makin kelihatan)
          Positioned(top: -50, left: -50, child: _blurCircle(Colors.blue.withOpacity(0.4))),
          Positioned(top: 150, right: -30, child: _blurCircle(Colors.purple.withOpacity(0.3))),
          Positioned(bottom: -50, left: 100, child: _blurCircle(Colors.orange.withOpacity(0.3))),

          // LAYER 3: KONTEN ASLI
          SafeArea(child: body),
        ],
      ),
    );
  }

  Widget _blurCircle(Color color) {
    return Container(
      width: 200, height: 200,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

// 2. KARTU KACA (GLASS CARD)
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const GlassCard({super.key, required this.child, this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // EFEK BLUR
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6), // Transparan Putih
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), // Border Kaca
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}