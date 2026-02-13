import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // WAJIB: Untuk ambil ID user saat ini
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart'; // WAJIB: Import ini
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/utils/invoice_pdf_helper.dart';

// IMPORT HALAMAN CHAT
import 'package:chupatu_mobile/pages/notification/chat_room_page.dart';

class OrderDetailPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;

  const OrderDetailPage({
    super.key,
    required this.docId,
    required this.data,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _isGeneratingPdf = false;
  bool _isLoadingChat = false; // Loading saat buka chat

  // --- 1. FUNGSI BUKA CHAT KE ADMIN ---
  Future<void> _openChatWithAdmin() async {
    setState(() => _isLoadingChat = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan login terlebih dahulu.")));
        return;
      }

      // 1. Cari Room Chat milik user ini
      var chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      String chatId;

      if (chatQuery.docs.isNotEmpty) {
        // Room sudah ada, pakai ID-nya
        chatId = chatQuery.docs.first.id;
      } else {
        // Room belum ada, buat baru
        DocumentReference newChat = await FirebaseFirestore.instance.collection('chats').add({
          'userId': user.uid,
          'userName': user.displayName ?? 'Customer',
          'lastMessage': 'Halo Admin, saya mau tanya pesanan #${widget.docId.substring(0, 6)}', // Pesan awal otomatis
          'lastTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        chatId = newChat.id;
      }

      if (!mounted) return;

      // 2. Masuk ke Chat Room (Sesuai parameter AdminChatPage)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(
            name: "Admin Chupatu", // Nama yang muncul di header chat customer
            isOnline: true,        // Status Admin (Dummy)
            chatId: chatId,        // Kunci Masuk Room
            isAdmin: false,        // Customer bukan Admin
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal membuka chat: $e")));
    } finally {
      if (mounted) setState(() => _isLoadingChat = false);
    }
  }

  // --- 2. FUNGSI TAMPILKAN BARCODE ---
  void _showBarcodeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Barcode Pesanan", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Tunjukkan ke kasir/kurir", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),

              // QR CODE
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                child: QrImageView(
                  data: widget.docId,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),

              const SizedBox(height: 12),
              // Gunakan robotoMono untuk font kode biar rapi
              Text("#${widget.docId.toUpperCase().substring(0, 8)}", style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, letterSpacing: 1.5)),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                  child: const Text("Tutup"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- FUNGSI BATALKAN PESANAN ---
  Future<void> _cancelOrder() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Batalkan Pesanan?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text("Tindakan ini tidak dapat diurungkan.", style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Kembali")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('bookings').doc(widget.docId).update({'status': 'Cancelled'});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pesanan dibatalkan", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Batalkan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- FUNGSI UNDUH INVOICE ---
  Future<void> _generateAndDownloadInvoice() async {
    setState(() => _isGeneratingPdf = true);
    try {
      await InvoicePdfHelper.generateInvoice(widget.docId, widget.data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${e.toString()}"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // --- FORMAT TANGGAL AMAN ---
  String _formatSafeDate(dynamic dateData, {String fallback = '-', String format = 'dd MMMM yyyy, HH:mm'}) {
    if (dateData == null) return fallback;
    if (dateData is Timestamp) return DateFormat(format).format(dateData.toDate());
    if (dateData is String) return dateData;
    return dateData.toString();
  }

  // --- MAPPING IKON ---
  Map<String, dynamic> _getServiceIcon(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'deep clean': return {'icon': Icons.water_drop_rounded, 'color': Colors.blue, 'lottie': 'assets/lottie/water_drop.json'};
      case 'fast clean': return {'icon': Icons.timer_rounded, 'color': Colors.orange, 'lottie': 'assets/lottie/Stopwatch.json'};
      case 'unyellowing': return {'icon': Icons.auto_awesome_rounded, 'color': Colors.amber, 'lottie': 'assets/lottie/sparkle.json'};
      case 'repair': return {'icon': Icons.build_rounded, 'color': Colors.grey.shade700, 'lottie': 'assets/lottie/wrench.json'};
      case 'repaint': return {'icon': Icons.format_paint_rounded, 'color': Colors.purple, 'lottie': 'assets/lottie/paint.json'};
      case 'waterproof': return {'icon': Icons.umbrella_rounded, 'color': Colors.teal, 'lottie': 'assets/lottie/umbrella.json'};
      case 'custom': return {'icon': Icons.design_services_rounded, 'color': Colors.pink, 'lottie': 'assets/lottie/pencil.json'};
      default: return {'icon': Icons.cleaning_services_rounded, 'color': Colors.indigo};
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String serviceName = widget.data['serviceName'] ?? 'Layanan';
    final serviceConfig = _getServiceIcon(serviceName);
    String dateStr = _formatSafeDate(widget.data['createdAt']);
    String pickupDateOnly = _formatSafeDate(widget.data['pickupDate'], format: 'dd MMMM yyyy', fallback: 'Belum dijadwalkan');
    String pickupTimeStr = widget.data['pickupTime'] ?? '';
    String finalPickup = pickupTimeStr.isNotEmpty ? "$pickupDateOnly\nJam: $pickupTimeStr" : pickupDateOnly;
    bool isDelivery = widget.data['isDelivery'] ?? false;
    String finalDelivery = isDelivery ? "Akan diantar setelah pesanan selesai" : "Ambil sendiri ke toko (Self Pick-up)";

    String mainAddress = widget.data['mainAddress'] ?? '';
    String detailAddress = widget.data['detailAddress'] ?? '';
    String fullAddress = (mainAddress.isNotEmpty || detailAddress.isNotEmpty) ? "$mainAddress\n\nCatatan: $detailAddress" : (widget.data['address'] ?? 'Alamat tidak tersedia');

    String currentStatus = widget.data['status'] ?? 'Pending';
    bool canCancel = (currentStatus == 'Pending' || currentStatus == 'Confirmed');
    bool isDone = (currentStatus == 'Done');

    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              backgroundColor: widget.statusColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text("Detail Pesanan", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                // TOMBOL BARCODE (BARU)
                IconButton(
                  onPressed: _showBarcodeDialog,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  tooltip: "Scan Barcode",
                ),
                const SizedBox(width: 8),
              ],
            ),

            body: SingleChildScrollView(
              child: Column(
                children: [
                  // HEADER
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: widget.statusColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30))),
                    child: Column(children: [
                      Icon(widget.statusIcon, color: Colors.white, size: 60), const SizedBox(height: 12),
                      Text(widget.statusLabel, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
                      Text("ID: #${widget.docId.substring(0, 8).toUpperCase()}", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14)),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // --- TOMBOL HUBUNGI ADMIN (BARU) ---
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingChat ? null : _openChatWithAdmin,
                            icon: _isLoadingChat
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.support_agent_rounded),
                            label: Text(_isLoadingChat ? "Menghubungkan..." : "Hubungi Admin", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: theme.primary,
                              elevation: 1,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: theme.primary.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // INFO LAYANAN
                        _buildSectionTitle("Informasi Layanan", theme),
                        Container(
                          padding: const EdgeInsets.all(16), decoration: _cardDecoration(theme),
                          child: Column(
                            children: [
                              Row(children: [
                                Container(
                                  width: 50, height: 50, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: serviceConfig['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: serviceConfig.containsKey('lottie') ? Lottie.asset(serviceConfig['lottie'], fit: BoxFit.contain) : Icon(serviceConfig['icon'], color: serviceConfig['color'], size: 26),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(serviceName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)), Text(widget.data['shoeDetail'] ?? 'Detail sepatu', style: GoogleFonts.plusJakartaSans(color: Colors.grey))])),
                              ]),
                              const Divider(height: 24),
                              _buildInfoRow("Kategori", widget.data['category'] ?? '-', theme), const SizedBox(height: 8),
                              _buildInfoRow("Tanggal Order", dateStr, theme), const SizedBox(height: 8),
                              _buildInfoRow("Catatan", widget.data['notes'] ?? '-', theme),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ALAMAT
                        _buildSectionTitle("Alamat & Jadwal", theme),
                        Container(
                          padding: const EdgeInsets.all(16), decoration: _cardDecoration(theme),
                          child: Column(
                            children: [
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Icon(Icons.location_on, color: Colors.red.shade400, size: 24), const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Alamat Penjemputan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain)), const SizedBox(height: 4), Text(fullAddress, style: GoogleFonts.plusJakartaSans(color: Colors.grey, height: 1.5))])),
                              ]),
                              const Divider(height: 24),
                              _buildInfoRow("Jadwal Jemput", finalPickup, theme), const SizedBox(height: 8),
                              _buildInfoRow("Pengantaran", finalDelivery, theme),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // PEMBAYARAN
                        _buildSectionTitle("Rincian Pembayaran", theme),
                        Container(
                          padding: const EdgeInsets.all(16), decoration: _cardDecoration(theme),
                          child: Column(
                            children: [
                              _buildPriceRow("Harga Layanan", widget.data['basePrice'] ?? 0, currency, theme), const SizedBox(height: 8),
                              _buildPriceRow("Biaya Antar Jemput", widget.data['deliveryFee'] ?? 0, currency, theme),
                              if ((widget.data['discount'] ?? 0) > 0) ...[const SizedBox(height: 8), _buildPriceRow("Diskon", -(widget.data['discount'] as int), currency, theme, isDiscount: true)],
                              const Divider(height: 24),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text("Metode Bayar", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(widget.data['paymentMethod'] ?? 'COD', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: theme.primary))),
                              ]),
                              const SizedBox(height: 16),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Total Tagihan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)), Text(currency.format(widget.data['totalPrice'] ?? 0), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green))]),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // TOMBOL AKSI UTAMA
                        if (canCancel || isDone)
                          SizedBox(
                            width: double.infinity,
                            child: canCancel
                                ? OutlinedButton.icon(
                              onPressed: _cancelOrder,
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: Text("Batalkan Pesanan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.redAccent), foregroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            )
                                : ElevatedButton.icon(
                              onPressed: _isGeneratingPdf ? null : _generateAndDownloadInvoice,
                              icon: _isGeneratingPdf
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                              label: Text(_isGeneratingPdf ? "Menyiapkan PDF..." : "Unduh Invoice", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                            ),
                          ),

                        const SizedBox(height: 40),
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

  Widget _buildSectionTitle(String title, AppThemeData theme) { return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: theme.textMain))); }
  BoxDecoration _cardDecoration(AppThemeData theme) { return BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]); }
  Widget _buildInfoRow(String label, String value, AppThemeData theme) { return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13))), Expanded(child: Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: theme.textMain, fontSize: 13), textAlign: TextAlign.right))]); }
  Widget _buildPriceRow(String label, int price, NumberFormat currency, AppThemeData theme, {bool isDiscount = false}) { return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: GoogleFonts.plusJakartaSans(color: isDiscount ? Colors.green : Colors.grey, fontSize: 14)), Text(currency.format(price), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: isDiscount ? Colors.green : theme.textMain, fontSize: 14))]); }
}