import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/pages/order/booking_page.dart';

// --- API KEY GOOGLE GEMINI ---
// GANTI DENGAN API KEY ANDA YANG ASLI DARI AI STUDIO
const String _apiKey = 'AIzaSyBZdMOQKt0dTU3nCFE5A-Kra074D5mVwvo';

class QuickOrder extends StatefulWidget {
  const QuickOrder({super.key});

  @override
  State<QuickOrder> createState() => _QuickOrderState();
}

class _QuickOrderState extends State<QuickOrder> {
  // --- STATE UNTUK AI ---
  File? _selectedImage;
  bool _isAnalyzing = false;
  String _shoeType = "-";
  String _condition = "-";
  String _recommendation = "-";
  String _careTips = "-";
  bool _hasResult = false;

  final ImagePicker _picker = ImagePicker();

  // --- FUNGSI AI: PROSES GAMBAR ---
  Future<void> _pickImage(ImageSource source, StateSetter setModalState) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 50);

      if (pickedFile != null) {
        setModalState(() {
          _selectedImage = File(pickedFile.path);
          _hasResult = false;
        });

        // Langsung Analisa
        _analyzeShoeCondition(setModalState);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _analyzeShoeCondition(StateSetter setModalState) async {
    if (_selectedImage == null) return;
    if (_apiKey == 'ISI_API_KEY_GEMINI_DISINI') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("API Key belum diisi! Cek kodingan."), backgroundColor: Colors.red));
      return;
    }

    setModalState(() => _isAnalyzing = true);

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final prompt = TextPart("""
        Analisa gambar sepatu ini sebagai Ahli Perawatan Sepatu Profesional.
        Format Jawaban WAJIB dipisah dengan tanda pipa '|' :
        [Jenis Sepatu] | [Kondisi Fisik & Noda] | [Rekomendasi Layanan] | [Tips Perawatan Singkat]
        
        Pilihan Layanan: Deep Clean, Fast Clean, Unyellowing, Repair, Repaint, Waterproof.
        Contoh: Sneakers Canvas | Noda lumpur & midsole kuning | Deep Clean + Unyellowing | Jangan sikat terlalu keras.
      """);

      final imageBytes = await _selectedImage!.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([Content.multi([prompt, imagePart])]);

      if (response.text != null) {
        final parts = response.text!.split('|');
        if (parts.length >= 4) {
          setModalState(() {
            _shoeType = parts[0].trim();
            _condition = parts[1].trim();
            _recommendation = parts[2].trim();
            _careTips = parts[3].trim();
            _hasResult = true;
          });
        } else {
          setModalState(() { _condition = response.text!; _hasResult = true; });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menganalisa: $e")));
    } finally {
      setModalState(() => _isAnalyzing = false);
    }
  }

  // --- UI: MODAL AI SHOE CHECK ---
  void _showAIShoeCheckModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),

                    // HEADER
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: Colors.purpleAccent)),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("AI Shoe Check", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)), Text("Deteksi kondisi sepatu otomatis", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey))]),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // AREA GAMBAR
                            GestureDetector(
                              onTap: () => _showSourcePicker(context, setModalState),
                              child: Container(
                                width: double.infinity, height: 200,
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300), image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null),
                                child: _selectedImage == null
                                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.grey.shade400), const SizedBox(height: 8), Text("Ambil Foto / Upload", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontWeight: FontWeight.bold))])
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // LOADING
                            if (_isAnalyzing) ...[const CircularProgressIndicator(), const SizedBox(height: 16), Text("AI sedang menganalisa...", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey))],

                            // HASIL
                            if (_hasResult && !_isAnalyzing)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))], border: Border.all(color: Colors.purpleAccent.withOpacity(0.2))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 20), const SizedBox(width: 8), Text("Analisa Selesai", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.green))]),
                                    const Divider(height: 24),
                                    _buildResultRow("Jenis", _shoeType, Icons.accessibility_new_rounded),
                                    const SizedBox(height: 12),
                                    _buildResultRow("Kondisi", _condition, Icons.search_rounded),
                                    const SizedBox(height: 12),
                                    _buildResultRow("Tips", _careTips, Icons.lightbulb_rounded, isLongText: true),
                                    const Divider(height: 24),
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Rekomendasi Layanan:", style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)), Text(_recommendation, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.purpleAccent))]),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),

                    // TOMBOL AKSI
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
                      child: Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)))),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: ElevatedButton(
                            onPressed: _hasResult
                                ? () {
                              Navigator.pop(context);
                              // TODO: Navigasi ke Booking dengan membawa data rekomendasi
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Memesan: $_recommendation")));
                            }
                                : null,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: Text(_hasResult ? "Pesan Sekarang" : "Foto Dulu", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)))),
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


  // --- BAGIAN LAMA (TIDAK DIUBAH TAMPILANNYA) ---

  void _showServiceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text("Pilih Layanan", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('services').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("Belum ada layanan tersedia", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
                  var allDocs = snapshot.data!.docs;
                  bool showMoreButton = allDocs.length > 6;
                  int itemCount = showMoreButton ? 6 : allDocs.length;
                  return GridView.builder(
                    itemCount: itemCount,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4),
                    itemBuilder: (context, index) {
                      if (showMoreButton && index == 5) {
                        return InkWell(onTap: () { Navigator.pop(context); _showMoreServices(context, allDocs.sublist(5)); }, borderRadius: BorderRadius.circular(16), child: Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.grid_view_rounded, size: 32, color: Colors.black87), const SizedBox(height: 8), Text("Lainnya", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)), Text("${allDocs.length - 5} lagi", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600))])));
                      }
                      var data = allDocs[index].data() as Map<String, dynamic>;
                      return _buildServiceCard(context, data);
                    },
                  );
                },
              ),
            )
          ],
          ),
        );
      },
    );
  }

  void _showMoreServices(BuildContext context, List<QueryDocumentSnapshot> remainingDocs) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) { return Container(height: MediaQuery.of(context).size.height * 0.6, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))), padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))), const SizedBox(height: 20), Row(children: [IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { Navigator.pop(context); _showServiceSelector(context); }), const SizedBox(width: 8), Text("Layanan Lainnya", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold))]), const SizedBox(height: 16), Expanded(child: GridView.builder(itemCount: remainingDocs.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4), itemBuilder: (context, index) { var data = remainingDocs[index].data() as Map<String, dynamic>; return _buildServiceCard(context, data); }))])); });
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> data) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String name = data['name'] ?? 'Layanan';
    int price = data['price'] ?? 0;
    String? imageUrl = data['imageUrl'];

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(serviceName: name, basePrice: price)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), image: (imageUrl != null && imageUrl.isNotEmpty) ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null), child: (imageUrl == null || imageUrl.isEmpty) ? Icon(Icons.local_laundry_service_rounded, size: 28, color: Colors.blue.shade700) : null), const SizedBox(height: 12), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(height: 4), Text(price == 0 ? "Tanya Admin" : currencyFormatter.format(price), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold))])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text("Mau layanan apa bos?", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          _buildMenuItem(context, icon: Icons.add_circle_outline_rounded, title: "Booking Order", subtitle: "Pilih layanan manual.", color: Colors.blueAccent, onTap: () { Navigator.pop(context); _showServiceSelector(context); }),
          const SizedBox(height: 12),
          // MODIFIKASI: PANGGIL MODAL AI
          _buildMenuItem(context, icon: Icons.auto_awesome, title: "Cek Kondisi (AI)", subtitle: "Foto sepatu, biar kami analisa.", color: Colors.purpleAccent, onTap: () { Navigator.pop(context); _showAIShoeCheckModal(context); }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 4), Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600))])), Icon(Icons.chevron_right, color: Colors.grey.shade400)])));
  }
}