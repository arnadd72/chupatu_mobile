import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MagicResultDetailPage extends StatefulWidget {
  final String title;
  final String beforeImg;
  final String afterImg;

  const MagicResultDetailPage({
    super.key,
    required this.title,
    required this.beforeImg,
    required this.afterImg,
  });

  @override
  State<MagicResultDetailPage> createState() => _MagicResultDetailPageState();
}

class _MagicResultDetailPageState extends State<MagicResultDetailPage> {
  // Posisi awal slider ada di tengah (50%)
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background gelap biar fokus ke gambar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
            widget.title,
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Geser garis pemisah ke kiri atau kanan untuk melihat perbedaan Before & After.",
              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight * 0.8; // Pakai 80% dari tinggi layar

                    return GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          // Update posisi slider sesuai gerakan jari
                          _sliderValue += details.delta.dx / width;
                          _sliderValue = _sliderValue.clamp(0.0, 1.0); // Jangan sampai keluar kotak
                        });
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: Stack(
                            children: [
                              // 1. AFTER IMAGE (Background paling bawah)
                              Image.network(
                                widget.afterImg,
                                width: width,
                                height: height,
                                fit: BoxFit.cover,
                              ),

                              // 2. BEFORE IMAGE (Dipotong menggunakan ClipRect)
                              ClipRect(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _sliderValue, // Lebarnya mengikuti slider
                                  child: Image.network(
                                    widget.beforeImg,
                                    width: width,
                                    height: height,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              // 3. GARIS SLIDER & HANDLE (Alat tarik)
                              Positioned(
                                left: (width * _sliderValue) - 15,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 30,
                                  color: Colors.transparent,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Garis vertikal putih
                                      Container(width: 4, color: Colors.white),
                                      // Kotak handle di tengah
                                      Container(
                                        height: 40,
                                        width: 30,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 5
                                              )
                                            ]
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Icon(Icons.arrow_left, size: 14, color: Colors.black),
                                            Icon(Icons.arrow_right, size: 14, color: Colors.black),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),

                              // 4. LABEL TEKS "BEFORE" & "AFTER"
                              Positioned(
                                  bottom: 16, left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.black54, borderRadius: BorderRadius.circular(20)
                                    ),
                                    child: const Text("BEFORE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  )
                              ),
                              Positioned(
                                  bottom: 16, right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.black54, borderRadius: BorderRadius.circular(20)
                                    ),
                                    child: const Text("AFTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  )
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 40), // Ruang bawah
        ],
      ),
    );
  }
}