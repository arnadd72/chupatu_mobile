import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/pages/order/booking_page.dart';
import 'package:chupatu_mobile/pages/order/custom_service_page.dart';

// ============================================================================
// KONFIGURASI API (NGROK LARAVEL)
// ============================================================================
class ApiConfig {
  static const String baseUrl =
      'https://malik-pseudomonocyclic-misti.ngrok-free.dev/api';
  static const String uploadUrl = '$baseUrl/upload';
  static const String geminiUrl = '$baseUrl/magic-result';
}

// ============================================================================
// HALAMAN UTAMA QUICK ORDER (Menu Pilihan)
// ============================================================================
class QuickOrder extends StatelessWidget {
  const QuickOrder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text("Mau layanan apa?",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 20),

          _buildMenuItem(
            icon: Icons.list_alt_rounded,
            title: "Booking Order (Manual)",
            subtitle: "Pilih layanan dari daftar harga.",
            color: Colors.blueAccent,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) =>
                  const ManualBookingScreen()));
            },
          ),
          const SizedBox(height: 12),

          _buildMenuItem(
            icon: Icons.auto_awesome,
            title: "Cek Kondisi (Gemini AI)",
            subtitle: "Deteksi kondisi & merk sepatu otomatis.",
            color: Colors.purpleAccent,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) =>
                  const AIScannerScreen()));
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey.shade600))
                    ])),
            Icon(Icons.chevron_right, color: Colors.grey.shade400)
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HALAMAN FULL 1: BOOKING MANUAL DARI FIREBASE
// ============================================================================
class ManualBookingScreen extends StatelessWidget {
  const ManualBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Pilih Layanan",
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Belum ada layanan di database.",
                style: GoogleFonts.plusJakartaSans()));
          }

          var services = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: services.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              var serviceData = services[index].data() as Map<String, dynamic>;
              String name = serviceData['name'] ?? 'Layanan';
              int price = serviceData['price'] ?? 0;

              return InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => BookingPage(
                        serviceName: name,
                        basePrice: price,
                      )));
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.2))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text("Rp $price",
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// HALAMAN FULL 2: AI SCANNER GEMINI (LARAVEL VERSION)
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
      _hasResult = false; // Reset hasil sebelumnya
    });

    try {
      // 1. PROSES UPLOAD KE LARAVEL
      var request = http.MultipartRequest(
          'POST', Uri.parse(ApiConfig.uploadUrl));

      request.files.add(await http.MultipartFile.fromPath(
          'foto', _selectedImage!.path));
      request.fields['kategori'] = 'order_customer';

      var responseUpload = await request.send();

      if (responseUpload.statusCode == 200) {
        var resData = await responseUpload.stream.bytesToString();
        var jsonRes = json.decode(resData);
        String urlFoto = jsonRes['url'];

        // 2. PROSES TANYA GEMINI (MAGIC RESULT)
        final responseGemini = await http.post(
          Uri.parse(ApiConfig.geminiUrl),
          body: {'url_foto': urlFoto},
        );

        // Debugging: Intip jawaban asli dari server di console
        debugPrint("Jawaban Laravel: ${responseGemini.body}");

        if (responseGemini.statusCode == 200) {
          var res = json.decode(responseGemini.body);

          // PERBAIKAN: Ambil langsung dari key 'data'
          // karena Laravel sudah melakukan json_decode di server
          var dataAI = res['data'];

          setState(() {
            _shoeBrand = dataAI['merk'] ?? "-";
            _shoeType = dataAI['jenis'] ?? "-";
            _condition = dataAI['kondisi'] ?? "-";
            _careTips = dataAI['tips'] ?? "-";

            // Pastikan rekomendasi adalah List
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
      debugPrint("Detail Error: $e");
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
                      color: Colors.purpleAccent.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.purpleAccent, size: 30)),
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
                    const CircularProgressIndicator(color: Colors.purpleAccent),
                    const SizedBox(height: 16),
                    Text("AI Gemini sedang menganalisa secara detail...",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.purpleAccent,
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
                                color: Colors.purpleAccent.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5))],
                          border: Border.all(
                              color: Colors.purpleAccent.withOpacity(0.2))),
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
                                      color: Colors.purpleAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.purpleAccent.withOpacity(0.5))),
                                  child: Text(service,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purpleAccent,
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
            child: ElevatedButton(
              onPressed: _isAnalyzing
                  ? null
                  : () {
                if (_hasResult) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomServicePage(
                        aiRecommendation: _aiTips,
                      ),
                    ),
                  );
                } else {
                  if (_selectedImage != null) _analyzeShoeCondition();
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: _hasResult ? Colors.green : Colors.purpleAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isAnalyzing
                    ? "Loading..."
                    : (_hasResult ? "Pesan Layanan Rekomendasi" : "Kirim ke AI"),
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