import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:chupatu_mobile/main.dart';
// IMPORT HALAMAN CHUPATU PRO BARU
import 'package:chupatu_mobile/pages/profile/chupatu_pro_page.dart';

class ApiConfig {
  static const String baseUrl =
      'https://malik-pseudomonocyclic-misti.ngrok-free.dev/api';
  static const String uploadUrl = '$baseUrl/upload';

  static const Map<String, String> ngrokHeaders = {
    'ngrok-skip-browser-warning': 'true',
    'User-Agent': 'ChupatuApp'
  };
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUpdatingPhoto = false;
  File? _localImageFile;

  // --- FUNGSI UPDATE FOTO PROFIL KE LARAVEL & FIREBASE ---
  Future<void> _updateProfilePicture() async {
    final freshUser = FirebaseAuth.instance.currentUser;
    if (freshUser == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 50);

    if (image == null) return;

    setState(() {
      _localImageFile = File(image.path);
      _isUpdatingPhoto = true;
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse(ApiConfig.uploadUrl));

      request.headers.addAll({'Accept': 'application/json'});
      request.files.add(await http.MultipartFile.fromPath('foto', image.path));
      request.fields['kategori'] = 'profil';

      var response = await request.send();

      if (response.statusCode == 200) {
        var resData = await response.stream.bytesToString();
        var jsonRes = json.decode(resData);

        String baseUploadUrl = jsonRes['url'].toString().replaceAll("http://", "https://");
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String newUrl = "$baseUploadUrl?v=$timestamp";

        await FirebaseFirestore.instance.collection('users')
            .doc(freshUser.uid).set({
          'photoUrl': newUrl,
        }, SetOptions(merge: true));

        await freshUser.updatePhotoURL(newUrl);
        await freshUser.reload();

        if (mounted) {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();

          setState(() {
            _localImageFile = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Foto Profil Berhasil Diperbarui! ✨"),
                  backgroundColor: Colors.green));
        }
      } else {
        throw "Gagal upload. Status: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("Error Ganti Profil: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPhoto = false);
    }
  }

