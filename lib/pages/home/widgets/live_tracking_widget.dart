import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/order/order_history_page.dart';

class LiveTrackingWidget extends StatelessWidget {
  final String userId;
  final AppThemeData theme;

  const LiveTrackingWidget(
      {super.key, required this.userId, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Tracking',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textMain)),
              GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OrderHistoryPage())),
                  child: Text('Lihat Semua',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: theme.primary,
                          fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: userId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, orderSnapshot) {
              // 1. Cek Error
              if (orderSnapshot.hasError) {
                return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16)),
                    child: const Text("Error memuat pesanan."));
              }

              // 2. REVISI LOGIKA LOADING:
              // Hanya tampilkan loading jika BENAR-BENAR tidak ada data sama sekali.
              // Kalau data sudah ada (misal update status), jangan tampilkan loading biar ga kedip.
              if (!orderSnapshot.hasData) {
                return Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24)),
                  // Opsional: Hilangkan loading jika ingin benar-benar statis, tapi sebaiknya ada di awal saja
                  child: const Center(
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                );
              }

              // Filter data aktif
              var activeDocs = orderSnapshot.data!.docs.where((doc) {
                String s = (doc.data() as Map)['status'] ?? '';
                return s != 'Done' && s != 'Cancelled';
              }).toList();

              // Jika tidak ada order aktif
              if (activeDocs.isEmpty) {
                return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Center(
                        child: Text("Tidak ada pesanan aktif",
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.grey))));
              }

              // Ambil data terbaru
              var latestOrder = activeDocs.first.data() as Map<String, dynamic>;
              String status = latestOrder['status'] ?? 'Pending';
              String shoeName = latestOrder['shoeDetail'] ?? 'Sepatu';
              String serviceName = latestOrder['serviceName'] ?? 'Layanan';

              double targetProgress = 0.1;
              Color statusColor = Colors.orange;

              if (status == 'Confirmed') {
                targetProgress = 0.25;
                statusColor = Colors.blue;
              } else if (status == 'Picked Up') {
                targetProgress = 0.50;
                statusColor = Colors.purple;
              } else if (status == 'Processing') {
                targetProgress = 0.75;
                statusColor = Colors.indigo;
              } else if (status == 'Ready') {
                targetProgress = 0.90;
                statusColor = Colors.teal;
              } else if (status == 'Delivery') {
                targetProgress = 1.0;
                statusColor = Colors.green;
              }

              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrderHistoryPage())),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5))
                      ],
                      border: Border.all(color: statusColor.withOpacity(0.3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16)),
                              child: Icon(Icons.local_laundry_service_rounded,
                                  color: statusColor)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(shoeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: theme.textMain)),
                                Text("$serviceName • Express",
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(status,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor)))
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. REVISI ANIMASI: TweenAnimationBuilder
                      // Ini membuat bar bergerak halus (sliding) saat status berubah,
                      // bukannya melompat atau loading ulang.
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: targetProgress),
                        duration: const Duration(
                            milliseconds: 1000), // Durasi animasi 1 detik
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.grey.shade100,
                                  color: statusColor,
                                  minHeight: 6));
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
