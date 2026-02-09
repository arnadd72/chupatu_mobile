import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/main.dart'; // Butuh struktur AppThemeData

class AutoMagicCard extends StatefulWidget {
  final String beforeUrl;
  final String afterUrl;
  final String title;
  final AppThemeData theme;
  final VoidCallback onTap;

  const AutoMagicCard({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
    required this.title,
    required this.theme,
    required this.onTap,
  });

  @override
  State<AutoMagicCard> createState() => _AutoMagicCardState();
}

class _AutoMagicCardState extends State<AutoMagicCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Setup animasi berulang (bolak-balik) selama 4 detik
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 220, // Lebar tetap kartu
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: widget.theme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          border: Border.all(color: widget.theme.textMain.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- AREA GAMBAR ANIMASI ---
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        // Nilai animasi 0.0 -> 1.0 -> 0.0
                        double scanValue = _controller.value; 
                        // Agar tidak terlalu mepet pinggir, kita kasih margin sedikit (0.1 - 0.9)
                        double clampedValue = (scanValue * 0.8) + 0.1;
                        double cutPosition = width * clampedValue;

                        return Stack(
                          children: [
                            // 1. LAYER BAWAH (AFTER - BERSIH) - Full Gambar
                            Image.network(
                              widget.afterUrl,
                              width: width,
                              height: height,
                              fit: BoxFit.cover,
                            ),

                            // 2. LAYER ATAS (BEFORE - KOTOR) - Dipotong Melintang
                            ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: clampedValue, // Lebar berubah sesuai animasi
                                child: Image.network(
                                  widget.beforeUrl,
                                  width: width, // Pastikan width tetap full agar gambar tidak gepeng
                                  height: height,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            // 3. GARIS SCANNER (Pemanis Visual)
                            Positioned(
                              left: cutPosition - 2, // Posisi mengikuti potongan
                              top: 0, bottom: 0,
                              child: Container(
                                width: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  boxShadow: [
                                    BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                                  ]
                                ),
                              ),
                            ),

                            // 4. LABEL TAP TO INTERACT
                             Positioned(
                              bottom: 10, right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    Icon(Icons.touch_app, color: widget.theme.primary, size: 12),
                                    const SizedBox(width: 4),
                                    Text('TAP UNTUK MENCOBA', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            
            // --- AREA TEKS BAWAH ---
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: widget.theme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Indikator Before/After kecil
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red.shade300, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text("Before", style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.grey),
                      const SizedBox(width: 8),
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green.shade300, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text("After", style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}