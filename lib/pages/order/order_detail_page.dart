import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/utils/invoice_pdf_helper.dart';
import 'package:chupatu_mobile/pages/home/magic_result_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoadingChat = false;

  Future<void> _openGoogleMapsLocation(double lat, double lng) async {
    final String url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching Google Maps: $e");
    }
  }

  Future<void> _openGoogleMapsDirections(double originLat, double originLng, double destLat, double destLng) async {
    final String url = "https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving";
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching Google Maps Directions: $e");
    }
  }

  // --- FUNGSI BUKA CHAT KE ADMIN ---
  Future<void> _openChatWithAdmin() async {
    setState(() => _isLoadingChat = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Silakan login terlebih dahulu."))
        );
        return;
      }

      var chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      String chatId;

      if (chatQuery.docs.isNotEmpty) {
        chatId = chatQuery.docs.first.id;
      } else {
        DocumentReference newChat = await FirebaseFirestore.instance
            .collection('chats').add({
          'userId': user.uid,
          'userName': user.displayName ?? 'Customer',
          'lastMessage': 'Halo Admin, saya mau tanya pesanan #${widget.docId.substring(0, 6)}',
          'lastTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        chatId = newChat.id;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(
            name: "Admin Chupatu",
            isOnline: true,
            chatId: chatId,
            isAdmin: false,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membuka chat: $e"))
      );
    } finally {
      if (mounted) setState(() => _isLoadingChat = false);
    }
  }

  // --- FUNGSI TAMPILKAN BARCODE ---
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
              Text("Barcode Pesanan", style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.bold
              )),
              const SizedBox(height: 8),
              Text("Tunjukkan ke kasir/kurir", style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: Colors.grey
              )),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12)
                ),
                child: QrImageView(
                  data: widget.docId,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),

              const SizedBox(height: 12),
              Text("#${widget.docId.toUpperCase().substring(0, 8)}",
                  style: GoogleFonts.robotoMono(
                      fontWeight: FontWeight.bold, letterSpacing: 1.5
                  )
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white
                  ),
                  child: const Text("Tutup"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- FUNGSI LIHAT GAMBAR FULL SCREEN ---
  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true, // Bisa digeser
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4, // Bisa di zoom sampai 4x
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator(color: Colors.white);
                },
                errorBuilder: (context, error, stackTrace) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 50),
                    SizedBox(height: 10),
                    Text("Gagal memuat gambar", style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
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
        title: Text("Batalkan Pesanan?", style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold
        )),
        content: Text("Tindakan ini tidak dapat diurungkan.",
            style: GoogleFonts.plusJakartaSans()
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Kembali")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('bookings')
                  .doc(widget.docId).update({'status': 'Cancelled'});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Pesanan dibatalkan", style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.red
                    )
                );
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
  Future<void> _generateAndDownloadInvoice(Map<String, dynamic> data) async {
    setState(() => _isGeneratingPdf = true);
    try {
      await InvoicePdfHelper.generateInvoice(widget.docId, data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${e.toString()}"), backgroundColor: Colors.red)
        );
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

  // ==========================================================
  // WIDGET BARU: MAGIC RESULT (BEFORE - AFTER) UNTUK PELANGGAN
  // ==========================================================

  Widget _buildMagicResultSection(Map<String, dynamic> data, AppThemeData theme) {
    String beforeImg = data['shoeImageUrl'] ?? '';
    String afterImg = data['afterImageUrl'] ?? '';
    String status = data['status'] ?? '';

    // Cuma tampil kalau statusnya Done dan Admin udah upload foto After
    if (status != 'Done' || afterImg.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
            "Magic Result ✨",
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain
            )
        ),
        const SizedBox(height: 8),
        Text(
            "Sepatu kamu sudah kembali kinclong seperti baru!",
            style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13)
        ),
        const SizedBox(height: 16),

        // BANNER PREVIEW YANG BISA DI-KLIK
        GestureDetector(
          onTap: () {
            // Pindah ke Halaman Full Screen Interaktif
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MagicResultDetailPage(
                      title: "Sepatu Kamu",
                      beforeImg: beforeImg.isNotEmpty ? beforeImg : afterImg, // Fallback aman
                      afterImg: afterImg,
                    )
                )
            );
          },
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(afterImg), // Tampilkan hasil akhirnya sebagai background
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.green.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)
                  )
                ]
            ),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.black87, Colors.transparent]
                  )
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8)
                            ),
                            child: const Text("SELESAI", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              "Lihat Hasil\nCucianmu",
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2
                              )
                          ),
                        ],
                      )
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white)
                    ),
                    child: const Icon(Icons.compare_rounded, color: Colors.white),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'Pending': return {'color': const Color(0xFFF59E0B), 'icon': Icons.pending_actions_rounded, 'label': 'Menunggu Konfirmasi'};
      case 'Confirmed': return {'color': const Color(0xFF3B82F6), 'icon': Icons.check_circle_outline_rounded, 'label': 'Dikonfirmasi'};
      case 'Picked Up': return {'color': const Color(0xFF8B5CF6), 'icon': Icons.local_shipping_outlined, 'label': 'Sepatu Dijemput'};
      case 'Processing': return {'color': const Color(0xFF10B981), 'icon': Icons.cleaning_services_rounded, 'label': 'Sedang Dicuci'};
      case 'Ready': return {'color': const Color(0xFF14B8A6), 'icon': Icons.inventory_2_outlined, 'label': 'Selesai Dicuci'};
      case 'Delivery': return {'color': const Color(0xFF6366F1), 'icon': Icons.delivery_dining_rounded, 'label': 'Sedang Diantar'};
      case 'Done': return {'color': const Color(0xFF22C55E), 'icon': Icons.task_alt_rounded, 'label': 'Pesanan Selesai'};
      case 'Cancelled': return {'color': const Color(0xFFEF4444), 'icon': Icons.cancel_outlined, 'label': 'Dibatalkan'};
      default: return {'color': Colors.grey, 'icon': Icons.help_outline, 'label': 'Tidak Dikenal'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').doc(widget.docId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Pesanan tidak ditemukan.")),
          );
        }

        var bookingData = snapshot.data!.data() as Map<String, dynamic>;

        final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        String serviceName = bookingData['serviceName'] ?? 'Layanan';
        final serviceConfig = _getServiceIcon(serviceName);
        String dateStr = _formatSafeDate(bookingData['createdAt']);
        String pickupDateOnly = _formatSafeDate(
            bookingData['pickupDate'], format: 'dd MMMM yyyy', fallback: 'Belum dijadwalkan'
        );
        String pickupTimeStr = bookingData['pickupTime'] ?? '';
        String finalPickup = pickupTimeStr.isNotEmpty ? "$pickupDateOnly\nJam: $pickupTimeStr" : pickupDateOnly;
        bool isDelivery = bookingData['isDelivery'] ?? false;
        String finalDelivery = isDelivery ? "Akan diantar setelah pesanan selesai" : "Ambil sendiri ke toko (Self Pick-up)";

        String mainAddress = bookingData['mainAddress'] ?? '';
        String detailAddress = bookingData['detailAddress'] ?? '';
        String fullAddress = (mainAddress.isNotEmpty || detailAddress.isNotEmpty)
            ? "$mainAddress\n\nCatatan: $detailAddress"
            : (bookingData['address'] ?? 'Alamat tidak tersedia');

        String currentStatus = bookingData['status'] ?? 'Pending';
        bool canCancel = (currentStatus == 'Pending' || currentStatus == 'Confirmed' || currentStatus == 'Pending Payment');
        bool isDone = (currentStatus == 'Done');

        // 👉 URL Foto Sepatu Sebelum Dicuci
        String? shoeImageUrl = bookingData['shoeImageUrl'];

        final statusConfig = _getStatusConfig(currentStatus);
        Color statusColor = statusConfig['color'];
        IconData statusIcon = statusConfig['icon'];
        String statusLabel = statusConfig['label'];

        return ValueListenableBuilder<AppThemeData>(
            valueListenable: ThemeConfig.currentTheme,
            builder: (context, theme, child) {
              return Scaffold(
                backgroundColor: theme.background,
                appBar: AppBar(
                  backgroundColor: statusColor,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: Text("Detail Pesanan", style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontWeight: FontWeight.bold
                  )),
                  centerTitle: true,
                  actions: [
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
                        decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30))
                        ),
                        child: Column(children: [
                          Icon(statusIcon, color: Colors.white, size: 60),
                          const SizedBox(height: 12),
                          Text(statusLabel, style: GoogleFonts.plusJakartaSans(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold
                          )),
                          const SizedBox(height: 4),
                          Text("ID: #${widget.docId.substring(0, 8).toUpperCase()}",
                              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14)
                          ),
                        ]),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // --- TOMBOL HUBUNGI ADMIN ---
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingChat ? null : _openChatWithAdmin,
                                icon: _isLoadingChat
                                    ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.support_agent_rounded),
                                label: Text(_isLoadingChat ? "Menghubungkan..." : "Hubungi Admin",
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)
                                ),
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

                            // --- WIDGET LIVE TRACKING MAPS DENGAN TOMBOL ---
                            if (currentStatus == 'Picked Up' || currentStatus == 'Delivery') ...[
                              _buildSectionTitle("Pelacakan Kurir", theme),

                              Builder(
                                builder: (context) {
                                  GeoPoint? driverGeo = bookingData['driverLocation'];
                                  GeoPoint? custGeo = bookingData['customerLocation'];
                                  
                                  bool hasDriverLoc = driverGeo != null;
                                  
                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 24),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.primary.withOpacity(0.05),
                                          theme.primary.withOpacity(0.1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: theme.primary.withOpacity(0.2), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 10, offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: theme.primary.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.local_shipping_rounded,
                                                color: theme.primary,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    currentStatus == 'Picked Up'
                                                        ? "Kurir Sedang Menjemput"
                                                        : "Kurir Sedang Mengantar",
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: theme.textMain,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    hasDriverLoc
                                                        ? "GPS aktif • Terakhir diperbarui secara live"
                                                        : "Menunggu kurir mengaktifkan GPS...",
                                                    style: GoogleFonts.plusJakartaSans(
                                                      color: hasDriverLoc ? Colors.green.shade700 : Colors.grey.shade500,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          "Anda dapat melacak lokasi kurir secara real-time menggunakan aplikasi Google Maps di HP Anda.\n\n💡 Tips: Jika kurir sedang bergerak, kembali ke aplikasi Chupatu lalu tekan tombol di bawah ini lagi untuk memperbarui posisi terbaru kurir.",
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: !hasDriverLoc
                                                ? null
                                                : () {
                                                    final driverVal = driverGeo;
                                                    final custVal = custGeo;
                                                    if (custVal != null) {
                                                      _openGoogleMapsDirections(
                                                        driverVal.latitude,
                                                        driverVal.longitude,
                                                        custVal.latitude,
                                                        custVal.longitude,
                                                      );
                                                    } else {
                                                      _openGoogleMapsLocation(
                                                        driverVal.latitude,
                                                        driverVal.longitude,
                                                      );
                                                    }
                                                  },
                                            icon: const Icon(Icons.map_rounded, color: Colors.white),
                                            label: Text(
                                              hasDriverLoc ? "Buka Peta Google Maps" : "Menunggu Sinyal GPS...",
                                              style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: theme.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              elevation: 2,
                                              shadowColor: theme.primary.withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ],
                            // --- AKHIR WIDGET MAPS ---

                            // INFO LAYANAN
                            _buildSectionTitle("Informasi Layanan", theme),
                            Container(
                              padding: const EdgeInsets.all(16), decoration: _cardDecoration(theme),
                              child: Column(
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 50, height: 50, padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: serviceConfig['color'].withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12)
                                      ),
                                      child: serviceConfig.containsKey('lottie')
                                          ? Lottie.asset(serviceConfig['lottie'], fit: BoxFit.contain)
                                          : Icon(serviceConfig['icon'], color: serviceConfig['color'], size: 26),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(serviceName, style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain
                                              )),
                                              Text(bookingData['shoeDetail'] ?? 'Detail sepatu',
                                                  style: GoogleFonts.plusJakartaSans(color: Colors.grey)
                                              )
                                            ]
                                        )
                                    ),
                                  ]),
                                  const Divider(height: 24),
                                  _buildInfoRow("Kategori", bookingData['category'] ?? '-', theme),
                                  const SizedBox(height: 8),
                                  _buildInfoRow("Tanggal Order", dateStr, theme),
                                  const SizedBox(height: 8),
                                  _buildInfoRow("Catatan", bookingData['notes'] ?? '-', theme),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 👉 WIDGET: FOTO SEPATU PELANGGAN (JIKA ADA)
                            if (shoeImageUrl != null && shoeImageUrl.isNotEmpty && !isDone) ...[
                              _buildSectionTitle("Foto Sepatu (Before)", theme),
                              GestureDetector(
                                onTap: () => _showFullScreenImage(shoeImageUrl),
                                child: Container(
                                  width: double.infinity,
                                  height: 180,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          shoeImageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              color: theme.surface,
                                              child: const Center(child: CircularProgressIndicator()),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: theme.surface,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey.shade400),
                                                const SizedBox(height: 8),
                                                Text("Gagal memuat foto", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Ikon Kaca Pembesar di pojok biar user tau bisa diklik
                                        Positioned(
                                          right: 12,
                                          bottom: 12,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 20),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // ALAMAT
                            _buildSectionTitle("Alamat & Jadwal", theme),
                            Container(
                              padding: const EdgeInsets.all(16), decoration: _cardDecoration(theme),
                              child: Column(
                                children: [
                                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Icon(Icons.location_on, color: Colors.red.shade400, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Alamat Penjemputan", style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain
                                              )),
                                              const SizedBox(height: 4),
                                              Text(fullAddress, style: GoogleFonts.plusJakartaSans(
                                                  color: Colors.grey, height: 1.5
                                              ))
                                            ]
                                        )
                                    ),
                                  ]),
                                  const Divider(height: 24),
                                  _buildInfoRow("Jadwal Jemput", finalPickup, theme),
                                  const SizedBox(height: 8),
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
                                  _buildPriceRow("Harga Layanan", bookingData['basePrice'] ?? 0, currency, theme),
                                  const SizedBox(height: 8),
                                  _buildPriceRow("Biaya Antar Jemput", bookingData['deliveryFee'] ?? 0, currency, theme),
                                  if ((bookingData['discount'] ?? 0) > 0) ...[
                                    const SizedBox(height: 8),
                                    _buildPriceRow("Diskon", -(bookingData['discount'] as int), currency, theme, isDiscount: true)
                                  ],
                                  const Divider(height: 24),
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Metode Bayar", style: GoogleFonts.plusJakartaSans(
                                            color: Colors.grey, fontSize: 12
                                        )),
                                        Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: theme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8)
                                            ),
                                            child: Text(bookingData['paymentMethod'] ?? 'COD',
                                                style: GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.bold, fontSize: 12, color: theme.primary
                                                )
                                            )
                                        ),
                                      ]
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Total Tagihan", style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain
                                        )),
                                        Text(currency.format(bookingData['totalPrice'] ?? 0),
                                            style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green
                                            )
                                        )
                                      ]
                                  ),
                                ],
                              ),
                            ),

                            // ==========================================================
                            // PEMANGGILAN WIDGET MAGIC RESULT
                            // ==========================================================
                            _buildMagicResultSection(bookingData, theme),

                            const SizedBox(height: 32),

                            // TOMBOL AKSI UTAMA
                            if (canCancel || isDone)
                              SizedBox(
                                width: double.infinity,
                                child: canCancel
                                    ? OutlinedButton.icon(
                                  onPressed: _cancelOrder,
                                  icon: const Icon(Icons.cancel_outlined, size: 18),
                                  label: Text("Batalkan Pesanan", style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold
                                  )),
                                  style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Colors.redAccent),
                                      foregroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                                  ),
                                )
                                    : ElevatedButton.icon(
                                  onPressed: _isGeneratingPdf ? null : () => _generateAndDownloadInvoice(bookingData),
                                  icon: _isGeneratingPdf
                                      ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                  label: Text(_isGeneratingPdf ? "Menyiapkan PDF..." : "Unduh Invoice",
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)
                                  ),
                                  style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 0
                                  ),
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
    );
  }

  Widget _buildSectionTitle(String title, AppThemeData theme) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w800, color: theme.textMain
        ))
    );
  }

  BoxDecoration _cardDecoration(AppThemeData theme) {
    return BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ]
    );
  }

  Widget _buildInfoRow(String label, String value, AppThemeData theme) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: GoogleFonts.plusJakartaSans(
              color: Colors.grey, fontSize: 13
          ))),
          Expanded(child: Text(value, style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600, color: theme.textMain, fontSize: 13
          ), textAlign: TextAlign.right))
        ]
    );
  }

  Widget _buildPriceRow(String label, int price, NumberFormat currency, AppThemeData theme, {bool isDiscount = false}) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(
              color: isDiscount ? Colors.green : Colors.grey, fontSize: 14
          )),
          Text(currency.format(price), style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600, color: isDiscount ? Colors.green : theme.textMain, fontSize: 14
          ))
        ]
    );
  }
}