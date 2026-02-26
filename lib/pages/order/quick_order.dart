import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:chupatu_mobile/pages/order/booking_page.dart';

class QuickOrder extends StatefulWidget {
  const QuickOrder({super.key});

  @override
  State<QuickOrder> createState() => _QuickOrderState();
}

class _QuickOrderState extends State<QuickOrder> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  String? _errorMessage;

  String _shoeType = "-";
  String _condition = "-";
  String _recommendation = "-";
  String _careTips = "-";
  bool _hasResult = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Nyalakan mesin SATU KALI SAJA saat halaman dibuka
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/ml/model.tflite",
        labels: "assets/ml/labels.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false,
      );
    } catch (e) {
      debugPrint("Error Load AI: $e");
    }
  }

  @override
  void dispose() {
    Tflite.close(); // Tutup mesin HANYA saat keluar dari halaman
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, StateSetter setModalState) async {
    try {
      // OBAT 1: Ukuran asli Teachable Machine adalah 224x224.
      // Ini dijamin RAM tidak akan kepenuhan!
      final XFile? pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 224,
          maxHeight: 224,
          imageQuality: 50
      );

      if (pickedFile != null) {
        setModalState(() {
          _selectedImage = File(pickedFile.path);
          _hasResult = false;
          _errorMessage = null;
        });
        _analyzeShoeConditionTFLite(setModalState);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _analyzeShoeConditionTFLite(StateSetter setModalState) async {
    if (_selectedImage == null) return;

    setModalState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    // Kasih jeda 0.2 detik biar loading ungu muncul di layar
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      // OBAT 2: asynch: false.
      // Ini akan memaksa Android mengeksekusi AI sampai tuntas, anti macet!
      var recognitions = await Tflite.runModelOnImage(
          path: _selectedImage!.path,
          imageMean: 127.5,
          imageStd: 127.5,
          numResults: 1,
          threshold: 0.1,
          asynch: false
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        String label = recognitions[0]['label'];
        label = label.replaceAll(RegExp(r'[0-9]'), '').trim();
        _generateRecommendationFromLabel(label, setModalState);
      } else {
        setModalState(() {
          _errorMessage = "AI ragu ini sepatu apa. Coba foto lebih jelas.";
        });
      }
    } catch (e) {
      setModalState(() {
        _errorMessage = "Error Sistem AI: $e";
      });
      debugPrint("Error Analisa Asli: $e");
    } finally {
      setModalState(() => _isAnalyzing = false);
    }
  }

  // --- PEMETAAN 5 LABEL ---
  void _generateRecommendationFromLabel(String detectedLabel, StateSetter setModalState) {
    String type = detectedLabel;
    String condition = "Kotor pemakaian wajar";
    String rec = "Deep Clean";
    String tips = "Bersihkan secara rutin agar kotoran tidak mengerak.";

    String labelLower = detectedLabel.toLowerCase();

    if (labelLower.contains("converse") || labelLower.contains("canvas")) {
      type = "Converse / Canvas";
      condition = "Noda menyerap ke kain & sol menguning (yellowing).";
      rec = "Deep Clean + Unyellowing";
      tips = "Jangan dijemur di bawah matahari langsung agar warna tidak pudar.";
    } else if (labelLower.contains("sneaker")) {
      type = "Sneakers Umum";
      condition = "Debu membandel di bagian midsole & upper.";
      rec = "Deep Clean";
      tips = "Gunakan shoe tree agar bentuk sepatu tetap terjaga.";
    } else if (labelLower.contains("loafers") || labelLower.contains("leather")) {
      type = "Loafers / Leather";
      condition = "Kulit kusam dan butuh hidrasi agar tidak retak.";
      rec = "Leather Care / Premium Clean";
      tips = "Gunakan lotion khusus kulit secara berkala.";
    } else if (labelLower.contains("soccer") || labelLower.contains("bola")) {
      type = "Sepatu Bola / Futsal";
      condition = "Kerak lumpur & sisa rumput di sela-sela sol.";
      rec = "Hard Clean";
      tips = "Segera bersihkan lumpur setelah pemakaian.";
    } else if (labelLower.contains("boots")) {
      type = "Boots";
      condition = "Lumpur tebal & butuh proteksi air (waterproof).";
      rec = "Deep Clean + Waterproofing";
      tips = "Semprot water repellent setelah kering sempurna.";
    }

    setModalState(() {
      _shoeType = type;
      _condition = condition;
      _recommendation = rec;
      _careTips = tips;
      _hasResult = true;
    });
  }

  // --- UI MODAL & BUILDER ---
  void _showAIShoeCheckModal(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    Padding(padding: const EdgeInsets.all(24), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: Colors.purpleAccent)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("AI Shoe Check", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)), Text("Deteksi kondisi sepatu *On-Device*", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey))])])),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showSourcePicker(context, setModalState),
                              child: Container(width: double.infinity, height: 200, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300), image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null), child: _selectedImage == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.grey.shade400), const SizedBox(height: 8), Text("Ambil Foto / Upload", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontWeight: FontWeight.bold))]) : null),
                            ),
                            const SizedBox(height: 24),

                            if (_isAnalyzing) ...[
                              const CircularProgressIndicator(color: Colors.purpleAccent),
                              const SizedBox(height: 16),
                              Text("Menganalisa Sepatu...", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.purpleAccent, fontWeight: FontWeight.bold))
                            ] else if (_errorMessage != null) ...[
                              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                                  child: Text(_errorMessage!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.red.shade800)))
                            ] else if (_hasResult) ...[
                              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))], border: Border.all(color: Colors.purpleAccent.withOpacity(0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 20), const SizedBox(width: 8), Text("Analisa Selesai", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.green))]), const Divider(height: 24), _buildResultRow("Jenis", _shoeType, Icons.accessibility_new_rounded), const SizedBox(height: 12), _buildResultRow("Kondisi", _condition, Icons.search_rounded), const SizedBox(height: 12), _buildResultRow("Tips", _careTips, Icons.lightbulb_rounded, isLongText: true), const Divider(height: 24), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Rekomendasi Layanan:", style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)), Text(_recommendation, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.purpleAccent))])])),
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
                      child: Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)))),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: ElevatedButton(
                            onPressed: _isAnalyzing ? null : () {
                              if (_hasResult) {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(
                                  serviceName: _recommendation,
                                  basePrice: 50000,
                                )));
                              } else {
                                if (_selectedImage != null) _analyzeShoeConditionTFLite(setModalState);
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: _hasResult ? Colors.green : Colors.purpleAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: Text(_isAnalyzing ? "Loading..." : (_hasResult ? "Pesan Layanan Ini" : "Foto Dulu"), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)))),
                      ]),
                    )
                  ],
                ),
              );
            }
        );
      },
    );
  }

  void _showSourcePicker(BuildContext context, StateSetter setModalState) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("Pilih Sumber Foto", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildSourceButton(Icons.camera_alt_rounded, "Kamera", () { Navigator.pop(ctx); _pickImage(ImageSource.camera, setModalState); }), _buildSourceButton(Icons.photo_library_rounded, "Galeri", () { Navigator.pop(ctx); _pickImage(ImageSource.gallery, setModalState); })])])));
  }

  Widget _buildSourceButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: Colors.purpleAccent, size: 30)), const SizedBox(height: 8), Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))]));
  }

  Widget _buildResultRow(String label, String value, IconData icon, {bool isLongText = false}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 2), Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black87, height: 1.4), maxLines: isLongText ? 5 : 2, overflow: TextOverflow.ellipsis)]))]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 24), Text("Mau layanan apa bos?", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 20),

        _buildMenuItem(
            context,
            icon: Icons.add_circle_outline_rounded,
            title: "Booking Order",
            subtitle: "Pilih layanan manual.",
            color: Colors.blueAccent,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingPage(
                serviceName: "Layanan Manual",
                basePrice: 0,
              )));
            }
        ),

        const SizedBox(height: 12),
        _buildMenuItem(context, icon: Icons.auto_awesome, title: "Cek Kondisi (AI)", subtitle: "Foto sepatu, biar kami analisa.", color: Colors.purpleAccent, onTap: () { Navigator.pop(context); _showAIShoeCheckModal(context); }),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 4), Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600))])), Icon(Icons.chevron_right, color: Colors.grey.shade400)])));
  }
}