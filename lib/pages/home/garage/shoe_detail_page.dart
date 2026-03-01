import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/main.dart';

class ShoeDetailPage extends StatelessWidget {
  final Map<String, dynamic> shoeData;

  const ShoeDetailPage({super.key, required this.shoeData});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          String? resultImage = shoeData['resultImage'];
          bool hasResult = resultImage != null && resultImage.toString().isNotEmpty;

          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              backgroundColor: theme.surface,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
              title: Text("Detail Koleksi",
                  style: GoogleFonts.plusJakartaSans(color: theme.textMain,
                      fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FOTO SEPATU ---
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(shoeData['image'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- INFO SEPATU ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(shoeData['brand'] ?? 'Unknown Brand',
                              style: GoogleFonts.plusJakartaSans(
                                  color: theme.primary,
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(height: 12),
                        Text(shoeData['name'] ?? 'Sepatu',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 24, fontWeight: FontWeight.w800,
                                color: theme.textMain)),
                        const SizedBox(height: 8),
                        Text("Ukuran: ${shoeData['size'] ?? '-'}",
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 16),

                        if (shoeData['note'] != null &&
                            shoeData['note'].toString().isNotEmpty) ...[
                          Text("Catatan:", style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold, fontSize: 14,
                              color: theme.textMain)),
                          const SizedBox(height: 4),
                          Text(shoeData['note'], style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, color: Colors.grey.shade700)),
                          const SizedBox(height: 24),
                        ],

                        // --- KARTU MAGIC RESULT ✨ ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.amber.shade100, Colors.orange.shade50],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.shade300),
                              boxShadow: [
                                BoxShadow(color: Colors.amber.withOpacity(0.2),
                                    blurRadius: 10, offset: const Offset(0, 4))
                              ]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text("Magic Result",
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18, fontWeight: FontWeight.w900,
                                          color: Colors.orange.shade900)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              hasResult
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(resultImage!,
                                    width: double.infinity, height: 250, fit: BoxFit.cover),
                              )
                                  : Container(
                                width: double.infinity, padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.hourglass_empty_rounded,
                                        color: Colors.orange.shade300, size: 40),
                                    const SizedBox(height: 12),
                                    Text("Belum ada layanan yang selesai.",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.bold)),
                                    Text("Pesan layanan untuk melihat keajaiban!",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12, color: Colors.orange.shade700)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }
}