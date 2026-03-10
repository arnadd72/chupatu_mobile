import 'dart:io';
import 'dart:convert';
import 'dart:async'; // WAJIB untuk Google Maps Completer
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/order/payment_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // WAJIB untuk Map Picker

// --- VARIABEL GLOBAL DRAFT ---
Map<String, dynamic> _bookingDraft = {};

class ApiConfig {
  static const String baseUrl =
      'https://malik-pseudomonocyclic-misti.ngrok-free.dev/api';
  static const String uploadUrl = '$baseUrl/upload';
}

class BookingPage extends StatefulWidget {
  final String serviceName;
  final int basePrice;
  final Map<String, dynamic>? selectedShoe;

  const BookingPage({
    super.key,
    required this.serviceName,
    required this.basePrice,
    this.selectedShoe,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _shoeDetailController = TextEditingController();
  final _noteController = TextEditingController();
  final _mainAddressController = TextEditingController();
  final _detailAddressController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCategory = 'Sneakers';
  final List<String> _shoeCategories = [
    'Sneakers', 'Boots', 'Flat Shoes', 'Heels/Wedges',
    'Formal/Pantofel', 'Olahraga', 'Lainnya'
  ];

  DateTime? _selectedDate;
  String _selectedTime = 'Pagi (09-12)';

  bool _isDeliveryIncluded = true;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoadingUserData = true;
  bool _isUploading = false;

  // Koordinat Asli Customer
  GeoPoint? _customerLocation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    if (widget.selectedShoe != null) {
      String brand = widget.selectedShoe!['brand'] ?? '';
      String name = widget.selectedShoe!['name'] ?? '';
      _shoeDetailController.text = "$brand - $name";

      if (widget.selectedShoe!['note'] != null) {
        _noteController.text = widget.selectedShoe!['note'];
      }
    }
  }

  Future<String?> _uploadFotoKeLaravel() async {
    if (widget.selectedShoe != null && widget.selectedShoe!['image'] != null) {
      return widget.selectedShoe!['image'];
    }

    if (_selectedImage == null) return null;
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadUrl));
      request.files.add(await http.MultipartFile.fromPath('foto', _selectedImage!.path));
      request.fields['kategori'] = 'order_customer';

