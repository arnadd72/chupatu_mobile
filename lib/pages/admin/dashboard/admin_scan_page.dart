import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:chupatu_mobile/pages/admin/widgets/admin_glass_theme.dart';

// IMPORT HALAMAN DETAIL ORDER ADMIN YANG BENAR
import 'package:chupatu_mobile/pages/admin/orders/admin_order_detail_page.dart';

class AdminScanPage extends StatefulWidget {
  const AdminScanPage({super.key});

  @override
  State<AdminScanPage> createState() => _AdminScanPageState();
}

class _AdminScanPageState extends State<AdminScanPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isFlashOn = false;
  bool _isSearching = false;

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
    _scannerController.dispose();
    super.dispose();
  }

  // --- LOGIKA PENCARIAN KE FIREBASE (COLLECTION 'bookings') ---
  Future<void> _searchOrder(String scannedCode) async {
    String cleanCode = scannedCode.trim();
    if (cleanCode.isEmpty || _isSearching) return;

    setState(() => _isSearching = true);
    _scannerController.stop(); // Pause kamera saat loading

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Mencari data pesanan..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      var doc = await FirebaseFirestore.instance
          .collection('bookings') // Sesuai dengan database Bos
          .doc(cleanCode)
          .get();

      if (doc.exists) {
        setState(() => _isSearching = false);

        // Ekstrak data JSON dari Firebase
        Map<String, dynamic> orderData =
        doc.data() as Map<String, dynamic>;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pesanan Ditemukan!"),
            backgroundColor: Colors.green,
          ),
        );

        if (!mounted) return;

        // PINDAH KE HALAMAN DETAIL DENGAN PARAMETER YANG BENAR
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminOrderDetailPage(
              docId: doc.id,   // Lempar ID Dokumen
              data: orderData, // Lempar Data Lengkap

              // ⚠️ CATATAN: Buka comment 3 baris di bawah ini
              // JIKA di AdminOrderDetailPage Bos juga
              // mewajibkan parameter warna dan ikon status
              // ------------------------------------------
              // statusColor: Colors.blueAccent,
              // statusIcon: Icons.info_outline_rounded,
              // statusLabel: "Detail Pesanan",
            ),
          ),
        );

      } else {
        // Jika tidak ketemu, nyalakan kamera lagi
        setState(() => _isSearching = false);
        _scannerController.start();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pesanan [$cleanCode] tidak ditemukan!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      _scannerController.start();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // --- POPUP INPUT KODE MANUAL ---
  void _showManualInputDialog() {
    TextEditingController resiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Input Manual",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: resiController,
            decoration: InputDecoration(
              hintText: "Contoh ID pesanan...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Batal",
                style: GoogleFonts.plusJakartaSans(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _searchOrder(resiController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Cari",
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KAMERA SCANNER AKTIF
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isSearching) {
                  _searchOrder(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // 2. OVERLAY KACA & PEMBATAS SCAN
          SafeArea(
            child: Column(
              children: [
                // --- HEADER (BACK & FLASH) ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      Text(
                        "Scan QR Code",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          _scannerController.toggleTorch();
                          setState(() => _isFlashOn = !_isFlashOn);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isFlashOn
                                ? Colors.yellow.withOpacity(0.8)
                                : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: _isFlashOn ? Colors.black : Colors.white,
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
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      // Sudut-sudut Fokus (Posisi sudah 100% presisi)
                      _buildCornerFocus(),

                      // Garis Animasi Scanning
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          double topPos = 10 +
                              (260 * _animationController.value);

                          return Positioned(
                            top: topPos,
                            child: Container(
                              width: 260,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Arahkan kamera ke label barcode pesanan",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const Spacer(),

                // --- FOOTER (INPUT MANUAL) ---
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        "Susah scan barcode?",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showManualInputDialog,
                          icon: const Icon(Icons.keyboard_alt_outlined),
                          label: const Text("Input Kode Pesanan Manual"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

  // --- WIDGET PENDUKUNG DESAIN UI ---
  Widget _buildCornerFocus() {
    return SizedBox(
      width: 300, height: 300,
      child: Stack(
        children: [
          // Kiri Atas
          Positioned(left: 0, top: 0, child: _cornerLine(0)),

          // Kanan Atas
          Positioned(right: 0, top: 0, child: _cornerLine(1)),

          // Kiri Bawah (Sudah diperbaiki)
          Positioned(left: 0, bottom: 0, child: _cornerLine(3)),

          // Kanan Bawah (Sudah diperbaiki)
          Positioned(right: 0, bottom: 0, child: _cornerLine(2)),
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
          ),
        ),
      ),
    );
  }
}