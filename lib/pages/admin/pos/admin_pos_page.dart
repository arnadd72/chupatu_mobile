import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // CONTROLLERS
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController(); // Untuk input KM

  bool _isLoadingData = true;
  bool _isLoadingSubmit = false;
  bool _isDelivery = false;
  String _paymentMethod = 'Cash / Tunai';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // ==========================================================
  // FITUR 1: FETCH DATA LAYANAN & KONFIGURASI SISTEM REALTIME
  // ==========================================================
  Future<void> _loadInitialData() async {
    try {
      // 1. Tarik Konfigurasi Sistem (Ongkir & Mayar)
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
      }

      // 2. Tarik Data Layanan Asli dari Firestore
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
  // FITUR 2: KALKULATOR ONGKIR DINAMIS BERDASARKAN JARAK (KM)
  // ==========================================================
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

  // ==========================================================
  // FITUR 3: PROSES CHECKOUT DENGAN INTEGRASI PAYMENT
  // ==========================================================
  Future<void> _processOrder() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nama pelanggan wajib diisi!"))
      );
      return;
    }
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih layanan terlebih dahulu!"))
      );
      return;
    }
    if (_isDelivery && _distanceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Masukkan jarak pengantaran (KM)!"))
      );
      return;
    }

    setState(() => _isLoadingSubmit = true);

    try {
      int deliveryFee = _calculateDeliveryFee();
      int basePrice = _selectedService!['price'];
      int totalPrice = basePrice + deliveryFee;

      // Proteksi Status Pembayaran Mayar
      // Jika pilih Mayar, status diubah jadi Pending Payment
      String orderStatus = (_paymentMethod == 'Mayar (QRIS/VA)')
          ? 'Pending Payment'
          : 'Confirmed';

      Map<String, dynamic> orderData = {
        'customerName': _nameController.text.trim(),
        'customerPhone': _phoneController.text.trim().isEmpty
            ? '-' : _phoneController.text.trim(),
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
        'userId': '', // Kosong karena bukan order dari HP Pelanggan
      };

      await FirebaseFirestore.instance.collection('bookings').add(orderData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Order ${_nameController.text} Berhasil Disimpan!"),
              backgroundColor: Colors.green
          )
      );

      // Reset Form
      setState(() {
        _selectedService = null;
        _nameController.clear();
        _phoneController.clear();
        _addressController.clear();
        _distanceController.clear();
        _isDelivery = false;
        _paymentMethod = 'Cash / Tunai';
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red)
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
          BoxShadow(
              color: Colors.black.withOpacity(0.02), blurRadius: 8
          )
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
                      "Input data pelanggan & layanan aktual.",
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

                          // 2. DELIVERY & ONGKIR DINAMIS
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
                                  _isDelivery
                                      ? "Ongkir dihitung otomatis"
                                      : "Customer ambil sendiri",
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, color: Colors.grey
                                  )
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
                                      onChanged: (val) => setState(() {}), // Trigger hitung ulang
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
                                childAspectRatio: 1.4, // Disesuaikan biar foto muat
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