      var response = await request.send();
      if (response.statusCode == 200) {
        var resData = await response.stream.bytesToString();
        var jsonRes = json.decode(resData);
        return jsonRes['url'];
      }
      return null;
    } catch (e) {
      debugPrint("Gagal upload: $e");
      return null;
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUserData = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      Map<String, dynamic> userData = {};
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) userData = doc.data()!;
      }

      if (_bookingDraft.isNotEmpty && _bookingDraft['service'] == widget.serviceName) {
        _loadDraft();
        if (_phoneController.text.isEmpty) {
          _phoneController.text = userData['phoneNumber'] ?? userData['phone'] ?? '';
        }
      } else {
        if (userData.isNotEmpty) {
          setState(() {
            _phoneController.text = userData['phoneNumber'] ?? userData['phone'] ?? '';
            _mainAddressController.text = userData['address'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal load user data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingUserData = false);
    }
  }

  void _showSavedAddressPicker(AppThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pilih Alamat Tersimpan", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('addresses').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("Belum ada alamat tersimpan.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
                    }

                    return ListView.separated(
                      itemCount: snapshot.data!.docs.length,
                      separatorBuilder: (ctx, i) => const Divider(),
                      itemBuilder: (context, index) {
                        var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.location_on_outlined, color: theme.primary),
                          title: Text(data['label'] ?? 'Alamat', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                          subtitle: Text("${data['fullAddress']}\n(${data['detail']})", maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 12)),
                          onTap: () {
                            setState(() {
                              _mainAddressController.text = data['fullAddress'] ?? '';
                              _detailAddressController.text = data['detail'] ?? '';
                              _customerLocation = null; // Reset biar bisa dilacak ulang
                            });
                            Navigator.pop(context);
                          },
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

  Future<void> _checkAndSaveNewAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String currentAddress = _mainAddressController.text.trim();
    String currentDetail = _detailAddressController.text.trim();
    if (currentAddress.isEmpty) return;

    final query = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('addresses').where('fullAddress', isEqualTo: currentAddress).get();

    if (query.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('addresses').add({
        'label': 'Alamat Baru (${DateFormat('dd/MM').format(DateTime.now())})',
        'fullAddress': currentAddress,
        'detail': currentDetail,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _loadDraft() {
    setState(() {
      if (widget.selectedShoe == null) {
        _shoeDetailController.text = _bookingDraft['shoeDetail'] ?? '';
        _noteController.text = _bookingDraft['note'] ?? '';
        _selectedCategory = _bookingDraft['category'] ?? 'Sneakers';
      }
      _mainAddressController.text = _bookingDraft['mainAddress'] ?? '';
      _detailAddressController.text = _bookingDraft['detailAddress'] ?? '';
      _phoneController.text = _bookingDraft['phoneNumber'] ?? '';
      _selectedTime = _bookingDraft['time'] ?? 'Pagi (09-12)';
      _isDeliveryIncluded = _bookingDraft['isDelivery'] ?? true;
    });
  }

  void _saveDraft() {
    _bookingDraft = {
      'service': widget.serviceName,
      'shoeDetail': _shoeDetailController.text,
      'note': _noteController.text,
      'mainAddress': _mainAddressController.text,
      'detailAddress': _detailAddressController.text,
      'phoneNumber': _phoneController.text,
      'category': _selectedCategory,
      'time': _selectedTime,
      'isDelivery': _isDeliveryIncluded,
    };
  }

  @override
  void dispose() {
    _saveDraft();
    _shoeDetailController.dispose();
    _noteController.dispose();
    _mainAddressController.dispose();
    _detailAddressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, AppThemeData theme) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: theme.primary,
            colorScheme: ColorScheme.light(primary: theme.primary, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  // 👇 FUNGSI BARU: BUKA MAP PICKER 👇
  Future<void> _openMapPicker() async {
    // Tampilkan loading sebentar
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    LatLng initialLoc = const LatLng(-6.974001, 107.630348); // Default Telkom

    try {
      // Coba dapet GPS HP sekarang biar petanya langsung pas
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      initialLoc = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("GPS gagal, pakai default.");
    }

    if (!mounted) return;
    Navigator.pop(context); // Tutup loading

    // Buka Halaman Peta Pemilih
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapSelectionScreen(initialLocation: initialLoc)),
    );

    // Kalau user mencet konfirmasi di peta
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _customerLocation = GeoPoint(result['latitude'], result['longitude']);
        _mainAddressController.text = result['address'];
      });
    }
  }

  void _goToPayment() async {
    if (_shoeDetailController.text.isEmpty ||
        _mainAddressController.text.isEmpty ||
        _detailAddressController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi semua data!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isUploading = true);

    // Kalau user ngetik manual tapi gak buka peta
    if (_customerLocation == null) {
      try {
        List<Location> locations = await locationFromAddress(_mainAddressController.text);
        if (locations.isNotEmpty) {
          _customerLocation = GeoPoint(locations.first.latitude, locations.first.longitude);
        }
      } catch (e) {
        try {
          Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
          _customerLocation = GeoPoint(pos.latitude, pos.longitude);
        } catch (e2) {
          _customerLocation = const GeoPoint(-6.974001, 107.630348);
        }
      }
    }

    String? urlFotoLaravel = await _uploadFotoKeLaravel();

    if (widget.selectedShoe == null && urlFotoLaravel == null && _selectedImage != null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal upload foto ke server!")));
      return;
    }

    await _checkAndSaveNewAddress();
    setState(() => _isUploading = false);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          serviceName: widget.serviceName,
          basePrice: widget.basePrice,
          category: widget.selectedShoe != null ? "My Garage" : _selectedCategory,
          shoeDetail: _shoeDetailController.text,
          notes: _noteController.text,
          pickupDate: _selectedDate!,
          pickupTime: _selectedTime,
          isDelivery: _isDeliveryIncluded,
          mainAddress: _mainAddressController.text,
          detailAddress: _detailAddressController.text,
          shoeImageFile: _selectedImage,
          phoneNumber: _phoneController.text,
          shoeImageUrl: urlFotoLaravel,
          customerLocation: _customerLocation,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_shoeDetailController.text.isEmpty && _mainAddressController.text.isEmpty) return true;
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan Draft?'),
        content: const Text('Data akan disimpan sementara.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () { _saveDraft(); Navigator.of(context).pop(true); }, child: const Text('Ya, Keluar')),
        ],
      ),
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String formattedPrice = currencyFormatter.format(widget.basePrice);
    bool isFromGarage = widget.selectedShoe != null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: ValueListenableBuilder<AppThemeData>(
          valueListenable: ThemeConfig.currentTheme,
          builder: (context, theme, child) {
            return Scaffold(
              backgroundColor: theme.background,
              appBar: AppBar(
                title: Text("Formulir Pemesanan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                backgroundColor: theme.surface,
                iconTheme: IconThemeData(color: theme.textMain),
                elevation: 0,
                centerTitle: true,
              ),

              body: _isLoadingUserData || _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: theme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.primary.withOpacity(0.2))),
                      child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.primary.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.cleaning_services_rounded, color: theme.primary, size: 28)),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.serviceName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: theme.textMain), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(formattedPrice, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.primary))]))
                          ]
                      ),
                    ),

                    _buildSectionTitle("Detail Sepatu", theme),

                    if (!isFromGarage) ...[
                      _buildLabel("Kategori", theme),
                      Wrap(spacing: 10, runSpacing: 0, children: _shoeCategories.map((category) { bool isSelected = _selectedCategory == category; return ChoiceChip(label: Text(category), labelStyle: GoogleFonts.plusJakartaSans(color: isSelected ? Colors.white : theme.textMain, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), selected: isSelected, onSelected: (selected) { if (selected) setState(() => _selectedCategory = category); }, selectedColor: theme.primary, backgroundColor: theme.background, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300))); }).toList()),
                      const SizedBox(height: 16),
                    ],

                    _buildLabel("Merk & Tipe Spesifik", theme),
                    _buildTextField(controller: _shoeDetailController, hint: "Contoh: Nike Air Jordan 1 High Panda", icon: Icons.edit_note_rounded, theme: theme, readOnly: isFromGarage),
                    const SizedBox(height: 16),

                    if (!isFromGarage) ...[
                      _buildLabel("Foto Sepatu (Opsional)", theme),
                      GestureDetector(onTap: _pickImage, child: Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300), image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null), child: _selectedImage == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_rounded, color: theme.primary, size: 40), const SizedBox(height: 8), Text("Tap untuk upload foto", style: GoogleFonts.plusJakartaSans(color: Colors.grey))]) : null)),
                      if (_selectedImage != null) Padding(padding: const EdgeInsets.only(top: 8), child: GestureDetector(onTap: () => setState(() => _selectedImage = null), child: Text("Hapus Foto", style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.bold)))),
                      const SizedBox(height: 16),
                    ],

                    _buildLabel("Catatan Khusus", theme),
                    _buildTextField(controller: _noteController, hint: "Misal: Noda di midsole susah hilang...", icon: Icons.note_alt_outlined, theme: theme, maxLines: 2),
                    const SizedBox(height: 30), const Divider(), const SizedBox(height: 20),

                    _buildSectionTitle("Data Pelanggan", theme),
                    _buildLabel("Nomor WhatsApp / HP", theme),
                    _buildTextField(controller: _phoneController, hint: "0812xxxx (Wajib Aktif)", icon: Icons.phone_android_rounded, theme: theme, isNumber: true),
                    const SizedBox(height: 16),

                    _buildSectionTitle("Pengiriman & Jadwal", theme),
                    SwitchListTile(contentPadding: EdgeInsets.zero, activeColor: theme.primary, title: Text("Layanan Antar-Jemput", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain, fontSize: 14)), subtitle: Text(_isDeliveryIncluded ? "Kurir Jemput & Antar Kembali" : "Hanya Jemput (Saya ambil sendiri)", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)), value: _isDeliveryIncluded, onChanged: (val) => setState(() => _isDeliveryIncluded = val)),
                    const SizedBox(height: 16),
                    _buildLabel("Jadwal Penjemputan", theme),
                    Row(children: [
                      Expanded(flex: 3, child: GestureDetector(onTap: () => _pickDate(context, theme), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Row(children: [Icon(Icons.calendar_today_rounded, color: theme.primary, size: 18), const SizedBox(width: 8), Expanded(child: Text(_selectedDate == null ? "Pilih Tanggal" : DateFormat('dd MMM').format(_selectedDate!), style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))])))),
                      const SizedBox(width: 12),
                      Expanded(flex: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedTime, dropdownColor: theme.surface, icon: Icon(Icons.access_time_rounded, color: theme.primary, size: 18), isExpanded: true, items: ['Pagi (09-12)', 'Siang (13-15)', 'Sore (16-18)'].map((String value) { return DropdownMenuItem<String>(value: value, child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: theme.textMain), overflow: TextOverflow.ellipsis)); }).toList(), onChanged: (val) => setState(() => _selectedTime = val!),),),),),
                    ]),
                    const SizedBox(height: 24),

                    // 👇 BAGIAN TOMBOL BUKA PETA 👇
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _buildLabel("Alamat Penjemputan", theme),
                      Row(children: [
                        GestureDetector(onTap: () => _showSavedAddressPicker(theme), child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.bookmarks_rounded, color: Colors.orange, size: 14), const SizedBox(width: 4), Text("Tersimpan", style: GoogleFonts.plusJakartaSans(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold))]))),

                        // TOMBOL PETA BARU
                        GestureDetector(
                            onTap: _openMapPicker,
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(20)),
                                child: Row(children: [
                                  const Icon(Icons.map_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text("Pilih di Peta", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
                                ])
                            )
                        ),
                      ],)
                    ],),
                    const SizedBox(height: 8),
                    _buildTextField(controller: _mainAddressController, hint: "Jalan, Kecamatan, Kota (Otomatis GPS / Pilih)", icon: Icons.map_rounded, theme: theme, maxLines: 4),
                    const SizedBox(height: 16),
                    _buildLabel("Detail Alamat (Wajib Diisi)", theme),
                    _buildTextField(controller: _detailAddressController, hint: "Contoh: Pagar Hitam, Samping Warung...", icon: Icons.home_work_outlined, theme: theme, maxLines: 2),
                    const SizedBox(height: 40),

                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _goToPayment, style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8, shadowColor: theme.primary.withOpacity(0.4)), child: Text("Lanjut ke Pembayaran", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)))),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppThemeData theme) { return Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain))); }
  Widget _buildLabel(String text, AppThemeData theme) { return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade600))); }
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, required AppThemeData theme, int maxLines = 1, bool isNumber = false, bool readOnly = false}) {
    return TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        readOnly: readOnly,
        style: GoogleFonts.plusJakartaSans(color: readOnly ? Colors.grey : theme.textMain),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Padding(padding: const EdgeInsets.only(top: 12), child: Icon(icon, color: Colors.grey.shade400, size: 22)),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : theme.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primary))
        )
    );
  }
}

