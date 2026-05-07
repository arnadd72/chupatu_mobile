import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chupatu_mobile/main.dart'; // IMPORT TEMA

class ManagePromoPage extends StatefulWidget {
  const ManagePromoPage({super.key});

  @override
  State<ManagePromoPage> createState() => _ManagePromoPageState();
}

// Tambahkan SingleTickerProviderStateMixin untuk TabBar
class _ManagePromoPageState extends State<ManagePromoPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  bool _isLoading = false;

  // =========================================================
  // STATE & CONTROLLER UNTUK TAB 1: BANNER PROMO
  // =========================================================
  final _bannerTitleCtrl = TextEditingController();
  final _bannerDescCtrl = TextEditingController();
  File? _imageFile;
  String? _editingBannerId;
  String? _currentBannerImageUrl;
  bool _isBannerActive = true;
  String? _selectedPromoCodeId; // Link ke Kode Promo

  final String _defaultPromoImage =
      "https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=800";

  // =========================================================
  // STATE & CONTROLLER UNTUK TAB 2: KODE PROMO (VOUCHER)
  // =========================================================
  final _voucherCodeCtrl = TextEditingController(); // cth: DISKON50
  final _voucherDiscountCtrl = TextEditingController(); // cth: 50000
  final _voucherMaxUsageCtrl = TextEditingController(); // cth: 100
  String? _editingVoucherId;
  bool _isVoucherActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerTitleCtrl.dispose();
    _bannerDescCtrl.dispose();
    _voucherCodeCtrl.dispose();
    _voucherDiscountCtrl.dispose();
    _voucherMaxUsageCtrl.dispose();
    super.dispose();
  }

  // =========================================================
  // LOGIKA TAB 1: BANNER PROMO (CLOUDINARY & FIRESTORE)
  // =========================================================
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _resetBannerForm() {
    _bannerTitleCtrl.clear();
    _bannerDescCtrl.clear();
    setState(() {
      _imageFile = null;
      _editingBannerId = null;
      _currentBannerImageUrl = null;
      _isBannerActive = true;
      _selectedPromoCodeId = null;
    });
  }

  void _setEditBanner(Map<String, dynamic> data, String docId) {
    _bannerTitleCtrl.text = data['title'] ?? '';
    _bannerDescCtrl.text = data['description'] ?? '';
    setState(() {
      _editingBannerId = docId;
      _currentBannerImageUrl = data['imageUrl'];
      _isBannerActive = data['isActive'] ?? true;
      _selectedPromoCodeId = data['promoCodeId'];
      _imageFile = null; // Reset file lokal
      _tabController.animateTo(0); // Pindah ke tab banner
    });
  }

  Future<void> _saveBanner() async {
    if (_bannerTitleCtrl.text.isEmpty || _bannerDescCtrl.text.isEmpty) {
      _showToast("Judul dan Deskripsi wajib diisi!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _currentBannerImageUrl ?? _defaultPromoImage;

      // 1. UPLOAD CLOUDINARY (Hanya jika ada foto baru yang dipilih)
      if (_imageFile != null) {
        final cloudinaryUrl = Uri.parse(
            'https://api.cloudinary.com/v1_1/dyiicub10/image/upload'
        );
        final request = http.MultipartRequest('POST', cloudinaryUrl)
          ..fields['upload_preset'] = 'chupatu_promo'
          ..files.add(
              await http.MultipartFile.fromPath('file', _imageFile!.path)
          );

        final response = await request.send();
        if (response.statusCode == 200) {
          final resData = await response.stream.bytesToString();
          imageUrl = jsonDecode(resData)['secure_url'];
        } else {
          throw Exception("Gagal upload gambar ke Cloudinary.");
        }
      }

      // 2. SIAPKAN DATA
      final bannerData = {
        'title': _bannerTitleCtrl.text,
        'description': _bannerDescCtrl.text,
        'imageUrl': imageUrl,
        'isActive': _isBannerActive,
        'promoCodeId': _selectedPromoCodeId, // Bisa null kalau ga ada promo code
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 3. SIMPAN KE FIRESTORE (CREATE ATAU UPDATE)
      if (_editingBannerId == null) {
        bannerData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('promos').add(bannerData);
        _showToast("Banner baru berhasil dipublikasikan!");
      } else {
        await FirebaseFirestore.instance
            .collection('promos')
            .doc(_editingBannerId)
            .update(bannerData);
        _showToast("Perubahan banner berhasil disimpan!");
      }

      _resetBannerForm();
    } catch (e) {
      _showToast("Gagal menyimpan: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBanner(String docId) async {
    await FirebaseFirestore.instance.collection('promos').doc(docId).delete();
    _showToast("Banner dihapus!");
  }

  // =========================================================
  // LOGIKA TAB 2: KODE VOUCHER
  // =========================================================
  void _resetVoucherForm() {
    _voucherCodeCtrl.clear();
    _voucherDiscountCtrl.clear();
    _voucherMaxUsageCtrl.clear();
    setState(() {
      _editingVoucherId = null;
      _isVoucherActive = true;
    });
  }

  void _setEditVoucher(Map<String, dynamic> data, String docId) {
    _voucherCodeCtrl.text = data['code'] ?? '';
    _voucherDiscountCtrl.text = (data['discountAmount'] ?? 0).toString();
    _voucherMaxUsageCtrl.text = (data['maxUsage'] ?? 0).toString();
    setState(() {
      _editingVoucherId = docId;
      _isVoucherActive = data['isActive'] ?? true;
      _tabController.animateTo(1); // Pindah ke tab voucher
    });
  }

  Future<void> _saveVoucher() async {
    if (_voucherCodeCtrl.text.isEmpty || _voucherDiscountCtrl.text.isEmpty) {
      _showToast("Kode dan Diskon wajib diisi!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final voucherData = {
        'code': _voucherCodeCtrl.text.toUpperCase().replaceAll(' ', ''),
        'discountAmount': int.tryParse(_voucherDiscountCtrl.text) ?? 0,
        'maxUsage': int.tryParse(_voucherMaxUsageCtrl.text) ?? 0,
        'isActive': _isVoucherActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingVoucherId == null) {
        voucherData['currentUsage'] = 0;
        voucherData['usedBy'] = []; // Array kosong untuk nyimpen ID User
        voucherData['createdAt'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance
            .collection('promo_codes')
            .add(voucherData);
        _showToast("Kode voucher berhasil dibuat!");
      } else {
        await FirebaseFirestore.instance
            .collection('promo_codes')
            .doc(_editingVoucherId)
            .update(voucherData);
        _showToast("Kode voucher berhasil diupdate!");
      }

      _resetVoucherForm();
    } catch (e) {
      _showToast("Gagal menyimpan voucher: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVoucher(String docId) async {
    await FirebaseFirestore.instance
        .collection('promo_codes')
        .doc(docId)
        .delete();
    _showToast("Voucher dihapus!");
  }

  // Dialog untuk melihat siapa saja yang menggunakan kode ini
  void _showUsedByUsers(List<dynamic> users) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Digunakan Oleh:"),
        content: SizedBox(
          width: double.maxFinite,
          child: users.isEmpty
              ? const Text("Belum ada yang menggunakan kode ini.")
              : ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.person),
                // Asumsi di array tersimpan User ID / Email
                title: Text(users[index].toString()),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          )
        ],
      ),
    );
  }

  void _showToast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message))
      );
    }
  }

  // =========================================================
  // UI: BUILDER UTAMA
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text(
                "Promo & Voucher Manager",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: theme.textMain,
                ),
              ),
              backgroundColor: theme.surface,
              elevation: 1,
              iconTheme: IconThemeData(color: theme.textMain),
              bottom: TabBar(
                controller: _tabController,
                labelColor: theme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: theme.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.image), text: "Banner Promo"),
                  Tab(icon: Icon(Icons.local_offer), text: "Kode Voucher"),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildBannerTab(theme),
                _buildVoucherTab(theme),
              ],
            ),
          );
        }
    );
  }

  // =========================================================
  // UI: TAB 1 (BANNER PROMO)
  // =========================================================
  Widget _buildBannerTab(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER FORM
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _editingBannerId == null ? "Buat Banner" : "Edit Banner",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textMain,
                ),
              ),
              if (_editingBannerId != null)
                TextButton(
                  onPressed: _resetBannerForm,
                  child: const Text("Batal Edit", style: TextStyle(color: Colors.red)),
                )
            ],
          ),
          const SizedBox(height: 16),

          // UPLOAD IMAGE
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                image: _imageFile != null
                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                    : (_currentBannerImageUrl != null
                    ? DecorationImage(
                    image: NetworkImage(_currentBannerImageUrl!),
                    fit: BoxFit.cover
                )
                    : null),
              ),
              child: (_imageFile == null && _currentBannerImageUrl == null)
                  ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
                    SizedBox(height: 8),
                    Text("Upload Banner Gambar", style: TextStyle(color: Colors.grey)),
                  ]
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // INPUT FIELDS
          TextField(
              controller: _bannerTitleCtrl,
              style: TextStyle(color: theme.textMain),
              decoration: InputDecoration(
                labelText: "Judul Banner",
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary)),
              )
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _bannerDescCtrl,
              maxLines: 2,
              style: TextStyle(color: theme.textMain),
              decoration: InputDecoration(
                labelText: "Deskripsi",
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary)),
              )
          ),
          const SizedBox(height: 16),

          // LINK KE KODE PROMO (DROPDOWN REAL-TIME)
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('promo_codes').where('isActive', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                List<DropdownMenuItem<String>> items = [
                  const DropdownMenuItem(value: null, child: Text("Tidak Sematkan Kode Promo"))
                ];

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    items.add(DropdownMenuItem(
                      value: doc.id,
                      child: Text("Kode: ${data['code']} (Potongan ${data['discountAmount']})"),
                    ));
                  }
                }

                return DropdownButtonFormField<String>(
                  value: _selectedPromoCodeId,
                  items: items,
                  onChanged: (val) => setState(() => _selectedPromoCodeId = val),
                  decoration: InputDecoration(
                    labelText: "Sematkan Voucher ke Banner",
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary)),
                  ),
                  style: TextStyle(color: theme.textMain),
                  dropdownColor: theme.surface,
                );
              }
          ),
          const SizedBox(height: 16),

          // TOGGLE ACTIVE
          SwitchListTile(
            title: Text("Status Banner Aktif", style: TextStyle(color: theme.textMain)),
            value: _isBannerActive,
            activeColor: theme.primary,
            onChanged: (val) => setState(() => _isBannerActive = val),
          ),
          const SizedBox(height: 16),

          // BUTTON SAVE
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveBanner,
              style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                _editingBannerId == null ? "SIMPAN BANNER BARU" : "UPDATE BANNER",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 32),
          Text("Riwayat Banner", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
          const Divider(),

          // LIST BANNER (REALTIME)
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('promos').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("Belum ada banner.");

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isActive = data['isActive'] ?? true;

                    return Card(
                      color: theme.surface,
                      child: ListTile(
                        leading: Image.network(data['imageUrl'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                        title: Text(data['title'] ?? '', style: TextStyle(color: theme.textMain, fontWeight: FontWeight.bold)),
                        subtitle: Text(isActive ? "🟢 Tayang" : "🔴 Disembunyikan", style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _setEditBanner(data, doc.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteBanner(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
          )
        ],
      ),
    );
  }

  // =========================================================
  // UI: TAB 2 (KODE VOUCHER)
  // =========================================================
  Widget _buildVoucherTab(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _editingVoucherId == null ? "Buat Voucher Baru" : "Edit Voucher",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textMain,
                ),
              ),
              if (_editingVoucherId != null)
                TextButton(
                  onPressed: _resetVoucherForm,
                  child: const Text("Batal Edit", style: TextStyle(color: Colors.red)),
                )
            ],
          ),
          const SizedBox(height: 16),

          TextField(
              controller: _voucherCodeCtrl,
              style: TextStyle(color: theme.textMain, fontWeight: FontWeight.bold, letterSpacing: 2),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: "Kode Voucher (Cth: CHUPATU2026)",
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary)),
              )
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                    controller: _voucherDiscountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.textMain),
                    decoration: InputDecoration(
                      labelText: "Nominal Diskon (Rp)",
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary)),
                    )
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                    controller: _voucherMaxUsageCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.textMain),
                    decoration: InputDecoration(
                      labelText: "Batas Kuota Pemakaian",
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary)),
                    )
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: Text("Voucher Bisa Digunakan", style: TextStyle(color: theme.textMain)),
            value: _isVoucherActive,
            activeColor: theme.primary,
            onChanged: (val) => setState(() => _isVoucherActive = val),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveVoucher,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                _editingVoucherId == null ? "SIMPAN VOUCHER" : "UPDATE VOUCHER",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 32),
          Text("Daftar Kode Voucher", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
          const Divider(),

          // LIST VOUCHER (REALTIME)
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('promo_codes').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("Belum ada voucher.");

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    bool isActive = data['isActive'] ?? true;
                    int maxUsage = data['maxUsage'] ?? 0;
                    int currentUsage = data['currentUsage'] ?? 0;
                    List<dynamic> usedBy = data['usedBy'] ?? [];

                    return Card(
                      color: theme.surface,
                      child: ExpansionTile(
                        leading: Icon(Icons.local_activity, color: isActive ? Colors.teal : Colors.grey),
                        title: Text(data['code'] ?? '', style: TextStyle(color: theme.textMain, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        subtitle: Text("Potongan: Rp ${data['discountAmount']} | Terpakai: $currentUsage / $maxUsage", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Colors.grey.withOpacity(0.05),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.people, size: 18),
                                  label: const Text("Lihat Pengguna"),
                                  onPressed: () => _showUsedByUsers(usedBy),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text("Edit"),
                                  onPressed: () => _setEditVoucher(data, doc.id),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  label: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                  onPressed: () => _deleteVoucher(doc.id),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              }
          )
        ],
      ),
    );
  }
}