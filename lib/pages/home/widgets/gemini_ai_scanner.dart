import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:chupatu_mobile/pages/order/custom_service_page.dart';

// ============================================================================
// KONFIGURASI API KHUSUS GEMINI
// ============================================================================
class GeminiApiConfig {
  static const String baseUrl =
      'https://malik-pseudomonocyclic-misti.ngrok-free.dev/api';
  static const String uploadUrl = '$baseUrl/upload';
  static const String geminiUrl = '$baseUrl/magic-result';
}

// ============================================================================
// WIDGET CARD UNTUK DI HOME PAGE (BERANDA)
// Nanti tinggal panggil GeminiScanCard() di file home_page.dart
// ============================================================================
class GeminiScanCard extends StatelessWidget {
  const GeminiScanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AIScannerScreen()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF22D3EE), Color(0xFF06B6D4)], // Tema Cyan
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF22D3EE).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8))
            ]),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)
                  ]
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF9B72CB), Color(0xFFD96570)], // Warna Khas Gemini
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Magic Scan AI",
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("Deteksi sepatu & rekomendasi cuci otomatis",
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16)
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HALAMAN FULL AI SCANNER GEMINI
// ============================================================================
class AIScannerScreen extends StatefulWidget {
  const AIScannerScreen({super.key});

  @override
  State<AIScannerScreen> createState() => _AIScannerScreenState();
}

class _AIScannerScreenState extends State<AIScannerScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  String? _errorMessage;

  String _shoeBrand = "-";
  String _shoeType = "-";
  String _condition = "-";
  String _careTips = "-";
  String _aiTips = "-";
  List<String> _recommendedServices = [];
  bool _hasResult = false;
  String? _uploadedImageUrl;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: source, maxWidth: 800, maxHeight: 800, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasResult = false;
          _errorMessage = null;
        });
        _analyzeShoeCondition();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _analyzeShoeCondition() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _hasResult = false;
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse(GeminiApiConfig.uploadUrl));

      request.files.add(await http.MultipartFile.fromPath(
          'foto', _selectedImage!.path));
      request.fields['kategori'] = 'order_customer';

      var responseUpload = await request.send();

      if (responseUpload.statusCode == 200) {
        var resData = await responseUpload.stream.bytesToString();
        var jsonRes = json.decode(resData);
        String urlFoto = jsonRes['url'];
        _uploadedImageUrl = urlFoto;

        final responseGemini = await http.post(
          Uri.parse(GeminiApiConfig.geminiUrl),
          body: {'url_foto': urlFoto},
        );

        if (responseGemini.statusCode == 200) {
          var res = json.decode(responseGemini.body);
          var dataAI = res['data'];

          setState(() {
            _shoeBrand = dataAI['merk'] ?? "-";
            _shoeType = dataAI['jenis'] ?? "-";
            _condition = dataAI['kondisi'] ?? "-";
            _careTips = dataAI['tips'] ?? "-";

            if (dataAI['rekomendasi'] is List) {
              _recommendedServices =
              List<String>.from(dataAI['rekomendasi']);
            } else {
              _recommendedServices = [dataAI['rekomendasi'].toString()];
            }

            _aiTips = _recommendedServices.isNotEmpty
                ? _recommendedServices.join(", ")
                : "Layanan Umum";

            _hasResult = true;
          });
        } else {
          setState(() => _errorMessage =
          "Gemini Error: ${responseGemini.statusCode}");
        }
      } else {
        setState(() => _errorMessage =
        "Gagal Upload. Status: ${responseUpload.statusCode}");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error Koneksi: $e");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Pilih Sumber Foto",
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSourceButton(Icons.camera_alt_rounded, "Kamera", () {
                          Navigator.pop(ctx); _pickImage(ImageSource.camera);
                        }),
                        _buildSourceButton(Icons.photo_library_rounded, "Galeri", () {
                          Navigator.pop(ctx); _pickImage(ImageSource.gallery);
                        })
                      ])
                ])));
  }

  Widget _buildSourceButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: Column(
            children: [
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Color(0xFF06B6D4).withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(icon, color: Color(0xFF06B6D4), size: 30)),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold))
            ]));
  }

  Widget _buildResultRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("AI Cloud Scanner",
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showSourcePicker,
                    child: Container(
                      width: double.infinity, height: 300,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300)),
                      child: _selectedImage == null
                          ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text("Ambil Foto / Upload",
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold))])
                          : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isAnalyzing) ...[
                    const CircularProgressIndicator(color: Color(0xFF06B6D4)),
                    const SizedBox(height: 16),
                    Text("AI Gemini sedang menganalisa secara detail...",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Color(0xFF06B6D4),
                            fontWeight: FontWeight.bold))
                  ] else if (_errorMessage != null) ...[
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200)),
                        child: Text(_errorMessage!,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: Colors.red.shade800)))
                  ] else if (_hasResult) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Color(0xFF06B6D4).withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5))],
                          border: Border.all(
                              color: Color(0xFF06B6D4).withOpacity(0.2))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text("Analisa Selesai",
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green))]),
                          const Divider(height: 24),
                          _buildResultRow("Merk", _shoeBrand,
                              Icons.branding_watermark_rounded),
                          const SizedBox(height: 12),
                          _buildResultRow("Jenis", _shoeType,
                              Icons.accessibility_new_rounded),
                          const SizedBox(height: 12),
                          _buildResultRow("Kondisi", _condition,
                              Icons.search_rounded),
                          const SizedBox(height: 12),
                          _buildResultRow("Tips Perawatan", _careTips,
                              Icons.lightbulb_rounded),
                          const Divider(height: 24),
                          Text("Rekomendasi Layanan:",
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _recommendedServices.map((service) =>
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: Color(0xFF06B6D4).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Color(0xFF06B6D4).withOpacity(0.5))),
                                  child: Text(service,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF06B6D4),
                                          fontSize: 12)),
                                )).toList(),
                          )
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: _selectedImage != null && !_isAnalyzing
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showSourcePicker,
                          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF06B6D4), size: 18),
                          label: Text(
                            "Foto Ulang",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF06B6D4),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            side: const BorderSide(color: Color(0xFF06B6D4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_hasResult) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomServicePage(
                                    aiRecommendation: _aiTips,
                                    aiImageFile: _selectedImage,
                                    aiImageUrl: _uploadedImageUrl,
                                    aiShoeBrand: _shoeBrand,
                                    aiShoeType: _shoeType,
                                    aiCondition: _condition,
                                  ),
                                ),
                              );
                            } else {
                              _analyzeShoeCondition();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            backgroundColor: _hasResult ? Colors.green : Color(0xFF06B6D4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _hasResult ? "Pesan Layanan" : "Kirim ke AI",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _isAnalyzing
                        ? null
                        : _showSourcePicker,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: Color(0xFF06B6D4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isAnalyzing ? "Loading..." : "Pilih Foto Sepatu",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
          )
        ],
      ),
    );
  }
}