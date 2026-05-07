import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // TAMBAHAN: Untuk Kamera/Galeri
import 'package:chupatu_mobile/main.dart';

class AdminPOSPage extends StatefulWidget {
  const AdminPOSPage({super.key});

  @override
  State<AdminPOSPage> createState() => _AdminPOSPageState();
}

class _AdminPOSPageState extends State<AdminPOSPage> {
  // DATA DINAMIS DARI FIREBASE
  List<Map<String, dynamic>> _dbServices = [];
  Map<String, dynamic>? _selectedService;

  // KONFIGURASI SISTEM ONGKIR & MAYAR
  int _baseDistanceKm = 0;
  int _baseDeliveryFee = 0;
  int _extraFeePerKm = 0;

  bool _isMayarActive = false;
  bool _isMayarSandbox = true;
  String _mayarApiKey = '';

  // CONTROLLERS & FILES
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  File? _imageFile; // State untuk simpan foto sepatu

  bool _isLoadingData = true;
  bool _isLoadingSubmit = false;
  bool _isDelivery = false;
  String _paymentMethod = 'Cash / Tunai';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      var configDoc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('config')
          .get();

      if (configDoc.exists) {
        var conf = configDoc.data()!;
        _baseDistanceKm = conf['baseDistanceKm'] ?? 0;
        _baseDeliveryFee = conf['baseDeliveryFee'] ?? 0;
        _extraFeePerKm = conf['extraFeePerKm'] ?? 0;

        _isMayarActive = conf['isMayarActive'] ?? false;
        _isMayarSandbox = conf['isMayarSandbox'] ?? true;
        _mayarApiKey = conf['mayarApiKey'] ?? '';
      }

      var serviceDocs = await FirebaseFirestore.instance
          .collection('services')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> tempServices = [];
      for (var doc in serviceDocs.docs) {
        var data = doc.data();
        tempServices.add({
          'id': doc.id,
          'name': data['name'] ?? 'Layanan',
          'price': data['price'] ?? 0,
          'imageUrl': data['imageUrl'] ?? '',
        });
      }

