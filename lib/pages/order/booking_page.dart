import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:geolocator/geolocator.dart'; 
import 'package:geocoding/geocoding.dart'; 
import 'package:chupatu_mobile/main.dart'; 
// PENTING: Import Payment Page
import 'package:chupatu_mobile/pages/order/payment_page.dart';

// --- VARIABEL GLOBAL DRAFT ---
Map<String, dynamic> _bookingDraft = {};

class BookingPage extends StatefulWidget {
  final String serviceName;
  final int basePrice;

  const BookingPage({
    super.key,
    required this.serviceName,
    required this.basePrice,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // --- CONTROLLERS ---
  final _shoeDetailController = TextEditingController();
  final _noteController = TextEditingController();
  final _mainAddressController = TextEditingController(); 
  final _detailAddressController = TextEditingController(); 

  // --- STATE ---
  String _selectedCategory = 'Sneakers'; 
  final List<String> _shoeCategories = ['Sneakers', 'Boots', 'Flat Shoes', 'Heels/Wedges', 'Formal/Pantofel', 'Olahraga', 'Lainnya'];

  DateTime? _selectedDate;
  // Default value harus sama persis dengan opsi di dropdown menu
  String _selectedTime = 'Pagi (09-12)'; 
  
  bool _isDeliveryIncluded = true;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLocating = false; // Loading GPS

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  // --- LOGIKA DRAFT ---
  void _loadDraft() {
    if (_bookingDraft.isNotEmpty && _bookingDraft['service'] == widget.serviceName) {
      setState(() {
        _shoeDetailController.text = _bookingDraft['shoeDetail'] ?? '';
        _noteController.text = _bookingDraft['note'] ?? '';
        _mainAddressController.text = _bookingDraft['mainAddress'] ?? '';
        _detailAddressController.text = _bookingDraft['detailAddress'] ?? '';
        _selectedCategory = _bookingDraft['category'] ?? 'Sneakers';
        _selectedTime = _bookingDraft['time'] ?? 'Pagi (09-12)';
        _isDeliveryIncluded = _bookingDraft['isDelivery'] ?? true;
      });
    }
  }

  void _saveDraft() {
    _bookingDraft = {
      'service': widget.serviceName,
      'shoeDetail': _shoeDetailController.text,
      'note': _noteController.text,
      'mainAddress': _mainAddressController.text,
      'detailAddress': _detailAddressController.text,
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
    super.dispose();
  }

  // --- INPUT HELPERS ---
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String mainAddress = "${place.thoroughfare}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}";
        if (place.thoroughfare == null || place.thoroughfare!.isEmpty) {
           mainAddress = "${place.street}, ${place.subLocality}, ${place.locality}";
        }
        setState(() {
          _mainAddressController.text = mainAddress;
        });
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      setState(() => _isLocating = false);
    }
  }

  // --- LOGIKA NAVIGASI (GO TO PAYMENT) ---
  void _goToPayment() {
    // 1. Validasi Input
    if (_shoeDetailController.text.isEmpty || _mainAddressController.text.isEmpty || _detailAddressController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi detail, tanggal, dan alamat!"), backgroundColor: Colors.red));
      return;
    }

    // 2. Pindah ke Halaman Pembayaran (Bawa semua data)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          serviceName: widget.serviceName,
          basePrice: widget.basePrice,
          category: _selectedCategory,
          shoeDetail: _shoeDetailController.text,
          notes: _noteController.text,
          pickupDate: _selectedDate!,
          pickupTime: _selectedTime,
          isDelivery: _isDeliveryIncluded,
          mainAddress: _mainAddressController.text,
          detailAddress: _detailAddressController.text,
          shoeImageFile: _selectedImage, // Bawa file foto (tidak diupload disini)
          phoneNumber: "", // Nanti diambil di PaymentPage atau BookingPage (jika sudah ada logic HP)
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
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: theme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.primary.withOpacity(0.2))),
                    child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.primary.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.cleaning_services_rounded, color: theme.primary, size: 28)), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.serviceName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: theme.textMain)), const SizedBox(height: 4), Text(formattedPrice, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.primary))])]),
                  ),
                  const SizedBox(height: 24),

                  // BAGIAN 1
                  _buildSectionTitle("Detail Sepatu", theme),
                  _buildLabel("Kategori", theme),
                  Wrap(spacing: 10, runSpacing: 0, children: _shoeCategories.map((category) { bool isSelected = _selectedCategory == category; return ChoiceChip(label: Text(category), labelStyle: GoogleFonts.plusJakartaSans(color: isSelected ? Colors.white : theme.textMain, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), selected: isSelected, onSelected: (selected) { if (selected) setState(() => _selectedCategory = category); }, selectedColor: theme.primary, backgroundColor: theme.background, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300))); }).toList()),
                  const SizedBox(height: 16),
                  _buildLabel("Merk & Tipe Spesifik", theme),
                  _buildTextField(controller: _shoeDetailController, hint: "Contoh: Nike Air Jordan 1 High Panda", icon: Icons.edit_note_rounded, theme: theme),
                  const SizedBox(height: 16),
                  _buildLabel("Foto Sepatu (Opsional)", theme),
                  GestureDetector(onTap: _pickImage, child: Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300), image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null), child: _selectedImage == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_rounded, color: theme.primary, size: 40), const SizedBox(height: 8), Text("Tap untuk upload foto", style: GoogleFonts.plusJakartaSans(color: Colors.grey))]) : null)),
                  if (_selectedImage != null) Padding(padding: const EdgeInsets.only(top: 8), child: GestureDetector(onTap: () => setState(() => _selectedImage = null), child: Text("Hapus Foto", style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 16),
                  _buildLabel("Catatan Khusus", theme),
                  _buildTextField(controller: _noteController, hint: "Misal: Noda di midsole susah hilang...", icon: Icons.note_alt_outlined, theme: theme, maxLines: 2),
                  const SizedBox(height: 30), const Divider(), const SizedBox(height: 20),

                  // BAGIAN 2
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildLabel("Alamat Utama / Titik Peta", theme), GestureDetector(onTap: _isLocating ? null : _getCurrentLocation, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Row(children: [_isLocating ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: theme.primary)) : Icon(Icons.my_location_rounded, color: theme.primary, size: 16), const SizedBox(width: 6), Text(_isLocating ? "Mencari..." : "Isi Otomatis", style: GoogleFonts.plusJakartaSans(color: theme.primary, fontSize: 11, fontWeight: FontWeight.bold))])))]),
                  const SizedBox(height: 8),
                  
                  // KOLOM ALAMAT DIPERBESAR (maxLines: 4)
                  _buildTextField(controller: _mainAddressController, hint: "Jalan, Kecamatan, Kota (Otomatis GPS)", icon: Icons.map_rounded, theme: theme, maxLines: 4),
                  const SizedBox(height: 16),
                  
                  _buildLabel("Detail Alamat (Wajib Diisi)", theme),
                  _buildTextField(controller: _detailAddressController, hint: "Contoh: Rumah Pagar Hitam No. 5, Samping Indomaret...", icon: Icons.home_work_outlined, theme: theme, maxLines: 2),
                  const SizedBox(height: 40),

                  // TOMBOL LANJUT KE PEMBAYARAN (Ganti dari Konfirmasi Pesanan)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goToPayment, // PANGGIL FUNGSI NAVIGASI
                      style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8, shadowColor: theme.primary.withOpacity(0.4)),
                      child: Text("Lanjut ke Pembayaran", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
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
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, required AppThemeData theme, int maxLines = 1}) { return TextField(controller: controller, maxLines: maxLines, style: GoogleFonts.plusJakartaSans(color: theme.textMain), decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 13), prefixIcon: Padding(padding: const EdgeInsets.only(top: 12), child: Icon(icon, color: Colors.grey.shade400, size: 22)), filled: true, fillColor: theme.surface, contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.primary)))); }
}