  // --- FUNGSI UPDATE DATA TEKS ---
  Future<void> _updateUserData(String field, String value) async {
    final freshUser = FirebaseAuth.instance.currentUser;
    if (freshUser == null) return;
    try {
      await FirebaseFirestore.instance.collection('users')
          .doc(freshUser.uid).set({
        field: value,
      }, SetOptions(merge: true));

      if (field == 'name') {
        await freshUser.updateDisplayName(value);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // ==========================================================
  // FITUR MANAJEMEN ALAMAT
  // ==========================================================
  void _showAddressManager(AppThemeData theme, List<dynamic> addresses) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, controller) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Daftar Alamat", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAddAddressDialog(theme, addresses);
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Tambah"),
                          style: TextButton.styleFrom(foregroundColor: theme.primary),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
                          builder: (ctx, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                            var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                            List<dynamic> currentAddrs = userData['addresses'] ?? [];

                            if (currentAddrs.isEmpty) {
                              return Center(
                                  child: Text("Belum ada alamat tersimpan.", style: GoogleFonts.plusJakartaSans(color: Colors.grey))
                              );
                            }

                            return ListView.separated(
                              controller: controller,
                              itemCount: currentAddrs.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 12),
                              itemBuilder: (c, i) {
                                var addr = currentAddrs[i] as Map<String, dynamic>;
                                bool isPrimary = addr['isPrimary'] == true;

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      color: theme.background,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isPrimary ? theme.primary : Colors.grey.withOpacity(0.2), width: isPrimary ? 2 : 1)
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(isPrimary ? Icons.location_on : Icons.location_on_outlined, color: isPrimary ? theme.primary : Colors.grey),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(addr['label'] ?? 'Alamat', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                                                if (isPrimary) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                                    child: Text("Utama", style: TextStyle(color: theme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  )
                                                ]
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(addr['detail'] ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                                        onSelected: (val) async {
                                          if (val == 'primary') {
                                            await _setPrimaryAddress(currentAddrs, addr['id'], addr['detail']);
                                          } else if (val == 'delete') {
                                            await _deleteAddress(currentAddrs, addr['id']);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          if (!isPrimary)
                                            const PopupMenuItem(value: 'primary', child: Text("Jadikan Utama")),
                                          const PopupMenuItem(value: 'delete', child: Text("Hapus Alamat", style: TextStyle(color: Colors.red))),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                      ),
                    )
                  ],
                ),
              );
            },
          );
        }
    );
  }

  Future<void> _showAddAddressDialog(AppThemeData theme, List<dynamic> currentAddresses) async {
    TextEditingController labelCtrl = TextEditingController();
    TextEditingController detailCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Tambah Alamat", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              style: TextStyle(color: theme.textMain),
              decoration: InputDecoration(
                labelText: "Label (ex: Rumah, Kantor)",
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary), borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailCtrl,
              maxLines: 3,
              style: TextStyle(color: theme.textMain),
              decoration: InputDecoration(
                labelText: "Alamat Lengkap",
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary), borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (labelCtrl.text.isEmpty || detailCtrl.text.isEmpty) return;

              String newId = DateTime.now().millisecondsSinceEpoch.toString();
              bool isFirst = currentAddresses.isEmpty;

              var newAddress = {
                'id': newId,
                'label': labelCtrl.text.trim(),
                'detail': detailCtrl.text.trim(),
                'isPrimary': isFirst,
              };

              List<dynamic> updatedList = List.from(currentAddresses)..add(newAddress);
              Map<String, dynamic> payload = {'addresses': updatedList};

              if (isFirst) payload['address'] = detailCtrl.text.trim();

              await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update(payload);
              if (mounted) {
                Navigator.pop(ctx);
                _showAddressManager(theme, updatedList);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _setPrimaryAddress(List<dynamic> addresses, String targetId, String fullAddress) async {
    final freshUser = FirebaseAuth.instance.currentUser;
    if (freshUser == null) return;

    List<dynamic> updatedList = addresses.map((a) {
      var newAddr = Map<String, dynamic>.from(a);
      newAddr['isPrimary'] = (newAddr['id'] == targetId);
      return newAddr;
    }).toList();

    await FirebaseFirestore.instance.collection('users').doc(freshUser.uid).update({
      'addresses': updatedList,
      'address': fullAddress,
    });
  }

  Future<void> _deleteAddress(List<dynamic> addresses, String targetId) async {
    final freshUser = FirebaseAuth.instance.currentUser;
    if (freshUser == null) return;

    List<dynamic> updatedList = addresses.where((a) => a['id'] != targetId).toList();
    String newMainAddress = "";

    if (updatedList.isNotEmpty) {
      bool hasPrimary = updatedList.any((a) => a['isPrimary'] == true);
      if (!hasPrimary) {
        updatedList[0]['isPrimary'] = true;
        newMainAddress = updatedList[0]['detail'];
      } else {
        newMainAddress = updatedList.firstWhere((a) => a['isPrimary'] == true)['detail'];
      }
    }

    await FirebaseFirestore.instance.collection('users').doc(freshUser.uid).update({
      'addresses': updatedList,
      'address': newMainAddress.isNotEmpty ? newMainAddress : FieldValue.delete(),
    });
  }

  // --- DIALOG EDIT PROFIL ---
  Future<void> _showEditDialog(String title, String fieldKey, String currentValue,
      {TextInputType keyboardType = TextInputType.text}) async {
    TextEditingController controller = TextEditingController(text: currentValue == "-" ? "" : currentValue);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConfig.currentTheme.value.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Ubah $title", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: true,
          decoration: InputDecoration(border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) _updateUserData(fieldKey, controller.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: ThemeConfig.currentTheme.value.primary),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
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
        title: const Text("Pilih Jenis Kelamin"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text("Pria"),
                onTap: () { _updateUserData('gender', 'Pria'); Navigator.pop(ctx); }),
            const Divider(),
            ListTile(title: const Text("Wanita"),
                onTap: () { _updateUserData('gender', 'Wanita'); Navigator.pop(ctx); }),
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
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('dd MMMM yyyy').format(pickedDate);
      _updateUserData('birthdate', formattedDate);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID Disalin!")));
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
              title: Text("Info Profil",
                  style: GoogleFonts.plusJakartaSans(color: theme.textMain,
                      fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(freshUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  Map<String, dynamic> userData = {};
                  if (snapshot.hasData && snapshot.data!.data() != null) {
                    userData = snapshot.data!.data() as Map<String, dynamic>;
                  }

                  String name = userData['name'] ?? freshUser?.displayName ?? "Pelanggan";
                  String username = userData['username'] ?? "";
                  String bio = userData['bio'] ?? "";
                  String phone = userData['phone'] ?? "";
                  String gender = userData['gender'] ?? "";
                  String birthdate = userData['birthdate'] ?? "";
                  bool isPro = (userData['memberType'] == 'Pro');

                  List<dynamic> addressList = userData['addresses'] ?? [];
                  String displayAddress = "Atur Alamat";
                  if (addressList.isNotEmpty) {
                    var primaryAddress = addressList.firstWhere((addr) => addr['isPrimary'] == true, orElse: () => addressList.first);
                    displayAddress = primaryAddress['label'] ?? 'Alamat Utama';
                  } else if (userData['address'] != null && userData['address'].toString().isNotEmpty) {
                    displayAddress = "Lihat Alamat (Legacy)";
                  }

                  String? photoUrl;
                  if (userData['photoUrl'] != null && userData['photoUrl'] != "") {
                    photoUrl = userData['photoUrl'];
                  } else {
                    photoUrl = freshUser?.photoURL;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- FOTO PROFIL ---
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _isUpdatingPhoto ? null : _updateProfilePicture,
                                child: Container(
                                  key: ValueKey(photoUrl),
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.primary.withOpacity(0.1),
                                    border: Border.all(color: theme.primary, width: 2),
                                    image: _localImageFile != null
                                        ? DecorationImage(
                                        image: FileImage(_localImageFile!),
                                        fit: BoxFit.cover)
                                        : (photoUrl != null
                                        ? DecorationImage(
                                        image: NetworkImage(
                                            photoUrl.replaceAll("http://", "https://"),
                                            headers: ApiConfig.ngrokHeaders
                                        ),
                                        fit: BoxFit.cover)
                                        : null),
                                  ),
                                  child: _isUpdatingPhoto
                                      ? Center(child: CircularProgressIndicator(
                                      strokeWidth: 3, color: theme.primary))
                                      : (_localImageFile == null && photoUrl == null
                                      ? Icon(Icons.person, size: 50, color: theme.primary)
                                      : null),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _isUpdatingPhoto ? null : _updateProfilePicture,
                                child: Text(
                                    _isUpdatingPhoto ? "Mengunggah..." : "Ubah Foto Profil",
                                    style: GoogleFonts.plusJakartaSans(
                                        color: theme.primary,
                                        fontWeight: FontWeight.bold, fontSize: 14)
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- BANNER STATUS MEMBER (DIARAHKAN KE HALAMAN BARU) ---
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ChupatuProPage())
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 32),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isPro
                                  ? const LinearGradient(colors: [Color(0xFFFDB931), Color(0xFFECAA05)])
                                  : LinearGradient(colors: [theme.surface, theme.surface]),
                              color: isPro ? null : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                              border: isPro ? null : Border.all(color: Colors.grey.shade300),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: isPro ? Colors.white24 : Colors.grey.shade300,
                                      shape: BoxShape.circle),
                                  child: Icon(isPro ? Icons.workspace_premium : Icons.person_outline,
                                      color: isPro ? Colors.white : Colors.grey, size: 30),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isPro ? "Chupatu Pro Member" : "Member Reguler",
                                          style: GoogleFonts.plusJakartaSans(
                                              color: isPro ? Colors.white : theme.textMain,
                                              fontWeight: FontWeight.w800, fontSize: 16)),
                                      Text(isPro ? "Status aktif selamanya" : "Ketuk untuk info selengkapnya",
                                          style: GoogleFonts.plusJakartaSans(
                                              color: isPro ? Colors.white70 : Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: isPro ? Colors.white70 : Colors.grey),
                              ],
                            ),
                          ),
                        ),

                        Text("Info Profil", style: GoogleFonts.plusJakartaSans(fontSize: 18,
                            fontWeight: FontWeight.w800, color: theme.textMain)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _cardDecoration(theme),
                          child: Column(
                            children: [
                              _buildInfoRow("Nama", name, theme,
                                  onTap: () => _showEditDialog("Nama", "name", name)),
                              const Divider(height: 24),
                              _buildInfoRow("Username", username.isEmpty ? "Buat username" : username,
                                  theme, onTap: () => _showEditDialog("Username", "username", username)),
                              const Divider(height: 24),
                              _buildInfoRow("Bio", bio.isEmpty ? "Tulis bio" : bio,
                                  theme, onTap: () => _showEditDialog("Bio", "bio", bio)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        Text("Info Pribadi", style: GoogleFonts.plusJakartaSans(fontSize: 18,
                            fontWeight: FontWeight.w800, color: theme.textMain)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _cardDecoration(theme),
                          child: Column(
                            children: [
                              _buildInfoRow("User ID", freshUser?.uid.substring(0, 10).toUpperCase() ?? "-",
                                  theme, isCopyable: true, onTap: () => _copyToClipboard(freshUser?.uid ?? "")),
                              const Divider(height: 24),
                              _buildInfoRow("E-mail", freshUser?.email ?? "Email kosong", theme, showArrow: false),
                              const Divider(height: 24),
                              _buildInfoRow("Nomor HP", phone.isEmpty ? "+62 8xx" : phone,
                                  theme, onTap: () => _showEditDialog("Nomor HP", "phone", phone,
                                      keyboardType: TextInputType.phone)),

                              const Divider(height: 24),
                              _buildInfoRow("Alamat", displayAddress, theme,
                                  onTap: () => _showAddressManager(theme, addressList)),

                              const Divider(height: 24),
                              _buildInfoRow("Jenis Kelamin", gender.isEmpty ? "Pilih" : gender,
                                  theme, onTap: () => _showGenderDialog(gender)),
                              const Divider(height: 24),
                              _buildInfoRow("Tanggal Lahir", birthdate.isEmpty ? "Atur" : birthdate,
                                  theme, onTap: () => _showDatePicker()),
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
    return BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]);
  }

  Widget _buildInfoRow(String title, String value, AppThemeData theme,
      {bool isPlaceholder = false, bool isCopyable = false, bool showArrow = true,
        VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 100, child: Text(title, style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade600, fontSize: 14))),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(child: Text(value, style: GoogleFonts.plusJakartaSans(
                      color: theme.textMain, fontWeight: FontWeight.w600, fontSize: 14),
                      textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Icon(isCopyable ? Icons.copy : (showArrow ? Icons.chevron_right : null),
                      size: 18, color: Colors.grey.shade400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}