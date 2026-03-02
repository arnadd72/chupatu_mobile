import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert'; // <-- TAMBAHAN: Untuk Encode JSON Notifikasi
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http; // <-- TAMBAHAN: Untuk nembak API Laravel
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/notification/chat_room_page.dart';

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
  bool _isLoadingChat = false;
  final GlobalKey _barcodeKey = GlobalKey();

  final List<String> _statuses = [
    'Pending', 'Confirmed', 'Picked Up', 'Processing', 'Ready', 'Delivery', 'Done', 'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.data['status'] ?? 'Pending';
  }

  Future<void> _openChatWithCustomer() async {
    String customerId = widget.data['userId'] ?? '';
    String customerName = widget.data['customerName'] ?? 'Customer';

    if (customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal: ID Customer tidak ditemukan.")));
      return;
    }

    setState(() => _isLoadingChat = true);

    try {
      var chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      String chatId;

      if (chatQuery.docs.isNotEmpty) {
        chatId = chatQuery.docs.first.id;
      } else {
        DocumentReference newChat = await FirebaseFirestore.instance.collection('chats').add({
          'userId': customerId,
          'userName': customerName,
          'lastMessage': '',
          'lastTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        chatId = newChat.id;
      }

      if (!mounted) return;

      Navigator.push(context, MaterialPageRoute(
          builder: (context) => ChatRoomPage(
            chatId: chatId,
            name: customerName,
            isOnline: false,
            isAdmin: true,
          )
      ));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eror chat: $e")));
    } finally {
      if(mounted) setState(() => _isLoadingChat = false);
    }
  }

  Future<void> _shareBarcode() async {
    try {
      RenderRepaintBoundary boundary = _barcodeKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/barcode_${widget.docId}.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Barcode Pesanan #${widget.docId.substring(0, 8)} - ${widget.data['customerName']}'
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal share barcode: $e")));
    }
  }

  void _showBarcodeDialog() {
    final theme = ThemeConfig.currentTheme.value;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _barcodeKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_laundry_service_rounded, color: theme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text("Chupatu Official", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text("Barcode Pesanan", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                    const SizedBox(height: 8),
                    Text(widget.data['customerName'] ?? 'Customer', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primary)),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12)
                      ),
                      child: QrImageView(
                        data: widget.docId,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text("#${widget.docId.toUpperCase().substring(0, 8)}", style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16, color: theme.textMain)),
                    const SizedBox(height: 8),
                    Text(widget.data['serviceName'] ?? 'Layanan', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: theme.textMain),
                    label: Text("Tutup", style: TextStyle(color: theme.textMain)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareBarcode,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text("Share / Save"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- TAMBAHAN: FUNGSI PEMICU NOTIFIKASI KE LARAVEL ---
  Future<void> _sendNotificationToCustomer(String customerUid, String newStatus) async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(customerUid).get();
      if (!userDoc.exists) return;

      String? fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint("Customer belum ngasih izin notif / belum punya token.");
        return;
      }

      String title = "Pesanan Chupatu Diupdate! 👟";
      String body = "Status sepatu kamu sekarang: $newStatus";

      var response = await http.post(
          Uri.parse('https://malik-pseudomonocyclic-misti.ngrok-free.dev/api/kirim-notif'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'token': fcmToken,
            'title': title,
            'body': body,
          })
      );

      debugPrint("Hasil tembak notif Laravel: ${response.body}");
    } catch(e) {
      debugPrint("Gagal nge-trigger notif: $e");
    }
  }

  Future<void> _attemptStatusChange(String newStatus) async {
    if (_currentStatus == 'Done') {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ThemeConfig.currentTheme.value.surface,
          title: Text("Peringatan!", style: TextStyle(color: ThemeConfig.currentTheme.value.textMain)),
          content: Text("Pesanan ini sudah selesai (DONE).\nMengubah statusnya akan membatalkan perhitungan pendapatan.\n\nYakin ingin mengubah?", style: TextStyle(color: ThemeConfig.currentTheme.value.textMain)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Ya, Ubah")),
          ],
        ),
      );
      if (confirm != true) return;
    }
    _updateStatus(newStatus);
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      // 1. Update status di Firestore
      await FirebaseFirestore.instance.collection('bookings').doc(widget.docId).update({'status': newStatus});

      // 2. TAMBAHAN: Kirim Notifikasi Otomatis ke Customer
      String customerId = widget.data['userId'] ?? '';
      if (customerId.isNotEmpty) {
        await _sendNotificationToCustomer(customerId, newStatus);
      }

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

    int statusIndex = _statuses.indexOf(_currentStatus);
    bool showBarcode = statusIndex >= 1 && _currentStatus != 'Cancelled';

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
          Color pageBackgroundColor = theme.background;

          return Scaffold(
            backgroundColor: pageBackgroundColor,
            appBar: AppBar(
              title: Text("Detail Pesanan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: themeColor,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              centerTitle: true,
              actions: [
                if (showBarcode)
                  IconButton(
                    onPressed: _showBarcodeDialog,
                    icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
                    tooltip: "Lihat Barcode",
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER STATUS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: themeColor, width: 2), boxShadow: [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(children: [Text("Status Pesanan", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(_currentStatus.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: themeColor, letterSpacing: 1.5))]),
                  ),
                  const SizedBox(height: 24),

                  // UPDATE PROSES
                  Text("Update Proses", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(12)),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _statuses.where((s) => s != 'Cancelled').map((status) {
                        bool isSelected = _currentStatus == status;
                        Color chipColor = _getStatusColor(status);
                        return ChoiceChip(
                            label: Text(status),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : theme.textMain, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12),
                            selected: isSelected,
                            selectedColor: chipColor,
                            backgroundColor: theme.background,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2))),
                            onSelected: _isUpdating ? null : (selected) { if (selected) _attemptStatusChange(status); }
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TOMBOL CHAT CUSTOMER
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingChat ? null : _openChatWithCustomer,
                      icon: _isLoadingChat
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.chat_bubble_rounded, size: 20),
                      label: Text(_isLoadingChat ? "Memuat..." : "Chat Customer", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2
                      ),
                    ),
                  ),

                  const SizedBox(height: 24), const Divider(), const SizedBox(height: 24),

                  // INFORMASI PENJEMPUTAN
                  _buildSectionContainer(title: "Informasi Penjemputan", theme: theme, child: Column(children: [_buildDetailRow(Icons.calendar_today, "Jadwal Pickup", pickupInfo, themeColor, theme), const SizedBox(height: 12), _buildDetailRow(Icons.location_on, "Alamat", widget.data['mainAddress'] ?? '-', themeColor, theme), const SizedBox(height: 12), _buildDetailRow(Icons.home, "Patokan", widget.data['detailAddress'] ?? '-', themeColor, theme)])),
                  const SizedBox(height: 20),

                  // DATA PELANGGAN
                  _buildSectionContainer(title: "Data Pelanggan", theme: theme, child: Column(children: [_buildInfoRow(Icons.person, "Nama", widget.data['customerName'] ?? '-', themeColor, theme), _buildInfoRow(Icons.phone, "No. HP", widget.data['customerPhone'] ?? '-', themeColor, theme), _buildInfoRow(Icons.confirmation_number, "Order ID", "#${widget.docId.substring(0, 8).toUpperCase()}", themeColor, theme)])),
                  const SizedBox(height: 20),

                  // RINCIAN BIAYA
                  _buildSectionContainer(title: "Rincian Biaya", theme: theme, child: Column(children: [_buildDetailItem("Layanan", widget.data['serviceName'], theme), _buildDetailItem("Kategori", widget.data['category'], theme), _buildDetailItem("Sepatu", widget.data['shoeDetail'], theme), const Divider(), _buildDetailItem("Total Bayar", currencyFormatter.format(price), theme, isBold: true, color: themeColor), _buildDetailItem("Metode Bayar", widget.data['paymentMethod'] ?? '-', theme)])),

                  const SizedBox(height: 40),

                  // FITUR MAGIC RESULT
                  if (_currentStatus == 'Done') ...[
                    Text("Magic Result (Hasil Cuci)", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.5)), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10)]),
                      child: Column(
                        children: [
                          const Icon(Icons.auto_awesome, size: 40, color: Colors.green),
                          const SizedBox(height: 8),
                          Text("Upload Foto Hasil Cuci", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                          Text("Foto ini akan muncul di aplikasi customer.", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                              onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Upload Foto akan segera hadir!"))); },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text("Ambil Foto / Upload"),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.green)
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // TOMBOL BATAL
                  if (_currentStatus != 'Done' && _currentStatus != 'Cancelled')
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: theme.surface, title: Text("Batalkan Pesanan?", style: TextStyle(color: theme.textMain)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tidak", style: TextStyle(color: Colors.grey))), ElevatedButton(onPressed: () { Navigator.pop(ctx); _updateStatus('Cancelled'); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Ya, Batalkan"))])); }, icon: const Icon(Icons.cancel, color: Colors.white), label: const Text("Batalkan Pesanan", style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
    );
  }

  // WIDGET HELPER (PERUBAHAN WARNA TEKS SESUAI TEMA)
  Widget _buildSectionContainer({required String title, required Widget child, required AppThemeData theme}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)), const SizedBox(height: 8), Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: child)]);
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color, AppThemeData theme) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: color), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)), Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textMain))]))]);
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, AppThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: color), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)), Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textMain))]))]));
  }

  Widget _buildDetailItem(String label, String? value, AppThemeData theme, {bool isBold = false, Color? color}) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600)), Text(value ?? '-', style: GoogleFonts.plusJakartaSans(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? theme.textMain))]));
  }
}