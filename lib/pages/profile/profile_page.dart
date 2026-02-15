import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fitur Copy to Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal lahir
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/profile/member_payment_page.dart'; // Import halaman pembayaran untuk navigasi Upgrade

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- FUNGSI UPDATE DATA KE FIRESTORE ---
  Future<void> _updateUserData(String field, String value) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        field: value,
      }, SetOptions(merge: true));

      if (field == 'name') {
        await user!.updateDisplayName(value);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- POP-UP BOTTOM SHEET STATUS MEMBER ---
  void _showMemberStatusDetails(bool isPro, AppThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Garis indikator drag
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),

            // Judul BottomSheet
            Text(
              isPro ? "Chupatu Pro Benefits ✨" : "Member Reguler",
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textMain),
            ),
            const SizedBox(height: 8),
            Text(
              isPro ? "Nikmati layanan eksklusif khusus untuk Anda." : "Upgrade ke Pro untuk pengalaman terbaik.",
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Daftar Manfaat (Icon, Judul, Deskripsi)
            _buildBenefitItem(Icons.flash_on_rounded, "Layanan Prioritas", "Sepatu Anda dikerjakan lebih awal dari antrean reguler.", theme),
            _buildBenefitItem(Icons.local_shipping_rounded, "Gratis Antar Jemput", "Tanpa biaya tambahan untuk area cakupan tertentu.", theme),
            _buildBenefitItem(Icons.verified_rounded, "Badge Emas Profil", "Menampilkan status prestisius Anda di aplikasi.", theme),
            _buildBenefitItem(Icons.card_giftcard_rounded, "Voucher Bulanan", "Dapatkan diskon khusus member setiap awal bulan.", theme),

            const SizedBox(height: 32),

            // Tombol Aksi (Beda untuk Pro dan Reguler)
            if (isPro)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmDowngrade(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Batal Berlangganan", style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup BottomSheet dulu
                    // Arahkan ke Halaman Pembayaran
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MemberPaymentPage(onPaymentSuccess: (){})));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Upgrade ke Pro Sekarang", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget Item Manfaat di BottomSheet
  Widget _buildBenefitItem(IconData icon, String title, String desc, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: theme.primary, size: 20)
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi Konfirmasi Downgrade (Kembali ke Reguler)
  Future<void> _confirmDowngrade() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Konfirmasi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin berhenti berlangganan Pro? Semua manfaat prioritas akan hilang.", style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Ya, Berhenti", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true && user != null) {
      // Hapus status Pro di Firestore
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'memberType': '', // Mengosongkan field memberType
      });

      if (mounted) {
        Navigator.pop(context); // Tutup BottomSheet
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Anda telah kembali menjadi Member Reguler."))
        );
      }
    }
  }

  Future<void> _showEditDialog(String title, String fieldKey, String currentValue, {TextInputType keyboardType = TextInputType.text}) async {
    TextEditingController controller = TextEditingController(text: currentValue == "-" ? "" : currentValue);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConfig.currentTheme.value.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Ubah $title", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Masukkan $title baru",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ThemeConfig.currentTheme.value.primary)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _updateUserData(fieldKey, controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: ThemeConfig.currentTheme.value.primary, foregroundColor: Colors.white),
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  Future<void> _showGenderDialog(String currentGender) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConfig.currentTheme.value.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Pilih Jenis Kelamin", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("Pria", style: GoogleFonts.plusJakartaSans()),
              trailing: currentGender == "Pria" ? Icon(Icons.check_circle, color: ThemeConfig.currentTheme.value.primary) : null,
              onTap: () { _updateUserData('gender', 'Pria'); Navigator.pop(ctx); },
            ),
            const Divider(height: 1),
            ListTile(
              title: Text("Wanita", style: GoogleFonts.plusJakartaSans()),
              trailing: currentGender == "Wanita" ? Icon(Icons.check_circle, color: ThemeConfig.currentTheme.value.primary) : null,
              onTap: () { _updateUserData('gender', 'Wanita'); Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: ThemeConfig.currentTheme.value.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd MMMM yyyy').format(pickedDate);
      _updateUserData('birthdate', formattedDate);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("User ID berhasil disalin!"),
          backgroundColor: ThemeConfig.currentTheme.value.primary,
          duration: const Duration(seconds: 2),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              backgroundColor: theme.surface,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
              title: Text("Info Profil", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  Map<String, dynamic> userData = {};
                  if (snapshot.hasData && snapshot.data!.data() != null) {
                    userData = snapshot.data!.data() as Map<String, dynamic>;
                  }

                  // Data logic
                  String name = userData['name'] ?? user?.displayName ?? "Pelanggan Chupatu";
                  String username = userData['username'] ?? "";
                  String bio = userData['bio'] ?? "";
                  String phone = userData['phone'] ?? "";
                  String gender = userData['gender'] ?? "";
                  String birthdate = userData['birthdate'] ?? "";

                  // CEK STATUS PRO
                  // Jika memberType == 'Pro', maka isPro = true
                  bool isPro = (userData['memberType'] == 'Pro');

                  String? photoUrl = user?.photoURL;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- FOTO PROFIL ---
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.primary.withOpacity(0.1),
                                  border: Border.all(color: theme.primary, width: 2),
                                  image: photoUrl != null ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                                ),
                                child: photoUrl == null ? Icon(Icons.person_rounded, size: 50, color: theme.primary) : null,
                              ),
                              const SizedBox(height: 12),
                              Text("Ubah Foto Profil", style: GoogleFonts.plusJakartaSans(color: theme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- BANNER STATUS MEMBER INTERAKTIF ---
                        GestureDetector(
                          onTap: () => _showMemberStatusDetails(isPro, theme), // Klik untuk buka detail
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 32),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              // Jika Pro: Gradient Emas. Jika Reguler: Abu-abu solid/gradient halus
                              gradient: isPro
                                  ? const LinearGradient(
                                colors: [Color(0xFFFDB931), Color(0xFFECAA05)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : LinearGradient(
                                colors: [theme.surface, theme.surface], // Atau warna abu-abu
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              color: isPro ? null : Colors.grey.shade200, // Fallback color
                              borderRadius: BorderRadius.circular(20),
                              border: isPro ? null : Border.all(color: Colors.grey.shade300), // Border untuk reguler
                              boxShadow: [
                                BoxShadow(
                                    color: (isPro ? const Color(0xFFECAA05) : Colors.black).withOpacity(isPro ? 0.3 : 0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8)
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                // Ikon Mahkota (Pro) atau Orang (Reguler)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: isPro ? Colors.white24 : Colors.grey.shade300,
                                      shape: BoxShape.circle
                                  ),
                                  child: Icon(
                                      isPro ? Icons.workspace_premium_rounded : Icons.person_outline_rounded,
                                      color: isPro ? Colors.white : Colors.grey.shade600,
                                      size: 30
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          isPro ? "Chupatu Pro Member" : "Member Reguler",
                                          style: GoogleFonts.plusJakartaSans(
                                              color: isPro ? Colors.white : theme.textMain,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16
                                          )
                                      ),
                                      Text(
                                          isPro ? "Status akun Anda aktif selamanya" : "Ketuk untuk melihat penawaran Pro",
                                          style: GoogleFonts.plusJakartaSans(
                                              color: isPro ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
                                              fontSize: 12
                                          )
                                      ),
                                    ],
                                  ),
                                ),
                                // Panah Indikator (Chevron)
                                Icon(
                                    Icons.chevron_right_rounded,
                                    color: isPro ? Colors.white70 : Colors.grey.shade400,
                                    size: 24
                                ),
                              ],
                            ),
                          ),
                        ),

                        // --- INFO PROFIL ---
                        Text("Info Profil", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textMain)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _cardDecoration(theme),
                          child: Column(
                            children: [
                              _buildInfoRow("Nama", name, theme, onTap: () => _showEditDialog("Nama", "name", name)),
                              const Divider(height: 24),
                              _buildInfoRow("Username", username.isEmpty ? "Buat username yang unik" : username, theme, isPlaceholder: username.isEmpty, onTap: () => _showEditDialog("Username", "username", username)),
                              const Divider(height: 24),
                              _buildInfoRow("Bio", bio.isEmpty ? "Tulis bio tentangmu" : bio, theme, isPlaceholder: bio.isEmpty, onTap: () => _showEditDialog("Bio", "bio", bio)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- INFO PRIBADI ---
                        Text("Info Pribadi", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textMain)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _cardDecoration(theme),
                          child: Column(
                            children: [
                              _buildInfoRow("User ID", user?.uid.substring(0, 10).toUpperCase() ?? "-", theme, isCopyable: true, onTap: () => _copyToClipboard(user?.uid ?? "")),
                              const Divider(height: 24),
                              _buildInfoRow("E-mail", user?.email ?? "Belum ada email", theme, showArrow: false),
                              const Divider(height: 24),
                              _buildInfoRow("Nomor HP", phone.isEmpty ? "+62 8xx xxxx xxxx" : phone, theme, isPlaceholder: phone.isEmpty, onTap: () => _showEditDialog("Nomor HP", "phone", phone, keyboardType: TextInputType.phone)),
                              const Divider(height: 24),
                              _buildInfoRow("Jenis Kelamin", gender.isEmpty ? "Pilih jenis kelamin" : gender, theme, isPlaceholder: gender.isEmpty, onTap: () => _showGenderDialog(gender)),
                              const Divider(height: 24),
                              _buildInfoRow("Tanggal Lahir", birthdate.isEmpty ? "Atur tanggal lahir" : birthdate, theme, isPlaceholder: birthdate.isEmpty, onTap: () => _showDatePicker()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                }
            ),
          );
        }
    );
  }

  BoxDecoration _cardDecoration(AppThemeData theme) {
    return BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]);
  }

  Widget _buildInfoRow(String title, String value, AppThemeData theme, {bool isPlaceholder = false, bool isCopyable = false, bool showArrow = true, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 100, child: Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 14))),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(color: isPlaceholder ? Colors.grey.shade400 : theme.textMain, fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w600, fontSize: 14),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCopyable) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.copy_rounded, size: 16, color: theme.primary),
                  ] else if (showArrow) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}