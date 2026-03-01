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

class ApiConfig {
  static const String baseUrl =
      'https://malik-pseudomonocyclic-misti.ngrok-free.dev/api';
  static const String uploadUrl = '$baseUrl/upload';
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
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users').doc(user!.uid)
            .collection('garage').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sepatu berhasil dihapus 🗑️")));
        }
      } catch (e) {
        debugPrint("Error Hapus: $e");
      }
    }
  }

  // --- 2. FUNGSI EDIT SEPATU ---
  void _showEditShoeModal(BuildContext context, String docId,
      Map<String, dynamic> currentData, AppThemeData theme) {

    final nameController = TextEditingController(text: currentData['name']);
    final brandController = TextEditingController(text: currentData['brand']);
    final sizeController = TextEditingController(text: currentData['size']);
    final noteController = TextEditingController(text: currentData['note']);

    File? newImageFile;
    bool isUpdating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: BoxDecoration(color: theme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration:
                BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text("Edit Info Sepatu", style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.bold, color: theme.textMain)),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildInputLabel("Ganti Foto (Opsional)", theme),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery, imageQuality: 50);
                          if (picked != null) setModalState(() =>
                          newImageFile = File(picked.path));
                        },
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.primary.withOpacity(0.2)),
                            image: DecorationImage(
                              image: newImageFile != null
                                  ? FileImage(newImageFile!)
                                  : NetworkImage(currentData['image']) as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: const Center(child: Icon(Icons.camera_alt,
                              color: Colors.white70, size: 40)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInputLabel("Nama Sepatu", theme),
                      _buildTextField(nameController, "Nama Sepatu", theme),
                      const SizedBox(height: 16),
                      _buildInputLabel("Brand", theme),
                      _buildTextField(brandController, "Brand", theme),
                      const SizedBox(height: 16),
                      _buildInputLabel("Ukuran", theme),
                      _buildTextField(sizeController, "Size", theme, isNumber: true),
                      const SizedBox(height: 16),
                      _buildInputLabel("Catatan", theme),
                      _buildTextField(noteController, "Catatan", theme, maxLines: 3),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : () async {
                      setModalState(() => isUpdating = true);
                      try {
                        String imageUrl = currentData['image'];

                        if (newImageFile != null) {
                          var request = http.MultipartRequest('POST',
                              Uri.parse(ApiConfig.uploadUrl));
                          request.headers.addAll({'Accept': 'application/json'});
                          request.files.add(await http.MultipartFile.fromPath(
                              'foto', newImageFile!.path));
                          request.fields['kategori'] = 'garage_shoes';
                          var res = await request.send();
                          if (res.statusCode == 200) {
                            var resBody = await res.stream.bytesToString();
                            imageUrl = json.decode(resBody)['url'].toString()
                                .replaceAll("http://", "https://");
                          }
                        }

                        await FirebaseFirestore.instance
                            .collection('users').doc(user!.uid)
                            .collection('garage').doc(docId).update({
                          'name': nameController.text.trim(),
                          'brand': brandController.text.trim(),
                          'size': sizeController.text.trim(),
                          'note': noteController.text.trim(),
                          'image': imageUrl,
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Koleksi diperbarui! ✨"),
                                  backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        debugPrint("Error Update: $e");
                      } finally {
                        if (mounted) setModalState(() => isUpdating = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: theme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: isUpdating ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Simpan Perubahan", style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- FUNGSI PILIH LAYANAN (TETAP SAMA) ---
  void _showServicePicker(BuildContext context, Map<String, dynamic> shoeData,
      AppThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Mau diapakan sepatu ini?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textMain,
                ),
              ),
              Text(
                "${shoeData['brand']} - ${shoeData['name']}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('services').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "Belum ada layanan tersedia.",
                          style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                        ),
                      );
                    }

                    var services = snapshot.data!.docs;

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: services.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemBuilder: (context, index) {
                        var s = services[index].data() as Map<String, dynamic>;
                        String name = s['name'] ?? 'Layanan';
                        String price = s['price'] != null ? s['price'].toString() : 'Rp -';

                        IconData icon = Icons.cleaning_services_rounded;
                        Color color = theme.primary;
                        String nameLower = name.toLowerCase();

                        if (nameLower.contains('deep')) { icon = Icons.water_drop_rounded; color = Colors.blue; }
                        else if (nameLower.contains('fast')) { icon = Icons.timer_rounded; color = Colors.orange; }
                        else if (nameLower.contains('yellow')) { icon = Icons.wb_sunny_rounded; color = Colors.amber; }
                        else if (nameLower.contains('repair')) { icon = Icons.build_rounded; color = Colors.grey; }
                        else if (nameLower.contains('repaint')) { icon = Icons.format_paint_rounded; color = Colors.purple; }
                        else if (nameLower.contains('water')) { icon = Icons.umbrella_rounded; color = Colors.teal; }

                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);

                            if (nameLower.contains('custom')) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomServicePage(
                                    selectedShoe: shoeData,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingPage(
                                    serviceName: name,
                                    basePrice: int.tryParse(s['price'].toString()) ?? 0,
                                    selectedShoe: shoeData,
                                  ),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, color: color, size: 28),
                                const SizedBox(height: 8),
                                Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textMain,
                                  ),
                                ),
                                Text(
                                  price,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
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
        );
      },
    );
  }

  // --- MODAL TAMBAH SEPATU (TETAP SAMA) ---
  void _showAddShoeModal(BuildContext context, AppThemeData theme) {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final sizeController = TextEditingController();
    final noteController = TextEditingController();

    File? selectedImageFile;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Tambah Koleksi Baru",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textMain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildInputLabel("Foto Sepatu", theme),
                          const SizedBox(height: 8),

                          GestureDetector(
                            onTap: isUploading ? null : () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 50,
                              );
                              if (picked != null) {
                                setModalState(() => selectedImageFile = File(picked.path));
                              }
                            },
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.primary.withOpacity(0.2)),
                                image: selectedImageFile != null
                                    ? DecorationImage(
                                  image: FileImage(selectedImageFile!),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: selectedImageFile == null
                                  ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 40,
                                    color: theme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tap untuk memilih foto",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: theme.primary,
                                      fontSize: 12,
                                    ),
                                  )
                                ],
                              )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildInputLabel("Nama Sepatu", theme),
                          _buildTextField(nameController, "Contoh: Air Jordan 1 High", theme),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel("Brand", theme),
                                    _buildTextField(brandController, "Nike, Adidas...", theme),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel("Ukuran (Size)", theme),
                                    _buildTextField(sizeController, "42 / 9 US", theme, isNumber: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildInputLabel("Catatan Kondisi (Opsional)", theme),
                          _buildTextField(noteController, "Ada noda di bagian sol...", theme, maxLines: 3),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isUploading ? null : () async {
                          if (nameController.text.isEmpty ||
                              brandController.text.isEmpty ||
                              selectedImageFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Nama, Brand, dan Foto wajib diisi!"),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setModalState(() => isUploading = true);

                          try {
                            var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadUrl));
                            request.headers.addAll({
                              'Accept': 'application/json',
                            });
                            request.files.add(await http.MultipartFile.fromPath('foto', selectedImageFile!.path));
                            request.fields['kategori'] = 'garage_shoes';

                            var response = await request.send();

                            if (response.statusCode == 200) {
                              var resData = await response.stream.bytesToString();
                              var jsonRes = json.decode(resData);

                              String uploadedUrl = jsonRes['url'].toString().replaceAll("http://", "https://");

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user!.uid)
                                  .collection('garage')
                                  .add({
                                'name': nameController.text.trim(),
                                'brand': brandController.text.trim(),
                                'size': sizeController.text.trim(),
                                'note': noteController.text.trim(),
                                'image': uploadedUrl,
                                'resultImage': '',
                                'createdAt': FieldValue.serverTimestamp()
                              });

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Sepatu berhasil masuk garasi!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              throw "Server error code: ${response.statusCode}";
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Gagal menyimpan: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setModalState(() => isUploading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 5,
                          shadowColor: theme.primary.withOpacity(0.4),
                        ),
                        child: isUploading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                            : Text(
                          "Simpan ke Garasi",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
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
                backgroundColor: theme.background,
                elevation: 0,
                pinned: true,
                expandedHeight: 100.0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text(
                    "My Garage",
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.textMain,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  background: Container(color: theme.background),
                ),
                actions: [
                  StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users')
                          .doc(user!.uid).collection('garage').snapshots(),
                      builder: (context, snapshot) {
                        List<String> brands = ['All'];
                        if (snapshot.hasData) {
                          brands.addAll(snapshot.data!.docs
                              .map((doc) => (doc.data() as Map)['brand'].toString())
                              .toSet());
                        }

                        String dropdownValue = brands.contains(_selectedBrandFilter)
                            ? _selectedBrandFilter
                            : 'All';

                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: dropdownValue,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: theme.primary,
                                  size: 20,
                                ),
                                dropdownColor: theme.surface,
                                alignment: Alignment.centerRight,
                                style: GoogleFonts.plusJakartaSans(
                                  color: theme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                items: brands.map((String brand) {
                                  return DropdownMenuItem<String>(
                                    value: brand,
                                    child: Text(brand),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedBrandFilter = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      }
                  ),
                ],
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users')
                    .doc(user!.uid).collection('garage')
                    .orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  var shoesDocs = snapshot.data?.docs ?? [];

                  if (_selectedBrandFilter != 'All') {
                    shoesDocs = shoesDocs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data['brand'] == _selectedBrandFilter;
                    }).toList();
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          if (index == shoesDocs.length) {
                            return _buildAddShoeCard(theme);
                          }
                          var doc = shoesDocs[index];
                          var data = doc.data() as Map<String, dynamic>;
                          return _buildShoeCard(doc.id, data, theme);
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

  // --- WIDGET ADD SHOE CARD (TETAP SAMA) ---
  Widget _buildAddShoeCard(AppThemeData theme) {
    return InkWell(
      onTap: () => _showAddShoeModal(context, theme),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primary.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 40, color: theme.primary),
            const SizedBox(height: 12),
            Text(
              "Tambah\nKoleksi",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: theme.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET KARTU SEPATU (TAMBAH MENU EDIT & HAPUS) ---
  Widget _buildShoeCard(String docId, Map<String, dynamic> data, AppThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShoeDetailPage(shoeData: data),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ]
        ),
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
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c,e,s) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.image_not_supported)),
                      ),
                    ),
                  ),

                  // MENU POPUP EDIT/HAPUS (BARU)
                  Positioned(
                    top: 5, right: 5,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      color: theme.surface,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      onSelected: (val) {
                        if (val == 'edit') _showEditShoeModal(context, docId, data, theme);
                        if (val == 'delete') _deleteShoe(docId);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8), Text("Edit Info")
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text("Hapus", style: TextStyle(color: Colors.red))
                          ]),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data['brand'] ?? '-',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                        Text(
                          data['name'] ?? 'Sepatu',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textMain,
                          ),
                        ),
                        Text(
                          "Size: ${data['size'] ?? '-'}",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () => _showServicePicker(context, data, theme),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          "Pilih Layanan",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.primary,
                          ),
                        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.textMain,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, AppThemeData theme,
      {bool isNumber = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}