      setState(() {
        _dbServices = tempServices;
        _isLoadingData = false;
      });
    } catch (e) {
      debugPrint("Gagal load data POS: $e");
      setState(() => _isLoadingData = false);
    }
  }

  // ==========================================================
  // FITUR: AMBIL FOTO SEPATU DARI KAMERA / GALERI
  // ==========================================================
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70, // Kompresi 70% biar upload cepet & kuota irit
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _showImagePickerOptions(AppThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                "Ambil Bukti Foto",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, fontSize: 18, color: theme.textMain
                )
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Kamera",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    }
                ),
                _buildPickerOption(
                    icon: Icons.photo_library_rounded,
                    label: "Galeri",
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    }
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon, required String label, required Color color, required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  int _calculateDeliveryFee() {
    if (!_isDelivery) return 0;
    int inputKm = int.tryParse(_distanceController.text) ?? 0;
    if (inputKm == 0) return 0;

    if (inputKm <= _baseDistanceKm) {
      return _baseDeliveryFee;
    } else {
      int extraKm = inputKm - _baseDistanceKm;
      return _baseDeliveryFee + (extraKm * _extraFeePerKm);
    }
  }

  Future<void> _processOrder() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama pelanggan wajib diisi!")));
      return;
    }
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih layanan terlebih dahulu!")));
      return;
    }
    if (_isDelivery && _distanceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Masukkan jarak pengantaran (KM)!")));
      return;
    }

    setState(() => _isLoadingSubmit = true);

    try {
      int deliveryFee = _calculateDeliveryFee();
      int basePrice = _selectedService!['price'];
      int totalPrice = basePrice + deliveryFee;

      String orderStatus = (_paymentMethod == 'Mayar (QRIS/VA)')
          ? 'Pending Payment' : 'Confirmed';

      String paymentLink = '';
      String invoiceId = '';
      String shoeImageUrl = '';

      // --- 1. UPLOAD FOTO KE CLOUDINARY (JIKA ADA) ---
      if (_imageFile != null) {
        final cloudinaryUrl = Uri.parse(
            'https://api.cloudinary.com/v1_1/dyiicub10/image/upload'
        );
        final request = http.MultipartRequest('POST', cloudinaryUrl)
          ..fields['upload_preset'] = 'chupatu_promo'
          ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

        var response = await request.send();
        if (response.statusCode == 200) {
          var resData = await response.stream.bytesToString();
          shoeImageUrl = jsonDecode(resData)['secure_url'];
        }
      }

      // --- 2. INTEGRASI MAYAR API ---
      if (_paymentMethod == 'Mayar (QRIS/VA)') {
        if (_mayarApiKey.isEmpty) {
          throw Exception("API Key Mayar belum disetting di Sistem!");
        }

        String apiUrl = _isMayarSandbox
            ? 'https://api.mayar.club/hl/v1/invoice/create'
            : 'https://api.mayar.id/hl/v1/invoice/create';

        var response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Bearer $_mayarApiKey',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              "name": _nameController.text.trim(),
              "email": "customer@chupatu.com",
              "mobile": _phoneController.text.trim().isEmpty ? "080000000000" : _phoneController.text.trim(),
              "description": "Order Kasir Chupatu",
              "expiredAt": DateTime.now().add(const Duration(days: 1)).toUtc().toIso8601String(),
              "items": [
                {
                  "quantity": 1,
                  "rate": totalPrice,
                  "description": "${_selectedService!['name']} ${(_isDelivery ? '+ Ongkir' : '')}"
                }
              ]
            })
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          var resData = jsonDecode(response.body);
          paymentLink = resData['data']['link'];
          invoiceId = resData['data']['id'] ?? '';
        } else {
          throw Exception("Mayar Error: ${response.body}");
        }
      }

      // --- 3. SIMPAN KE FIRESTORE ---
      Map<String, dynamic> orderData = {
        'customerName': _nameController.text.trim(),
        'customerPhone': _phoneController.text.trim().isEmpty ? '-' : _phoneController.text.trim(),
        'serviceName': _selectedService!['name'],
        'category': 'Walk-in',
        'shoeDetail': 'Walk-in Order',
        'notes': 'Pesanan via Kasir (POS)',
        'basePrice': basePrice,
        'deliveryFee': deliveryFee,
        'deliveryDistanceKm': int.tryParse(_distanceController.text) ?? 0,
        'discount': 0,
        'totalPrice': totalPrice,
        'status': orderStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDelivery': _isDelivery,
        'mainAddress': _isDelivery
            ? (_addressController.text.isEmpty ? 'Alamat menyusul' : _addressController.text)
            : 'Ambil di Toko',
        'detailAddress': _isDelivery ? 'Diantar Kurir' : 'Customer datang ke toko',
        'pickupDate': FieldValue.serverTimestamp(),
        'pickupTime': DateFormat('HH:mm').format(DateTime.now()),
        'paymentMethod': _paymentMethod,
        'paymentLink': paymentLink,
        'invoiceId': invoiceId,
        'shoeImageUrl': shoeImageUrl, // Simpan Bukti Foto ke Database
        'userId': '',
      };

      await FirebaseFirestore.instance.collection('bookings').add(orderData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Order ${_nameController.text} Tersimpan!"),
              backgroundColor: Colors.green
          )
      );

      // BUKA LINK PEMBAYARAN MAYAR
      if (paymentLink.isNotEmpty) {
        final Uri url = Uri.parse(paymentLink);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Gagal membuka link pembayaran Mayar."))
          );
        }
      }

      // Reset Form
      setState(() {
        _selectedService = null;
        _nameController.clear();
        _phoneController.clear();
        _addressController.clear();
        _distanceController.clear();
        _isDelivery = false;
        _paymentMethod = 'Cash / Tunai';
        _imageFile = null; // Kosongkan foto
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memproses: $e"), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isLoadingSubmit = false);
    }
  }

  Widget _buildSolidCard({
    required Widget child, required AppThemeData theme, EdgeInsetsGeometry? padding
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0
    );

    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          if (_isLoadingData) {
            return Scaffold(
              backgroundColor: theme.background,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          int calculatedOngkir = _calculateDeliveryFee();
          int currentTotal = (_selectedService?['price'] ?? 0) + calculatedOngkir;

          return Scaffold(
            backgroundColor: theme.background,
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Kasir (Walk-in)",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 24, fontWeight: FontWeight.bold, color: theme.textMain
                      )
                  ),
                  const SizedBox(height: 8),
                  Text(
                      "Input data pelanggan & buat Invoice otomatis.",
                      style: GoogleFonts.plusJakartaSans(color: Colors.grey)
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. DATA PELANGGAN
                          Text(
                              "Data Pelanggan",
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold, color: theme.textMain
                              )
                          ),
                          const SizedBox(height: 12),
                          _buildSolidCard(
                            theme: theme,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextField(
                              controller: _nameController,
                              style: TextStyle(color: theme.textMain),
                              decoration: InputDecoration(
                                icon: Icon(Icons.person_outline, color: theme.primary),
                                hintText: "Nama Pelanggan (Wajib)",
                                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSolidCard(
                            theme: theme,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: theme.textMain),
                              decoration: InputDecoration(
                                icon: Icon(Icons.phone_outlined, color: theme.primary),
                                hintText: "No. WhatsApp (Opsional)",
                                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ===================================================
                          // FITUR BARU: FOTO SEPATU (BUKTI PENERIMAAN)
                          // ===================================================
                          Text(
                              "Bukti Sepatu (Opsional)",
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold, color: theme.textMain
                              )
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _showImagePickerOptions(theme),
                            child: _buildSolidCard(
                              theme: theme,
                              padding: EdgeInsets.zero,
                              child: Container(
                                height: _imageFile != null ? 180 : 80,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: _imageFile != null
                                      ? DecorationImage(
                                      image: FileImage(_imageFile!), fit: BoxFit.cover
                                  )
                                      : null,
                                ),
                                child: _imageFile == null
                                    ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: Colors.grey.shade400, size: 28),
                                    const SizedBox(width: 12),
                                    Text(
                                        "Ambil Foto Sepatu Pelanggan",
                                        style: TextStyle(color: Colors.grey.shade500)
                                    )
                                  ],
                                )
                                    : Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    icon: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                            color: Colors.black54, shape: BoxShape.circle
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 18)
                                    ),
                                    onPressed: () => setState(() => _imageFile = null),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 2. OPSI PENGIRIMAN
                          Text(
                              "Opsi Pengiriman",
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold, color: theme.textMain
                              )
                          ),
                          const SizedBox(height: 12),
                          _buildSolidCard(
                            theme: theme,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: SwitchListTile(
                              title: Text(
                                  "Layanan Antar (Delivery)",
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain
                                  )
                              ),
                              subtitle: Text(
                                  _isDelivery ? "Ongkir dihitung otomatis" : "Customer ambil sendiri",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)
                              ),
                              value: _isDelivery,
                              activeColor: theme.primary,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() {
                                _isDelivery = val;
                                if (!val) _distanceController.clear();
                              }),
                            ),
                          ),

                          if (_isDelivery) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildSolidCard(
                                    theme: theme,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: TextField(
                                      controller: _distanceController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(color: theme.textMain),
                                      onChanged: (val) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: "Jarak (KM)",
                                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _buildSolidCard(
                                    theme: theme,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: TextField(
                                      controller: _addressController,
                                      maxLines: 1,
                                      style: TextStyle(color: theme.textMain),
                                      decoration: InputDecoration(
                                        hintText: "Alamat Pengantaran",
                                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 24),

                          // 3. METODE PEMBAYARAN
                          Text(
                              "Metode Pembayaran",
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold, color: theme.textMain
                              )
                          ),
                          const SizedBox(height: 12),
                          _buildSolidCard(
                            theme: theme,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _paymentMethod,
                                isExpanded: true,
                                dropdownColor: theme.surface,
                                style: TextStyle(color: theme.textMain, fontWeight: FontWeight.bold),
                                items: [
                                  const DropdownMenuItem(
                                      value: 'Cash / Tunai', child: Text("Cash / Tunai")
                                  ),
                                  const DropdownMenuItem(
                                      value: 'Transfer Bank Manual', child: Text("Transfer Bank Manual")
                                  ),
                                  if (_isMayarActive)
                                    const DropdownMenuItem(
                                        value: 'Mayar (QRIS/VA)', child: Text("Mayar (Otomatis QRIS/VA)")
                                    ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _paymentMethod = val);
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 4. GRID LAYANAN (DARI DATABASE)
                          Text(
                              "Pilih Layanan Aktual",
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain
                              )
                          ),
                          const SizedBox(height: 12),

                          if (_dbServices.isEmpty)
                            const Center(child: Text("Belum ada layanan di database."))
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _dbServices.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemBuilder: (context, index) {
                                final item = _dbServices[index];
                                bool isSelected = _selectedService == item;
                                String imgUrl = item['imageUrl'] ?? '';

                                return GestureDetector(
                                  onTap: () => setState(() => _selectedService = item),
                                  child: _buildSolidCard(
                                    theme: theme,
                                    padding: EdgeInsets.zero,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.primary.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                        border: isSelected
                                            ? Border.all(color: theme.primary, width: 2)
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (imgUrl.isNotEmpty)
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundImage: NetworkImage(imgUrl),
                                              backgroundColor: Colors.transparent,
                                            )
                                          else
                                            Icon(
                                                Icons.cleaning_services,
                                                size: 28,
                                                color: isSelected ? theme.primary : Colors.grey
                                            ),
                                          const SizedBox(height: 8),
                                          Text(
                                              item['name'],
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: isSelected ? theme.primary : theme.textMain
                                              )
                                          ),
                                          Text(
                                              currencyFormatter.format(item['price']),
                                              style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11, color: Colors.green
                                              )
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),

                  // 6. TOTAL & TOMBOL SUBMIT
                  if (_selectedService != null)
                    _buildSolidCard(
                      theme: theme,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Total Bayar", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                                Text(
                                  currencyFormatter.format(currentTotal),
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18, fontWeight: FontWeight.bold, color: theme.primary
                                  ),
                                ),
                                if (_isDelivery)
                                  Text(
                                      "(Ongkir Dinamis: ${currencyFormatter.format(calculatedOngkir)})",
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.green)
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isLoadingSubmit ? null : _processOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoadingSubmit
                                ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                                : const Text("Buat Order", style: TextStyle(fontWeight: FontWeight.bold)),
                          )
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