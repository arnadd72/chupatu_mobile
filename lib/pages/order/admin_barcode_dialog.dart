import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Wajib import ini

class AdminBarcodeDialog extends StatelessWidget {
  final String docId;
  final String customerName;

  const AdminBarcodeDialog({
    super.key,
    required this.docId,
    required this.customerName
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Label Barcode", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Tempel pada sepatu milik:", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
            Text(customerName, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),

            const SizedBox(height: 24),

            // --- QR CODE GENERATOR ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: QrImageView(
                data: docId, // Isi Barcode adalah ID Pesanan
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),
            Text("#${docId.toUpperCase().substring(0, 8)}", style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, letterSpacing: 1.5)),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Disini nanti bisa tambah logika Print Bluetooth
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Siap untuk dicetak/discan!")));
                },
                icon: const Icon(Icons.print),
                label: const Text("Tutup / Print"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}