// ======================================================================
// 👇 HALAMAN BARU: PEMILIH PETA (TARUH DI PALING BAWAH FILE INI AJA) 👇
// ======================================================================

class MapSelectionScreen extends StatefulWidget {
  final LatLng initialLocation;
  const MapSelectionScreen({super.key, required this.initialLocation});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  late LatLng _currentLocation;
  String _currentAddress = "Mencari alamat...";
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    _getAddressFromLatLng(_currentLocation);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.street}, ${place.subLocality}, ${place.locality}";
        });
      }
    } catch (e) {
      setState(() => _currentAddress = "Gagal mengambil alamat detail.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text("Pilih Lokasi Jemput", style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 1,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentLocation, zoom: 17.0),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onCameraMoveStarted: () => setState(() => _isDragging = true),
            onCameraMove: (CameraPosition position) {
              _currentLocation = position.target;
            },
            onCameraIdle: () {
              setState(() => _isDragging = false);
              _getAddressFromLatLng(_currentLocation);
            },
          ),

          // PIN DI TENGAH LAYAR
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0), // Diangkat dikit biar pas di jarum
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, _isDragging ? -15 : 0, 0),
                child: const Icon(Icons.location_on, size: 50, color: Colors.red),
              ),
            ),
          ),

          // PANEL KONFIRMASI DI BAWAH
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Lokasi Penjemputan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(_currentAddress, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37), // Warna Gold
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: () {
                        // KEMBALIKAN DATA KE BOOKING PAGE
                        Navigator.pop(context, {
                          'latitude': _currentLocation.latitude,
                          'longitude': _currentLocation.longitude,
                          'address': _currentAddress,
                        });
                      },
                      child: Text("Konfirmasi Lokasi Ini", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}