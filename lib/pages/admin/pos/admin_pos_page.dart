import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/admin/widgets/admin_glass_theme.dart';

class AdminPOSPage extends StatefulWidget {
  const AdminPOSPage({super.key});

  @override
  State<AdminPOSPage> createState() => _AdminPOSPageState();
}

class _AdminPOSPageState extends State<AdminPOSPage> {
  // Dummy Data Layanan
  final List<Map<String, dynamic>> services = [
    {'name': 'Deep Clean', 'price': 35000, 'icon': Icons.cleaning_services},
    {'name': 'Fast Clean', 'price': 25000, 'icon': Icons.timer},
    {'name': 'Unyellowing', 'price': 50000, 'icon': Icons.wb_sunny},
    {'name': 'Repaint', 'price': 120000, 'icon': Icons.format_paint},
    {'name': 'Repair', 'price': 45000, 'icon': Icons.build},
    {'name': 'Leather Care', 'price': 60000, 'icon': Icons.favorite},
  ];

  Map<String, dynamic>? selectedService;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isDelivery = false; // Toggle untuk Delivery atau Ambil Sendiri

  // --- FUNGSI KIRIM KE FIREBASE ---
  Future<void> _processOrder() async {
    // Validasi Dasar (Cuma Nama yang Wajib)
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama pelanggan wajib diisi!")));
      return;
    }
    if (selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih layanan terlebih dahulu!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Data Booking
      Map<String, dynamic> orderData = {
        'customerName': _nameController.text.trim(),
        'customerPhone': _phoneController.text.trim().isEmpty ? '-' : _phoneController.text.trim(),
        'serviceName': selectedService!['name'],
        'category': 'Walk-in',
        'shoeDetail': 'Walk-in Order',
        'notes': 'Pesanan via Kasir (POS)',

        // Harga
        'basePrice': selectedService!['price'],
        'deliveryFee': _isDelivery ? 10000 : 0, // Contoh: Biaya antar flat 10rb jika delivery
        'discount': 0,
        'totalPrice': selectedService!['price'] + (_isDelivery ? 10000 : 0),

        // Status & Waktu
        'status': 'Confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Alamat & Pengiriman
        'isDelivery': _isDelivery,
        'mainAddress': _isDelivery
            ? (_addressController.text.isEmpty ? 'Alamat menyusul' : _addressController.text)
            : 'Ambil di Toko',
        'detailAddress': _isDelivery ? 'Diantar Kurir' : 'Customer datang ke toko',
        'pickupDate': FieldValue.serverTimestamp(),
        'pickupTime': DateFormat('HH:mm').format(DateTime.now()),

        // Pembayaran & User
        'paymentMethod': 'Cash / Tunai',
        'userId': '', // Kosong karena walk-in
      };

      await FirebaseFirestore.instance.collection('bookings').add(orderData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order ${_nameController.text} Berhasil Disimpan!"), backgroundColor: Colors.green)
      );

      // Reset Form
      setState(() {
        selectedService = null;
        _nameController.clear();
        _phoneController.clear();
        _addressController.clear();
        _isDelivery = false;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Kasir (Walk-in)", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textMain)),
                const SizedBox(height: 8),
                Text("Input data pelanggan & layanan.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                const SizedBox(height: 20),

                // --- BAGIAN INPUT DATA PELANGGAN ---
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. NAMA (WAJIB)
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              icon: Icon(Icons.person_outline, color: theme.primary),
                              hintText: "Nama Pelanggan (Wajib)",
                              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2. NO HP (OPSIONAL)
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              icon: Icon(Icons.phone_outlined, color: theme.primary),
                              hintText: "No. WhatsApp (Opsional)",
                              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 3. TOGGLE DELIVERY
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: SwitchListTile(
                            title: Text("Layanan Antar (Delivery)", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(_isDelivery ? "Kurir akan mengantar (+10rb)" : "Customer ambil sendiri", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                            value: _isDelivery,
                            activeColor: theme.primary,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _isDelivery = val),
                          ),
                        ),

                        // 4. ALAMAT (MUNCUL JIKA DELIVERY AKTIF)
                        if (_isDelivery) ...[
                          const SizedBox(height: 12),
                          GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                icon: Icon(Icons.location_on_outlined, color: theme.primary),
                                hintText: "Alamat Pengantaran (Opsional)",
                                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        Text("Pilih Layanan", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                        const SizedBox(height: 12),

                        // 5. GRID LAYANAN
                        GridView.builder(
                          shrinkWrap: true, // Agar bisa discroll dalam SingleChildScrollView
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: services.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.5, // Sedikit lebih gepeng biar muat
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final item = services[index];
                            bool isSelected = selectedService == item;

                            return GestureDetector(
                              onTap: () => setState(() => selectedService = item),
                              child: GlassCard(
                                padding: EdgeInsets.zero,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isSelected ? theme.primary.withOpacity(0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isSelected ? Border.all(color: theme.primary, width: 2) : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(item['icon'], size: 28, color: isSelected ? theme.primary : Colors.grey),
                                      const SizedBox(height: 4),
                                      Text(item['name'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? theme.primary : Colors.black87)),
                                      Text(currencyFormatter.format(item['price']), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 80), // Space untuk tombol bawah
                      ],
                    ),
                  ),
                ),

                // 6. TOTAL & TOMBOL (FIXED AT BOTTOM)
                if (selectedService != null)
                  GlassCard(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Bayar", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54)),
                            Text(
                              currencyFormatter.format(selectedService!['price'] + (_isDelivery ? 10000 : 0)), // Tambah ongkir kalau delivery
                              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primary),
                            ),
                            if (_isDelivery)
                              Text("(Termasuk Ongkir 10rb)", style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.green)),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _processOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Buat Order", style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          );
        }
    );
  }
}