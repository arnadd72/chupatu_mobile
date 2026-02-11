import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fitur Copy to Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal lahir
import 'package:chupatu_mobile/main.dart';

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
      // SetOptions(merge: true) agar tidak menimpa data lain yang sudah ada
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        field: value,
      }, SetOptions(merge: true));

      // Khusus untuk Nama, kita update juga di Firebase Auth
      if (field == 'name') {
        await user!.updateDisplayName(value);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- MUNCULKAN POP-UP KETIK TEKS (Nama, Username, Bio, No HP) ---
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

  // --- MUNCULKAN POP-UP PILIH JENIS KELAMIN ---
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

  // --- MUNCULKAN KALENDER TANGGAL LAHIR ---
  Future<void> _showDatePicker() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), // Default mulai dari tahun 2000
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

  // --- FUNGSI COPY USER ID ---
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
            // MENGGUNAKAN STREAM BUILDER AGAR DATA REAL-TIME
            body: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Tarik data dari Firestore, jika kosong pakai default
                  Map<String, dynamic> userData = {};
                  if (snapshot.hasData && snapshot.data!.data() != null) {
                    userData = snapshot.data!.data() as Map<String, dynamic>;
                  }

                  String name = userData['name'] ?? user?.displayName ?? "Pelanggan Chupatu";
                  String username = userData['username'] ?? "";
                  String bio = userData['bio'] ?? "";
                  String phone = userData['phone'] ?? "";
                  String gender = userData['gender'] ?? "";
                  String birthdate = userData['birthdate'] ?? "";

                  // Cek Foto dari Google
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
                                  // JIKA ADA FOTO DARI GOOGLE, TAMPILKAN!
                                  image: photoUrl != null ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                                ),
                                // Jika tidak ada foto, tampilkan ikon orang
                                child: photoUrl == null ? Icon(Icons.person_rounded, size: 50, color: theme.primary) : null,
                              ),
                              const SizedBox(height: 12),
                              Text("Ubah Foto Profil", style: GoogleFonts.plusJakartaSans(color: theme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

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
                              // USER ID (Copyable)
                              _buildInfoRow("User ID", user?.uid.substring(0, 10).toUpperCase() ?? "-", theme, isCopyable: true, onTap: () => _copyToClipboard(user?.uid ?? "")),
                              const Divider(height: 24),

                              // EMAIL (Tidak bisa diubah dari sini)
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

  // --- WIDGET ROW YANG BISA DI-KLIK ---
  Widget _buildInfoRow(String title, String value, AppThemeData theme, {bool isPlaceholder = false, bool isCopyable = false, bool showArrow = true, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap, // Menambahkan fungsi klik
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4), // Ruang sentuh agar lebih enak diklik
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