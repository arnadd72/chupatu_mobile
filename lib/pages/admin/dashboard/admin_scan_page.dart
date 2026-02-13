import 'dart:async'; // Untuk animasi timer
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/pages/admin/widgets/admin_glass_theme.dart'; // Pastikan import tema benar

class AdminScanPage extends StatefulWidget {
  const AdminScanPage({super.key});

  @override
  State<AdminScanPage> createState() => _AdminScanPageState();
}

class _AdminScanPageState extends State<AdminScanPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    // Animasi garis scanner naik turun
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background hitam ala kamera
      body: Stack(
        children: [
          // 1. KAMERA DUMMY (Background Gelap)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade900,
            child: Center(
              child: Text(
                  "Kamera akan terbuka disini...",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white24)
              ),
            ),
          ),

          // 2. OVERLAY KACA & PEMBATAS SCAN
          SafeArea(
            child: Column(
              children: [
                // --- HEADER (BACK & FLASH) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tombol Back Kaca
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      Text("Scan QR Code", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      // Tombol Flash Kaca
                      GestureDetector(
                        onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isFlashOn ? Colors.yellow.withOpacity(0.8) : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              _isFlashOn ? Icons.flash_on : Icons.flash_off,
                              color: _isFlashOn ? Colors.black : Colors.white
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // --- AREA SCANNER (KOTAK TENGAH) ---
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Kotak Pembatas
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      // Sudut-sudut Fokus (Pojok Tebal)
                      _buildCornerFocus(),

                      // Garis Animasi Scanning
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Positioned(
                            top: 10 + (260 * _animationController.value), // Bergerak dari atas ke bawah
                            child: Container(
                              width: 260,
                              height: 2,
                              decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  boxShadow: [
                                    BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                                  ]
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text("Arahkan kamera ke label barcode sepatu", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14)),

                const Spacer(),

                // --- FOOTER (INPUT MANUAL) ---
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text("Susah scan barcode?", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Nanti ini untuk input kode manual (Keyboard)
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Input Manual segera hadir")));
                          },
                          icon: const Icon(Icons.keyboard_alt_outlined),
                          label: const Text("Input Kode Pesanan Manual"),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Bikin Pojokan Kotak Fokus biar keren
  Widget _buildCornerFocus() {
    return SizedBox(
      width: 300, height: 300,
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, child: _cornerLine(0)),     // Kiri Atas
          Positioned(right: 0, top: 0, child: _cornerLine(1)),    // Kanan Atas
          Positioned(left: 0, bottom: 0, child: _cornerLine(2)),  // Kiri Bawah
          Positioned(right: 0, bottom: 0, child: _cornerLine(3)), // Kanan Bawah
        ],
      ),
    );
  }

  Widget _cornerLine(int rotation) {
    return RotatedBox(
      quarterTurns: rotation,
      child: Container(
        width: 40, height: 40,
        decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.blue, width: 4),
              left: BorderSide(color: Colors.blue, width: 4),
            )
        ),
      ),
    );
  }
}