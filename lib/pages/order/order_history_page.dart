import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart'; // IMPORT LOTTIE WAJIB ADA
import 'package:chupatu_mobile/main.dart';
// IMPORT HALAMAN DETAIL
import 'package:chupatu_mobile/pages/order/order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> with SingleTickerProviderStateMixin {
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

  Future<void> _cancelOrder(String docId) async {
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
              await FirebaseFirestore.instance.collection('bookings').doc(docId).update({'status': 'Cancelled'});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Batalkan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- MAPPING IKON SERVIS DENGAN FILE LOTTIE ---
  Map<String, dynamic> _getServiceIcon(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'deep clean':
        return {'icon': Icons.water_drop_rounded, 'color': Colors.blue, 'lottie': 'assets/lottie/water_drop.json'};
      case 'fast clean':
        return {'icon': Icons.timer_rounded, 'color': Colors.orange, 'lottie': 'assets/lottie/Stopwatch.json'};
      case 'unyellowing':
      case 'unyellow':
        return {'icon': Icons.auto_awesome_rounded, 'color': Colors.amber, 'lottie': 'assets/lottie/sparkle.json'};
      case 'repair':
        return {'icon': Icons.build_rounded, 'color': Colors.grey.shade700, 'lottie': 'assets/lottie/wrench.json'};
      case 'repaint':
        return {'icon': Icons.format_paint_rounded, 'color': Colors.purple, 'lottie': 'assets/lottie/paint.json'};
      case 'waterproof':
        return {'icon': Icons.umbrella_rounded, 'color': Colors.teal, 'lottie': 'assets/lottie/umbrella.json'};
      case 'custom':
        return {'icon': Icons.design_services_rounded, 'color': Colors.pink, 'lottie': 'assets/lottie/pencil.json'};
      case 'pickup':
        return {'icon': Icons.two_wheeler_rounded, 'color': Colors.red, 'lottie': 'assets/lottie/delivery.json'};
      default:
        return {'icon': Icons.cleaning_services_rounded, 'color': Colors.indigo}; // Fallback jika tidak ada Lottie
    }
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'Pending': return {'color': const Color(0xFFF59E0B), 'icon': Icons.pending_actions_rounded, 'step': 1, 'label': 'Menunggu Konfirmasi'};
      case 'Confirmed': return {'color': const Color(0xFF3B82F6), 'icon': Icons.check_circle_outline_rounded, 'step': 2, 'label': 'Dikonfirmasi'};
      case 'Picked Up': return {'color': const Color(0xFF8B5CF6), 'icon': Icons.local_shipping_outlined, 'step': 3, 'label': 'Sepatu Dijemput'};
      case 'Processing': return {'color': const Color(0xFF10B981), 'icon': Icons.cleaning_services_rounded, 'step': 4, 'label': 'Sedang Dicuci'};
      case 'Ready': return {'color': const Color(0xFF14B8A6), 'icon': Icons.inventory_2_outlined, 'step': 5, 'label': 'Selesai Dicuci'};
      case 'Delivery': return {'color': const Color(0xFF6366F1), 'icon': Icons.delivery_dining_rounded, 'step': 6, 'label': 'Sedang Diantar'};
      case 'Done': return {'color': const Color(0xFF22C55E), 'icon': Icons.task_alt_rounded, 'step': 7, 'label': 'Pesanan Selesai'};
      case 'Cancelled': return {'color': const Color(0xFFEF4444), 'icon': Icons.cancel_outlined, 'step': 0, 'label': 'Dibatalkan'};
      default: return {'color': Colors.grey, 'icon': Icons.help_outline, 'step': 0, 'label': 'Tidak Dikenal'};
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
              title: Text("Pesanan Saya", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              centerTitle: true,
              backgroundColor: theme.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
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

  Widget _buildOrderList({required bool isActive, required AppThemeData theme}) {
    if (_uid == null) return const Center(child: Text("Silakan login"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: _uid).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada pesanan."));

        final filteredDocs = snapshot.data!.docs.where((doc) {
          String status = (doc.data() as Map)['status'] ?? 'Pending';
          return isActive ? (status != 'Done' && status != 'Cancelled') : (status == 'Done' || status == 'Cancelled');
        }).toList();

        if (filteredDocs.isEmpty) return const Center(child: Text("Belum ada pesanan."));

        return ListView.separated(
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 100),
          itemCount: filteredDocs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildPremiumCard(filteredDocs[index].id, filteredDocs[index].data() as Map<String, dynamic>, theme, isActive);
          },
        );
      },
    );
  }

  Widget _buildPremiumCard(String docId, Map<String, dynamic> data, AppThemeData theme, bool isActive) {
    String status = data['status'] ?? 'Unknown';
    final config = _getStatusConfig(status);
    Color statusColor = config['color'];

    // Konfigurasi Lottie dari Fungsi
    String serviceName = data['serviceName'] ?? 'Layanan';
    final serviceConfig = _getServiceIcon(serviceName);

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    bool canCancel = (status == 'Pending' || status == 'Confirmed');

    String dateStr = "-";
    if (data['createdAt'] != null) {
      dateStr = DateFormat('dd MMM yyyy, HH:mm').format((data['createdAt'] as Timestamp).toDate());
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
              statusIcon: config['icon'], // Icon banner tetap menggunakan icon statis agar rapi
              statusLabel: config['label'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
          border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(config['icon'], color: statusColor, size: 20), const SizedBox(width: 8),
                    Text(config['label'], style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor)),
                  ]),
                  Text("#${docId.substring(0, 6).toUpperCase()}", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // INFO SEPATU DENGAN LOTTIE ANIMATION
                  Row(
                    children: [
                      Container(
                        width: 55, height: 55,
                        padding: const EdgeInsets.all(10), // Memberi ruang agar Lottie tidak nabrak pinggiran
                        decoration: BoxDecoration(color: serviceConfig['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        // LOGIKA LOTTIE
                        child: serviceConfig.containsKey('lottie')
                            ? Lottie.asset(serviceConfig['lottie'], fit: BoxFit.contain)
                            : Icon(serviceConfig['icon'], color: serviceConfig['color'], size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(serviceName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: theme.textMain)),
                            const SizedBox(height: 4),
                            Text(data['shoeDetail'] ?? 'Detail sepatu', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(dateStr, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // PROGRESS BAR ANIMASI
                  if (isActive && status != 'Cancelled') ...[
                    _buildAnimatedProgressBar(config['step'], statusColor, theme),
                    const SizedBox(height: 16),
                  ],

                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // FOOTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total Pembayaran", style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey)),
                          Text(currency.format(data['totalPrice'] ?? 0), style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: theme.textMain)),
                        ],
                      ),

                      // DERETAN TOMBOL BATAL & DETAIL
                      Row(
                        children: [
                          if (canCancel) ...[
                            OutlinedButton(
                              onPressed: () => _cancelOrder(docId),
                              style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.redAccent),
                                  foregroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                              ),
                              child: Text("Batalkan", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                          ],
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
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                            ),
                            child: Text("Detail", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        ],
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

  // WIDGET PROGRESS BAR ANIMASI BARU
  Widget _buildAnimatedProgressBar(int currentStep, Color activeColor, AppThemeData theme) {
    const int totalSteps = 6;
    double progress = currentStep / totalSteps;
    int percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Progres Pengerjaan", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            Text("$percentage%", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: activeColor)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(height: 8, width: constraints.maxWidth, color: Colors.grey.shade200),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutQuart,
                    height: 8,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: activeColor.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))],
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