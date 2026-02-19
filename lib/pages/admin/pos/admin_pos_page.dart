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
  bool _isDelivery = false;

  // --- FUNGSI KIRIM KE FIREBASE ---
  Future<void> _processOrder() async {
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
      Map<String, dynamic> orderData = {
        'customerName': _nameController.text.trim(),
        'customerPhone': _phoneController.text.trim().isEmpty ? '-' : _phoneController.text.trim(),
        'serviceName': selectedService!['name'],
        'category': 'Walk-in',
        'shoeDetail': 'Walk-in Order',
        'notes': 'Pesanan via Kasir (POS)',
        'basePrice': selectedService!['price'],
        'deliveryFee': _isDelivery ? 10000 : 0,
        'discount': 0,
        'totalPrice': selectedService!['price'] + (_isDelivery ? 10000 : 0),
        'status': 'Confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDelivery': _isDelivery,
        'mainAddress': _isDelivery
            ? (_addressController.text.isEmpty ? 'Alamat menyusul' : _addressController.text)
            : 'Ambil di Toko',
        'detailAddress': _isDelivery ? 'Diantar Kurir' : 'Customer datang ke toko',
        'pickupDate': FieldValue.serverTimestamp(),
        'pickupTime': DateFormat('HH:mm').format(DateTime.now()),
        'paymentMethod': 'Cash / Tunai',
        'userId': '',
      };

      await FirebaseFirestore.instance.collection('bookings').add(orderData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order ${_nameController.text} Berhasil Disimpan!"), backgroundColor: Colors.green)
      );

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

  // Helper Custom Card tanpa efek blur kaca
  Widget _buildSolidCard({required Widget child, required AppThemeData theme, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: child,
    );
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

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. NAMA
                        _buildSolidCard(
                          theme: theme,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _nameController,
                            style: TextStyle(color: theme.textMain), // Adaptif
                            decoration: InputDecoration(
                              icon: Icon(Icons.person_outline, color: theme.primary),
                              hintText: "Nama Pelanggan (Wajib)",
                              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2. NO HP
                        _buildSolidCard(
                          theme: theme,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: theme.textMain), // Adaptif
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
                        _buildSolidCard(
                          theme: theme,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: SwitchListTile(
                            title: Text("Layanan Antar (Delivery)", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain)),
                            subtitle: Text(_isDelivery ? "Kurir akan mengantar (+10rb)" : "Customer ambil sendiri", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                            value: _isDelivery,
                            activeColor: theme.primary,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _isDelivery = val),
                          ),
                        ),

                        // 4. ALAMAT
                        if (_isDelivery) ...[
                          const SizedBox(height: 12),
                          _buildSolidCard(
                            theme: theme,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextField(
                              controller: _addressController,
                              maxLines: 2,
                              style: TextStyle(color: theme.textMain), // Adaptif
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
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: services.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final item = services[index];
                            bool isSelected = selectedService == item;

                            return GestureDetector(
                              onTap: () => setState(() => selectedService = item),
                              child: _buildSolidCard(
                                theme: theme,
                                padding: EdgeInsets.zero,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isSelected ? theme.primary.withOpacity(0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected ? Border.all(color: theme.primary, width: 2) : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(item['icon'], size: 28, color: isSelected ? theme.primary : Colors.grey),
                                      const SizedBox(height: 4),
                                      Text(item['name'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? theme.primary : theme.textMain)),
                                      Text(currencyFormatter.format(item['price']), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey)),
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

                // 6. TOTAL & TOMBOL
                if (selectedService != null)
                  _buildSolidCard(
                    theme: theme,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Bayar", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                            Text(
                              currencyFormatter.format(selectedService!['price'] + (_isDelivery ? 10000 : 0)),
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