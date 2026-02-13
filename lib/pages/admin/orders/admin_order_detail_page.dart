import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart'; 

class AdminOrderDetailPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const AdminOrderDetailPage({super.key, required this.docId, required this.data});

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  late String _currentStatus;
  bool _isUpdating = false;

  final List<String> _statuses = [
    'Pending', 'Confirmed', 'Picked Up', 'Processing', 'Ready', 'Delivery', 'Done', 'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.data['status'] ?? 'Pending';
  }

  // --- 3. FITUR PENGAMAN (SAFETY GUARD) ---
  // Fungsi ini dipanggil sebelum status benar-benar diupdate
  Future<void> _attemptStatusChange(String newStatus) async {
    // JIKA STATUS SEKARANG SUDAH 'DONE', TAMPILKAN PERINGATAN
    if (_currentStatus == 'Done') {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Peringatan!"),
          content: const Text("Pesanan ini sudah selesai (DONE).\n\nMengubah statusnya akan membatalkan perhitungan pendapatan. Yakin ingin mengubah?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("Ya, Ubah")
            ),
          ],
        ),
      );

      // Jika user pilih Batal atau klik luar, hentikan proses
      if (confirm != true) return;
    }

    // Lanjut Update jika aman
    _updateStatus(newStatus);
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.docId).update({'status': newStatus});
      setState(() { _currentStatus = newStatus; _isUpdating = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status diubah ke $newStatus"), backgroundColor: _getStatusColor(newStatus)));
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal update: $e")));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Confirmed': return Colors.blue;
      case 'Picked Up': return Colors.purple;
      case 'Processing': return Colors.indigo;
      case 'Ready': return Colors.teal;
      case 'Delivery': return Colors.deepPurple;
      case 'Done': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final int price = widget.data['totalPrice'] ?? 0;
    
    String pickupInfo = "-";
    if (widget.data['pickupDate'] != null) {
      Timestamp ts = widget.data['pickupDate'];
      String date = DateFormat('dd MMM yyyy').format(ts.toDate());
      String time = widget.data['pickupTime'] ?? '';
      pickupInfo = "$date, $time";
    }

    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        Color themeColor = _getStatusColor(_currentStatus);
        Color pastelBackgroundColor = Color.lerp(Colors.white, themeColor, 0.1)!;

        return Scaffold(
          backgroundColor: pastelBackgroundColor,
          appBar: AppBar(title: Text("Detail Pesanan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: themeColor, iconTheme: const IconThemeData(color: Colors.white), elevation: 0, centerTitle: true),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: themeColor, width: 2), boxShadow: [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(children: [Text("Status Pesanan", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(_currentStatus.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: themeColor, letterSpacing: 1.5))]),
                ),
                const SizedBox(height: 24),

                Text("Update Proses", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                const SizedBox(height: 12),
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _statuses.where((s) => s != 'Cancelled').map((status) {
                  bool isSelected = _currentStatus == status;
                  return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                    label: Text(status), 
                    selected: isSelected, 
                    selectedColor: themeColor, 
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87), 
                    // PANGGIL FUNGSI SAFETY GUARD DI SINI
                    onSelected: _isUpdating ? null : (selected) { if (selected) _attemptStatusChange(status); }
                  ));
                }).toList())),
                
                const SizedBox(height: 24), const Divider(), const SizedBox(height: 24),

                _buildSectionContainer(title: "Informasi Penjemputan", theme: theme, child: Column(children: [_buildDetailRow(Icons.calendar_today, "Jadwal Pickup", pickupInfo, themeColor), const SizedBox(height: 12), _buildDetailRow(Icons.location_on, "Alamat", widget.data['mainAddress'] ?? '-', themeColor), const SizedBox(height: 12), _buildDetailRow(Icons.home, "Patokan", widget.data['detailAddress'] ?? '-', themeColor)])),
                const SizedBox(height: 20),

                _buildSectionContainer(title: "Data Pelanggan", theme: theme, child: Column(children: [_buildInfoRow(Icons.person, "Nama", widget.data['customerName'] ?? '-', themeColor), _buildInfoRow(Icons.phone, "WhatsApp", widget.data['customerPhone'] ?? '-', themeColor), _buildInfoRow(Icons.confirmation_number, "Order ID", "#${widget.docId.substring(0, 8).toUpperCase()}", themeColor)])),
                const SizedBox(height: 20),

                _buildSectionContainer(title: "Rincian Biaya", theme: theme, child: Column(children: [_buildDetailItem("Layanan", widget.data['serviceName'], theme), _buildDetailItem("Kategori", widget.data['category'], theme), _buildDetailItem("Sepatu", widget.data['shoeDetail'], theme), const Divider(), _buildDetailItem("Total Bayar", currencyFormatter.format(price), theme, isBold: true, color: themeColor), _buildDetailItem("Metode Bayar", widget.data['paymentMethod'] ?? '-', theme)])),
                
                const SizedBox(height: 40),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _currentStatus == 'Cancelled' ? null : () { showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Batalkan Pesanan?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tidak")), ElevatedButton(onPressed: () { Navigator.pop(ctx); _updateStatus('Cancelled'); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Ya, Batalkan"))])); }, icon: const Icon(Icons.cancel, color: Colors.white), label: const Text("Batalkan Pesanan", style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSectionContainer({required String title, required Widget child, required AppThemeData theme}) { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)), const SizedBox(height: 8), Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: child)]); }
  Widget _buildDetailRow(IconData icon, String label, String value, Color color) { return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: color), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)), Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87))]))]); }
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) { return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: color), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)), Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87))]))])); }
  Widget _buildDetailItem(String label, String? value, AppThemeData theme, {bool isBold = false, Color? color}) { return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600)), Text(value ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? theme.textMain))])); }
}