import 'dart:convert';
import 'package:chupatu_mobile/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/order/order_detail_page.dart';
import 'package:chupatu_mobile/pages/home/home_page.dart';
import 'package:skeletonizer/skeletonizer.dart';

// 👉 TAMBAHAN: Untuk buka link pembayaran Mayar dari History
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOGIC BATALKAN PESANAN ---
  Future<void> _cancelOrder(String docId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConfig.currentTheme.value.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Batalkan Pesanan?",
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: ThemeConfig.currentTheme.value.textMain)),
        content: Text("Tindakan ini tidak dapat diurungkan.",
            style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("Kembali", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(docId)
                  .update({'status': 'Cancelled'});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child:
                const Text("Batalkan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- POLLING STATUS PEMBAYARAN DARI HALAMAN RIWAYAT ---
  // Dijalankan setelah user klik "Bayar Sekarang" dan kembali dari browser Mayar
  Future<void> _pollPaymentStatusFromHistory(
      String orderId, String mayarPaymentId, String firebaseUid) async {
    if (!mounted) return;

    const String apiUrl =
        "https://malik-pseudomonocyclic-misti.ngrok-free.dev/api/check-payment-status";

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Mengecek status pembayaran...",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
            ),
          ],
        ),
      ),
    );

    // Polling: coba cek sampai 5x dengan jeda 3 detik
    String finalStatus = 'unpaid';
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 3));

      try {
        var checkResponse = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'order_id': orderId,
            'mayar_payment_id': mayarPaymentId,
            'firebase_uid': firebaseUid,
            'payment_type': 'service',
          }),
        );

        if (checkResponse.statusCode == 200) {
          var checkData = jsonDecode(checkResponse.body);
          debugPrint("Poll History #${i + 1}: status = ${checkData['status']}");

          if (checkData['status'] == 'paid') {
            finalStatus = 'paid';
            break;
          }
        }
      } catch (e) {
        debugPrint("Poll History error: $e");
      }
    }

    // Tutup dialog loading
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    if (finalStatus == 'paid') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("✅ Pembayaran berhasil! Status pesanan sudah diupdate."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Jika Anda sudah membayar, status akan otomatis terupdate dalam beberapa saat."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _showReviewDialog(
      String docId, String serviceName, AppThemeData theme) async {
    int rating = 5;
    TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    // 1. Simpan messenger & navigator sebelum masuk area async & dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (stateCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: theme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text("Beri Ulasan",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, color: theme.textMain),
                textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Bagaimana layanan $serviceName kami?",
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => rating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    style: TextStyle(color: theme.textMain),
                    decoration: InputDecoration(
                      hintText: "Tulis pengalamanmu di sini (Opsional)...",
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: theme.background,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text("Nanti Saja",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        FocusManager.instance.primaryFocus?.unfocus();

                        setDialogState(() => isSubmitting = true);

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            DocumentSnapshot userDoc = await FirebaseFirestore
                                .instance
                                .collection('users')
                                .doc(user.uid)
                                .get();
                            String userName = user.displayName ?? 'Pelanggan';
                            String userPhoto = user.photoURL ?? '';

                            if (userDoc.exists) {
                              var uData =
                                  userDoc.data() as Map<String, dynamic>;
                              userName = uData['username'] ??
                                  uData['name'] ??
                                  uData['displayName'] ??
                                  userName;
                              userPhoto = uData['photoURL'] ?? userPhoto;
                            }

                            await FirebaseFirestore.instance
                                .collection('reviews')
                                .add({
                              'userId': user.uid,
                              'userName': userName,
                              'userPhoto': userPhoto,
                              'rating': rating,
                              'reviewText': reviewController.text.trim(),
                              'serviceName': serviceName,
                              'orderId': docId,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            await FirebaseFirestore.instance
                                .collection('bookings')
                                .doc(docId)
                                .update({
                              'isReviewed': true,
                            });
                          }

                          if (mounted) {
                            navigator.pop();
                            scaffoldMessenger.showSnackBar(const SnackBar(
                                content:
                                    Text("Terima kasih atas ulasannya! ⭐")));
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          scaffoldMessenger.showSnackBar(SnackBar(
                              content: Text("Gagal mengirim ulasan: $e")));
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Kirim",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        },
      ),
    );
  }

  // --- KONFIGURASI ICON & WARNA ---
  Map<String, dynamic> _getServiceIcon(String serviceName) {
    String lowerService = serviceName.toLowerCase();
    if (lowerService.contains('custom'))
      return {
        'icon': Icons.design_services_rounded,
        'color': Colors.pink,
        'lottie': 'assets/lottie/pencil.json'
      };

    switch (lowerService) {
      case 'deep clean':
        return {
          'icon': Icons.water_drop_rounded,
          'color': Colors.blue,
          'lottie': 'assets/lottie/water_drop.json'
        };
      case 'fast clean':
        return {
          'icon': Icons.timer_rounded,
          'color': Colors.orange,
          'lottie': 'assets/lottie/Stopwatch.json'
        };
      case 'unyellowing':
        return {
          'icon': Icons.auto_awesome_rounded,
          'color': Colors.amber,
          'lottie': 'assets/lottie/sparkle.json'
        };
      case 'repair':
        return {
          'icon': Icons.build_rounded,
          'color': Colors.grey.shade700,
          'lottie': 'assets/lottie/wrench.json'
        };
      case 'repaint':
        return {
          'icon': Icons.format_paint_rounded,
          'color': Colors.purple,
          'lottie': 'assets/lottie/paint.json'
        };
      case 'waterproof':
        return {
          'icon': Icons.umbrella_rounded,
          'color': Colors.teal,
          'lottie': 'assets/lottie/umbrella.json'
        };
      default:
        return {
          'icon': Icons.cleaning_services_rounded,
          'color': Colors.indigo
        };
    }
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'Pending':
        return {
          'color': const Color(0xFFF59E0B),
          'icon': Icons.pending_actions_rounded,
          'step': 1,
          'label': 'Menunggu Konfirmasi'
        };
      case 'Confirmed':
        return {
          'color': const Color(0xFF3B82F6),
          'icon': Icons.check_circle_outline_rounded,
          'step': 2,
          'label': 'Dikonfirmasi'
        };
      case 'Picked Up':
        return {
          'color': const Color(0xFF8B5CF6),
          'icon': Icons.local_shipping_outlined,
          'step': 3,
          'label': 'Sepatu Dijemput'
        };
      case 'Processing':
        return {
          'color': const Color(0xFF10B981),
          'icon': Icons.cleaning_services_rounded,
          'step': 4,
          'label': 'Sedang Dicuci'
        };
      case 'Ready':
        return {
          'color': const Color(0xFF14B8A6),
          'icon': Icons.inventory_2_outlined,
          'step': 5,
          'label': 'Selesai Dicuci'
        };
      case 'Delivery':
        return {
          'color': const Color(0xFF6366F1),
          'icon': Icons.delivery_dining_rounded,
          'step': 6,
          'label': 'Sedang Diantar'
        };
      case 'Done':
        return {
          'color': const Color(0xFF22C55E),
          'icon': Icons.task_alt_rounded,
          'step': 7,
          'label': 'Pesanan Selesai'
        };
      case 'Cancelled':
        return {
          'color': const Color(0xFFEF4444),
          'icon': Icons.cancel_outlined,
          'step': 0,
          'label': 'Dibatalkan'
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.help_outline,
          'step': 0,
          'label': 'Tidak Dikenal'
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text("Pesanan Saya",
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold, color: theme.textMain)),
              centerTitle: true,
              backgroundColor: theme.surface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: theme.textMain),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MainPage()),
                        (route) => false);
                  }
                },
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: theme.primary,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorColor: theme.primary,
                tabs: const [Tab(text: "Dalam Proses"), Tab(text: "Riwayat")],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(isActive: true, theme: theme),
                _buildOrderList(isActive: false, theme: theme),
              ],
            ),
          );
        });
  }

  Widget _buildOrderList(
      {required bool isActive, required AppThemeData theme}) {
    if (_uid == null) return const Center(child: Text("Silakan login"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: _uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        if (!isLoading && (!snapshot.hasData || snapshot.data!.docs.isEmpty))
          return const Center(child: Text("Belum ada pesanan."));

        var docs = isLoading ? [] : snapshot.data!.docs;
        final filteredDocs = isLoading ? [] : docs.where((doc) {
          String status = (doc.data() as Map)['status'] ?? 'Pending';
          return isActive
              ? (status != 'Done' && status != 'Cancelled')
              : (status == 'Done' || status == 'Cancelled');
        }).toList();

        if (!isLoading && filteredDocs.isEmpty)
          return const Center(child: Text("Belum ada pesanan."));

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Skeletonizer(
              enabled: isLoading,
              child: ListView.separated(
                padding: const EdgeInsets.only(
                    top: 20, left: 20, right: 20, bottom: 100),
                itemCount: isLoading ? 3 : filteredDocs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (isLoading) {
                    return _buildPremiumCard("dummy123", {
                      "status": "Pending",
                      "serviceName": "Deep Clean",
                      "totalPrice": 50000,
                      "shoeDetail": "Loading shoe data..."
                    }, theme, isActive);
                  }
                  var document = filteredDocs[index];
                  return _buildPremiumCard(document.id,
                      document.data() as Map<String, dynamic>, theme, isActive);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumCard(String docId, Map<String, dynamic> data,
      AppThemeData theme, bool isActive) {
    String status = data['status'] ?? 'Unknown';
    final config = _getStatusConfig(status);
    Color statusColor = config['color'];

    String serviceName = data['serviceName'] ?? 'Layanan';
    final serviceConfig = _getServiceIcon(serviceName);

    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Status Logic
    bool canCancel = (status == 'Pending' || status == 'Confirmed');
    bool isDone = (status == 'Done');
    bool isReviewed = data['isReviewed'] == true;

    // 👉 TAMBAHAN LOGIKA: Cek status pembayaran dari Webhook
    String paymentStatus = data['paymentStatus'] ?? '';
    bool isPendingPayment = (paymentStatus == 'Pending Payment');
    bool isPaid = (paymentStatus == 'PAID' ||
        paymentStatus == 'SUCCESS'); // Cek jika lunas
    String paymentUrl = data['paymentUrl'] ?? '';

    String dateStr = "-";
    if (data['createdAt'] != null) {
      dateStr = DateFormat('dd MMM yyyy, HH:mm')
          .format((data['createdAt'] as Timestamp).toDate());
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(
              docId: docId,
              data: data,
              statusColor: statusColor,
              statusIcon: config['icon'],
              statusLabel: config['label'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        child: Column(
          children: [
            // Banner Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(config['icon'], color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(config['label'],
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor)),
                  ]),
                  Text("#${docId.substring(0, 6).toUpperCase()}",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Info Service & Sepatu
                  Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: serviceConfig['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16)),
                        child: serviceConfig.containsKey('lottie')
                            ? Lottie.asset(serviceConfig['lottie'],
                                fit: BoxFit.contain)
                            : Icon(serviceConfig['icon'],
                                color: serviceConfig['color'], size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(serviceName,
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: theme.textMain)),
                            const SizedBox(height: 4),
                            Text(data['shoeDetail'] ?? 'Detail sepatu',
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey.shade600, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(dateStr,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11, color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 👉 UI BARU: Indikator Dinamis (Pending Oranye ATAU Lunas Hijau)
                  if (isActive &&
                      isPendingPayment &&
                      paymentUrl.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text("Menunggu Pembayaran",
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (isActive && isPaid) ...[
                    // 👉 Indikator Lunas (Muncul otomatis saat Webhook berhasil tembak PAID)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text("Pembayaran Lunas (Verified)",
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Progress Bar
                  if (isActive && status != 'Cancelled') ...[
                    _buildAnimatedProgressBar(
                        config['step'], statusColor, theme),
                    const SizedBox(height: 16),
                  ],

                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Footer (Harga & Tombol)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. BARIS HARGA (Kiri - Kanan)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total Pembayaran",
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: Colors.grey)),
                          Text(currency.format(data['totalPrice'] ?? 0),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: theme.textMain)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 2. BARIS TOMBOL (Otomatis turun ke bawah kalau gak muat)
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.end, // Rata kanan
                          spacing: 8, // Jarak antar tombol ke samping
                          runSpacing:
                              8, // Jarak antar tombol ke bawah (kalau numpuk)
                          children: [
                            // 👉 TOMBOL BAYAR SEKARANG (Otomatis hilang kalau isPendingPayment false)
                            if (canCancel &&
                                isPendingPayment &&
                                paymentUrl.isNotEmpty)
                              ElevatedButton(
                                onPressed: () async {
                                  // Buka halaman bayar Mayar
                                  await launchUrl(
                                    Uri.parse(paymentUrl),
                                    mode: LaunchMode.inAppBrowserView,
                                  );

                                  // Setelah user kembali dari browser, cek status pembayaran
                                  String mayarPaymentId =
                                      data['mayarPaymentId'] ?? '';
                                  if (mayarPaymentId.isNotEmpty && mounted) {
                                    await _pollPaymentStatusFromHistory(
                                      docId,
                                      mayarPaymentId,
                                      data['userId'] ?? '',
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF0606F9), // Biru Chupatu
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                child: Text("Bayar Sekarang",
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ),

                            // TOMBOL BATALKAN
                            if (canCancel)
                              OutlinedButton(
                                onPressed: () => _cancelOrder(docId),
                                style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Colors.redAccent),
                                    foregroundColor: Colors.redAccent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                child: Text("Batalkan",
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ),

                            // TOMBOL ULASAN
                            if (isDone && !isReviewed)
                              ElevatedButton(
                                onPressed: () => _showReviewDialog(
                                    docId, serviceName, theme),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                child: Text("Beri Ulasan",
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ),

                            // TOMBOL DETAIL
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailPage(
                                      docId: docId,
                                      data: data,
                                      statusColor: statusColor,
                                      statusIcon: config['icon'],
                                      statusLabel: config['label'],
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              child: Text("Detail",
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedProgressBar(
      int currentStep, Color activeColor, AppThemeData theme) {
    const int totalSteps = 6;
    double progress = currentStep / totalSteps;
    int percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Progres Pengerjaan",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            Text("$percentage%",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: activeColor)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                      height: 8,
                      width: constraints.maxWidth,
                      color: Colors.grey.shade200),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutQuart,
                    height: 8,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                            color: activeColor.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
