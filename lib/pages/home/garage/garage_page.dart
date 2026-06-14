import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:chupatu_mobile/pages/order/booking_page.dart';
import 'package:chupatu_mobile/pages/home/garage/shoe_detail_page.dart';
import 'package:chupatu_mobile/pages/order/custom_service_page.dart';
import 'package:lottie/lottie.dart';

class ApiConfig {
  static const String baseUrl = 'https://malik-pseudomonocyclic-misti.ngrok-free.dev/api';
  static const String uploadUrl = '$baseUrl/upload';

  // Header global untuk bypass warning Ngrok di semua gambar
  static const Map<String, String> ngrokHeaders = {
    'ngrok-skip-browser-warning': 'true',
    'User-Agent': 'ChupatuApp'
  };
}

class GaragePage extends StatefulWidget {
  final bool isFromNavbar;
  const GaragePage({super.key, this.isFromNavbar = false});

  @override
  State<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends State<GaragePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String _selectedBrandFilter = 'All';

  // --- 1. FUNGSI HAPUS SEPATU ---
  Future<void> _deleteShoe(String docId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Sepatu?"),
        content: const Text("Koleksi ini bakal hilang dari garasi lo."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid)
          .collection('garage').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sepatu berhasil dihapus 🗑️")));
      }
    }
  }

  // --- 2. FUNGSI FORM SEPATU (PINTAR: BISA TAMBAH & EDIT SEKALIGUS) ---
  void _showShoeFormModal(BuildContext context, AppThemeData theme, {String? docId, Map<String, dynamic>? currentData}) {
    final bool isEdit = docId != null && currentData != null;

    final nameCtrl = TextEditingController(text: isEdit ? currentData['name'] : '');
    final brandCtrl = TextEditingController(text: isEdit ? currentData['brand'] : '');
    final sizeCtrl = TextEditingController(text: isEdit ? currentData['size'] : '');
    final noteCtrl = TextEditingController(text: isEdit ? currentData['note'] : '');

    File? selectedImageFile;
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // Siapkan gambar untuk ditampilkan di form
          DecorationImage? decImage;
          if (selectedImageFile != null) {
            decImage = DecorationImage(image: FileImage(selectedImageFile!), fit: BoxFit.cover);
          } else if (isEdit && currentData['image'] != null && currentData['image'].toString().isNotEmpty) {
            decImage = DecorationImage(
              image: NetworkImage(
                currentData['image'].toString().replaceAll("http://", "https://"),
                headers: ApiConfig.ngrokHeaders, // Wajib pakai ini biar gak 403
              ),
              fit: BoxFit.cover,
            );
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              decoration: BoxDecoration(color: theme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text(isEdit ? "Edit Koleksi" : "Tambah Koleksi Baru", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildInputLabel(isEdit ? "Ganti Foto (Opsional)" : "Foto Sepatu", theme),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: isProcessing ? null : () async {
                            final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
                            if (picked != null) setModalState(() => selectedImageFile = File(picked.path));
                          },
                          child: Container(
                            height: 150, width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.primary.withOpacity(0.2)),
                              image: decImage,
                            ),
                            child: decImage == null ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 40, color: theme.primary),
                                const SizedBox(height: 8),
                                Text("Tap untuk memilih foto", style: GoogleFonts.plusJakartaSans(color: theme.primary, fontSize: 12))
                              ],
                            ) : null,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInputLabel("Nama Sepatu", theme),
                        _buildTextField(nameCtrl, "Contoh: Air Jordan 1 High", theme),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel("Brand", theme), _buildTextField(brandCtrl, "Nike, Adidas...", theme)])),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel("Ukuran (Size)", theme), _buildTextField(sizeCtrl, "42 / 9 US", theme, isNumber: true)])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInputLabel("Catatan Kondisi (Opsional)", theme),
                        _buildTextField(noteCtrl, "Ada noda di bagian sol...", theme, maxLines: 3),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : () async {
                        if (nameCtrl.text.isEmpty || brandCtrl.text.isEmpty || (!isEdit && selectedImageFile == null)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama, Brand, dan Foto wajib diisi!"), backgroundColor: Colors.orange));
                          return;
                        }

                        setModalState(() => isProcessing = true);
                        debugPrint("=== MULAI PROSES SIMPAN ===");

                        try {
                          String imageUrl = isEdit ? currentData['image'] : '';

                          if (selectedImageFile != null) {
                            debugPrint("1. Mengirim foto ke Laravel...");
                            var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadUrl));
                            request.headers.addAll({'Accept': 'application/json'});
                            request.files.add(await http.MultipartFile.fromPath('foto', selectedImageFile!.path));
                            request.fields['kategori'] = 'garage_shoes';

                            var res = await request.send();
                            debugPrint("2. Respon Laravel didapat! Status: ${res.statusCode}");

                            if (res.statusCode == 200) {
                              var resData = await res.stream.bytesToString();
                              imageUrl = json.decode(resData)['url'].toString().replaceAll("http://", "https://");
                              debugPrint("3. Link foto aman: $imageUrl");
                            } else {
                              var errorBody = await res.stream.bytesToString();
                              debugPrint("!!! ERROR DARI LARAVEL !!!: $errorBody");
                              throw "Gagal upload gambar ke server. Kode: ${res.statusCode}";
                            }
                          }

                          debugPrint("4. Menyusun data untuk Firebase...");
                          final Map<String, dynamic> shoeMap = {
                            'name': nameCtrl.text.trim(),
                            'brand': brandCtrl.text.trim(),
                            'size': sizeCtrl.text.trim(),
                            'note': noteCtrl.text.trim(),
                            'image': imageUrl,
                          };

                          // Ambil data user yang paling fresh biar ga nyangkut
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser == null) throw "Sesi login terputus!";

                          final collection = FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('garage');

                          debugPrint("5. Menulis ke database Firebase...");
                          if (isEdit) {
                            await collection.doc(docId).update(shoeMap);
                            debugPrint("6. Sukses update data lama!");
                          } else {
                            shoeMap['resultImage'] = '';
                            shoeMap['createdAt'] = FieldValue.serverTimestamp();
                            await collection.add(shoeMap);
                            debugPrint("6. Sukses tambah data baru!");
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "Koleksi diperbarui! ✨" : "Sepatu berhasil masuk garasi!"), backgroundColor: Colors.green));
                          }
                        } catch (e) {
                          debugPrint("!!! CATCH ERROR !!!: $e");
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
                        } finally {
                          if (mounted) setModalState(() => isProcessing = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: theme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5, shadowColor: theme.primary.withOpacity(0.4)),
                      child: isProcessing ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3) : Text(isEdit ? "Simpan Perubahan" : "Simpan ke Garasi", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 3. FUNGSI PILIH LAYANAN ---
  void _showServicePicker(BuildContext context, Map<String, dynamic> shoeData, AppThemeData theme) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(color: theme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(24), height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text("Mau diapakan sepatu ini?", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
            Text("${shoeData['brand']} - ${shoeData['name']}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('services').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("Belum ada layanan.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));

                  var services = snapshot.data!.docs;
                  return GridView.builder(
                    physics: const BouncingScrollPhysics(), itemCount: services.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.9),
                    itemBuilder: (context, index) {
                      var s = services[index].data() as Map<String, dynamic>;
                      String name = s['name'] ?? 'Layanan';
                      String price = s['price'] != null ? s['price'].toString() : 'Rp -';
                      String nameLower = name.toLowerCase();
                      String imageUrl = s['imageUrl'] ?? '';
                      Color color = theme.primary;

                      String? lottiePath;
                      if (nameLower.contains('deep')) { lottiePath = 'assets/lottie/water_drop.json'; color = Colors.blue; }
                      else if (nameLower.contains('fast')) { lottiePath = 'assets/lottie/Stopwatch.json'; color = Colors.orange; }
                      else if (nameLower.contains('yellow')) { lottiePath = 'assets/lottie/sparkle.json'; color = Colors.amber; }
                      else if (nameLower.contains('repair')) { lottiePath = 'assets/lottie/wrench.json'; color = Colors.grey; }
                      else if (nameLower.contains('repaint')) { lottiePath = 'assets/lottie/paint.json'; color = Colors.purple; }
                      else if (nameLower.contains('water')) { lottiePath = 'assets/lottie/umbrella.json'; color = Colors.teal; }
                      else if (nameLower.contains('custom')) { lottiePath = 'assets/lottie/pencil.json'; color = Colors.pink; }

                      Widget serviceIconWidget;
                      if (lottiePath != null) {
                        serviceIconWidget = SizedBox(height: 35, width: 35, child: Lottie.asset(lottiePath, fit: BoxFit.contain));
                      } else if (imageUrl.isNotEmpty) {
                        serviceIconWidget = ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, width: 35, height: 35, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.cleaning_services_rounded, color: color, size: 28)));
                      } else {
                        serviceIconWidget = Icon(Icons.cleaning_services_rounded, color: color, size: 28);
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          if (nameLower.contains('custom')) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => CustomServicePage(selectedShoe: shoeData)));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(serviceName: name, basePrice: int.tryParse(s['price'].toString()) ?? 0, selectedShoe: shoeData)));
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              serviceIconWidget, const SizedBox(height: 8),
                              Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textMain)),
                              Text(price, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: theme.background, elevation: 0, pinned: true, expandedHeight: 100.0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text("My Garage", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.w800)),
                  background: Container(color: theme.background),
                ),
                actions: [
                  StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('garage').snapshots(),
                      builder: (context, snapshot) {
                        List<String> brands = ['All'];
                        if (snapshot.hasData) {
                          brands.addAll(snapshot.data!.docs.map((doc) => (doc.data() as Map)['brand'].toString()).toSet());
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Container(
                            height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: brands.contains(_selectedBrandFilter) ? _selectedBrandFilter : 'All',
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.primary, size: 20),
                                dropdownColor: theme.surface, alignment: Alignment.centerRight,
                                style: GoogleFonts.plusJakartaSans(color: theme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                items: brands.map((String brand) => DropdownMenuItem<String>(value: brand, child: Text(brand))).toList(),
                                onChanged: (String? val) { if (val != null) setState(() => _selectedBrandFilter = val); },
                              ),
                            ),
                          ),
                        );
                      }
                  ),
                ],
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('garage').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  var shoesDocs = snapshot.data?.docs ?? [];
                  if (_selectedBrandFilter != 'All') {
                    shoesDocs = shoesDocs.where((doc) => (doc.data() as Map<String, dynamic>)['brand'] == _selectedBrandFilter).toList();
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 16, mainAxisSpacing: 16),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          if (index == shoesDocs.length) return _buildAddShoeCard(theme);
                          var doc = shoesDocs[index];
                          return _buildShoeCard(doc.id, doc.data() as Map<String, dynamic>, theme);
                        },
                        childCount: shoesDocs.length + 1,
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddShoeCard(AppThemeData theme) {
    return InkWell(
      onTap: () => _showShoeFormModal(context, theme), // Menggunakan fungsi gabungan!
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(color: theme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.primary.withOpacity(0.3), style: BorderStyle.solid, width: 2)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 40, color: theme.primary), const SizedBox(height: 12),
            Text("Tambah\nKoleksi", textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.primary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildShoeCard(String docId, Map<String, dynamic> data, AppThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShoeDetailPage(shoeData: data))),
      child: Container(
        decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      (data['image'] ?? '').toString().replaceAll("http://", "https://"),
                      headers: ApiConfig.ngrokHeaders, // Wajib pakai global headers
                      width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (c,e,s) => Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image_not_supported))),
                    ),
                  ),
                  Positioned(
                    top: 5, right: 5,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      color: theme.surface, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      onSelected: (val) {
                        if (val == 'edit') _showShoeFormModal(context, theme, docId: docId, currentData: data); // Pakai fungsi gabungan!
                        if (val == 'delete') _deleteShoe(docId);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text("Edit Info")])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18), SizedBox(width: 8), Text("Hapus", style: TextStyle(color: Colors.red))])),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                      child: Text(data['brand'] ?? '-', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Sepatu', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain)),
                        Text("Size: ${data['size'] ?? '-'}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity, height: 32,
                      child: OutlinedButton(
                        onPressed: () => _showServicePicker(context, data, theme),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: theme.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero),
                        child: Text("Pilih Layanan", style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primary)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, AppThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textMain)));
  }

  Widget _buildTextField(TextEditingController controller, String hint, AppThemeData theme, {bool isNumber = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, maxLines: maxLines,
        decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey.shade400), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      ),
    );
  }
}