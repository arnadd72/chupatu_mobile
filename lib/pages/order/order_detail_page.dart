import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/utils/invoice_pdf_helper.dart';

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
  // Variabel untuk mengatur loading tombol invoice
  bool _isGeneratingPdf = false;

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

  // --- FUNGSI UNDUH INVOICE DENGAN LOADING ---
  Future<void> _generateAndDownloadInvoice() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      await InvoicePdfHelper.generateInvoice(widget.docId, widget.data);
    } catch (e) {
      if (mounted) {
        // KITA UBAH PESANNYA UNTUK MENAMPILKAN ERROR ASLI DARI SISTEM
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error Asli: ${e.toString()}"), // <-- Menampilkan error jujur
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5), // Tampil sedikit lebih lama
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  // --- FUNGSI PENERJEMAH TANGGAL ---
  String _formatSafeDate(dynamic dateData, {String fallback = '-', String format = 'dd MMMM yyyy, HH:mm'}) {
    if (dateData == null) return fallback;
    if (dateData is Timestamp) return DateFormat(format).format(dateData.toDate());
    if (dateData is String) return dateData;
    return dateData.toString();
  }

  // --- MAPPING IKON SERVIS ---
  Map<String, dynamic> _getServiceIcon(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'deep clean': return {'icon': Icons.water_drop_rounded, 'color': Colors.blue, 'lottie': 'assets/lottie/water_drop.json'};
      case 'fast clean': return {'icon': Icons.timer_rounded, 'color': Colors.orange, 'lottie': 'assets/lottie/Stopwatch.json'};
      case 'unyellowing':
      case 'unyellow': return {'icon': Icons.auto_awesome_rounded, 'color': Colors.amber, 'lottie': 'assets/lottie/sparkle.json'};
      case 'repair': return {'icon': Icons.build_rounded, 'color': Colors.grey.shade700, 'lottie': 'assets/lottie/wrench.json'};
      case 'repaint': return {'icon': Icons.format_paint_rounded, 'color': Colors.purple, 'lottie': 'assets/lottie/paint.json'};
      case 'waterproof': return {'icon': Icons.umbrella_rounded, 'color': Colors.teal, 'lottie': 'assets/lottie/umbrella.json'};
      case 'custom': return {'icon': Icons.design_services_rounded, 'color': Colors.pink, 'lottie': 'assets/lottie/pencil.json'};
      case 'pickup': return {'icon': Icons.two_wheeler_rounded, 'color': Colors.red, 'lottie': 'assets/lottie/delivery.json'};
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
    String fullAddress = (mainAddress.isNotEmpty || detailAddress.isNotEmpty) ? "$mainAddress\n\nCatatan Lokasi: $detailAddress" : (widget.data['address'] ?? 'Alamat tidak tersedia');

    // LOGIKA TOMBOL
    String currentStatus = widget.data['status'] ?? 'Pending';
    bool canCancel = (currentStatus == 'Pending' || currentStatus == 'Confirmed');
    bool isDone = (currentStatus == 'Done');

    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(backgroundColor: widget.statusColor, elevation: 0, iconTheme: const IconThemeData(color: Colors.white), title: Text("Detail Pesanan", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)), centerTitle: true),

            // bottomNavigationBar TELAH DIHAPUS (Dipindah ke bawah list)

            body: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: widget.statusColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30))),
                    child: Column(children: [
                      Icon(widget.statusIcon, color: Colors.white, size: 60), const SizedBox(height: 12),
                      Text(widget.statusLabel, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
                      Text("ID Pesanan: #${widget.docId.toUpperCase()}", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14)),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                        const SizedBox(height: 32), // Jarak sebelum tombol

                        // --- AREA TOMBOL DIPINDAH KE SINI ---
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

                        const SizedBox(height: 40), // Jarak ekstra di paling bawah agar enak di-scroll
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