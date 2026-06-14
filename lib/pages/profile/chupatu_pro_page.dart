import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart';
// PASTIKAN IMPORT INI SESUAI DENGAN LOKASI FILE ANDA
import 'package:chupatu_mobile/pages/profile/member_payment_page.dart';

class ChupatuProPage extends StatefulWidget {
  const ChupatuProPage({super.key});

  @override
  State<ChupatuProPage> createState() => _ChupatuProPageState();
}

class _ChupatuProPageState extends State<ChupatuProPage> {

  Future<void> _confirmDowngrade(BuildContext context) async {
    final freshUser = FirebaseAuth.instance.currentUser;
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi"),
        content: const Text("Yakin ingin berhenti berlangganan Pro? Semua benefit eksklusif akan hilang."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Ya, Berhenti", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true && freshUser != null) {
      await FirebaseFirestore.instance.collection('users').doc(freshUser.uid).update({
        'memberType': 'Regular Member', // Kembalikan ke default
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Anda telah kembali ke Member Reguler."), backgroundColor: Colors.orange)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final freshUser = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              backgroundColor: theme.surface,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
              title: Text("Membership", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            // Menggunakan StreamBuilder agar status Pro langsung terupdate setelah bayar/batal
            body: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(freshUser?.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  Map<String, dynamic> userData = {};
                  if (snapshot.hasData && snapshot.data!.data() != null) {
                    userData = snapshot.data!.data() as Map<String, dynamic>;
                  }

                  bool isPro = (userData['memberType'] == 'Pro');

                  // Hitung sisa hari masa aktif
                  DateTime? proValidUntil;
                  int proRemainingDays = 0;
                  String proExpiredLabel = '';
                  if (isPro && userData['proValidUntil'] != null) {
                    try {
                      final raw = userData['proValidUntil'];
                      if (raw is Timestamp) {
                        proValidUntil = raw.toDate();
                      } else {
                        proValidUntil = DateTime.tryParse(raw.toString());
                      }
                      if (proValidUntil != null) {
                        proRemainingDays = proValidUntil.difference(DateTime.now()).inDays;
                        proExpiredLabel = DateFormat('dd MMMM yyyy', 'id_ID').format(proValidUntil);
                      }
                    } catch (_) {}
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- HEADER KARTU BESAR ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFDB931), Color(0xFFECAA05)]
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFECAA05).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                  "Chupatu Pro ✨",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isPro
                                    ? "Terima kasih telah menjadi member eksklusif kami."
                                    : "Tingkatkan pengalaman cuci sepatu Anda ke level maksimal.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.9), fontSize: 14),
                              ),
                              // ── KETERANGAN MASA AKTIF ──
                              if (isPro && proValidUntil != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        proRemainingDays > 0
                                            ? "Aktif hingga $proExpiredLabel  •  $proRemainingDays hari lagi"
                                            : proRemainingDays == 0
                                                ? "Berakhir hari ini!"
                                                : "Masa aktif telah berakhir",
                                        style: GoogleFonts.plusJakartaSans(
                                          color: proRemainingDays <= 3 ? Colors.red.shade100 : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- DAFTAR BENEFIT LENGKAP ---
                        Text(
                            "Keuntungan Eksklusif",
                            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textMain)
                        ),
                        const SizedBox(height: 24),

                        _buildBenefitItem(
                            icon: Icons.flash_on_rounded,
                            title: "Layanan Prioritas (Fast Lane)",
                            desc: "Sepatu Anda selalu berada di urutan pertama antrean. Tidak perlu menunggu lama.",
                            theme: theme
                        ),
                        _buildBenefitItem(
                            icon: Icons.local_shipping_rounded,
                            title: "Gratis Antar Jemput",
                            desc: "Dapatkan gratis ongkir antar jemput tanpa minimal transaksi (area tertentu).",
                            theme: theme
                        ),
                        _buildBenefitItem(
                            icon: Icons.verified_rounded,
                            title: "Badge Emas Profil",
                            desc: "Tampil beda dengan badge khusus Pro di halaman profil Anda.",
                            theme: theme
                        ),
                        _buildBenefitItem(
                            icon: Icons.card_giftcard_rounded,
                            title: "Voucher Diskon Bulanan",
                            desc: "Otomatis mendapatkan voucher potongan harga khusus setiap bulannya.",
                            theme: theme
                        ),
                        _buildBenefitItem(
                            icon: Icons.support_agent_rounded,
                            title: "CS Prioritas",
                            desc: "Pesan Anda ke admin akan dibalas lebih cepat dibandingkan member biasa.",
                            theme: theme
                        ),
                        const SizedBox(height: 40),

                        // --- TOMBOL AKSI BERDASARKAN STATUS ---
                        if (isPro)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDowngrade(context),
                              icon: const Icon(Icons.cancel_outlined, size: 20),
                              label: Text("Berhenti Berlangganan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => MemberPaymentPage(
                                            onPaymentSuccess: () {
                                              // Beri feedback kalau bayar sukses (update Firestore diurus di MemberPaymentPage)
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Selamat Datang di Chupatu Pro! 🎉"), backgroundColor: Colors.green)
                                              );
                                            }
                                        )
                                    )
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primary,
                                elevation: 5,
                                shadowColor: theme.primary.withOpacity(0.5),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                  "Upgrade Sekarang - Rp 99.000/bln",
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                }
            ),
          );
        }
    );
  }

  Widget _buildBenefitItem({required IconData icon, required String title, required String desc, required AppThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: theme.primary, size: 24)
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain, fontSize: 16)),
                const SizedBox(height: 6),
                Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}