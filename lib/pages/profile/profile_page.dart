import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

// --- PENTING: IMPORT MAIN.DART (Karena AppThemeData & ThemeConfig ada di sana) ---
import 'package:chupatu_mobile/main.dart'; 

// Import halaman lain
import 'package:chupatu_mobile/pages/auth/login_page.dart';
import 'package:chupatu_mobile/pages/profile/member_payment_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- INSTANCE FIREBASE ---
  final User? user = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // --- DATA WILAYAH INDONESIA LENGKAP (FOKUS JAWA) ---
  final Map<String, List<String>> _indonesiaData = {
    // 1. DKI JAKARTA
    'DKI Jakarta': [
      'Jakarta Selatan', 'Jakarta Pusat', 'Jakarta Barat', 'Jakarta Timur', 'Jakarta Utara', 'Kepulauan Seribu'
    ],
    
    // 2. JAWA BARAT
    'Jawa Barat': [
      'Bandung', 'Bandung Barat', 'Kab. Bandung', 'Cimahi', 
      'Bogor', 'Kab. Bogor', 'Depok', 
      'Bekasi', 'Kab. Bekasi', 'Cikarang',
      'Sukabumi', 'Cianjur', 'Tasikmalaya', 'Ciamis', 'Garut',
      'Cirebon', 'Indramayu', 'Majalengka', 'Kuningan',
      'Karawang', 'Purwakarta', 'Subang', 'Sumedang'
    ],

    // 3. BANTEN
    'Banten': [
      'Tangerang', 'Tangerang Selatan', 'Kab. Tangerang', 
      'Serang', 'Cilegon', 'Pandeglang', 'Lebak'
    ],

    // 4. JAWA TENGAH
    'Jawa Tengah': [
      'Semarang', 'Kab. Semarang', 'Salatiga', 'Kendal', 'Demak', 'Grobogan',
      'Solo (Surakarta)', 'Sukoharjo', 'Boyolali', 'Klaten', 'Wonogiri', 'Sragen', 'Karanganyar',
      'Magelang', 'Temanggung', 'Wonosobo', 'Purworejo', 'Kebumen',
      'Banyumas (Purwokerto)', 'Cilacap', 'Purbalingga', 'Banjarnegara',
      'Tegal', 'Brebes', 'Pekalongan', 'Pemalang', 'Batang',
      'Kudus', 'Jepara', 'Pati', 'Rembang', 'Blora'
    ],

    // 5. DI YOGYAKARTA
    'DI Yogyakarta': [
      'Yogyakarta', 'Sleman', 'Bantul', 'Kulon Progo', 'Gunung Kidul'
    ],

    // 6. JAWA TIMUR
    'Jawa Timur': [
      'Surabaya', 'Sidoarjo', 'Gresik', 
      'Malang', 'Batu', 'Kab. Malang', 'Pasuruan', 'Probolinggo',
      'Kediri', 'Blitar', 'Tulungagung', 'Trenggalek', 'Nganjuk',
      'Madiun', 'Ponorogo', 'Ngawi', 'Magetan', 'Pacitan',
      'Mojokerto', 'Jombang', 'Bojonegoro', 'Tuban', 'Lamongan',
      'Banyuwangi', 'Jember', 'Bondowoso', 'Situbondo', 'Lumajang',
      'Madura (Bangkalan)', 'Madura (Sampang)', 'Madura (Pamekasan)', 'Madura (Sumenep)'
    ],

    // 7. BALI & LAINNYA (Opsional)
    'Bali': ['Denpasar', 'Badung', 'Gianyar', 'Tabanan', 'Buleleng'],
    'Sumatera Utara': ['Medan', 'Binjai', 'Deli Serdang'],
    'Sulawesi Selatan': ['Makassar', 'Gowa', 'Maros'],
  };

  // --- DATA KECAMATAN (KOTA-KOTA BESAR DI JAWA) ---
  final Map<String, List<String>> _kecamatanData = {
    // --- JAWA BARAT ---
    'Bandung': ['Andir', 'Astana Anyar', 'Antapani', 'Arcamanik', 'Babakan Ciparay', 'Bandung Kidul', 'Bandung Kulon', 'Bandung Wetan', 'Batununggal', 'Bojongloa Kaler', 'Bojongloa Kidul', 'Buahbatu', 'Cibeunying Kaler', 'Cibeunying Kidul', 'Cibiru', 'Cicendo', 'Cidadap', 'Cinambo', 'Coblong', 'Gedebage', 'Kiaracondong', 'Lengkong', 'Mandalajati', 'Panyileukan', 'Rancasari', 'Regol', 'Sukajadi', 'Sukasari', 'Sumur Bandung', 'Ujung Berung'],
    'Kab. Bandung': ['Bojongsoang', 'Dayeuhkolot', 'Baleendah', 'Cileunyi', 'Rancaekek', 'Soreang', 'Ciwidey', 'Pangalengan', 'Ciparay', 'Majalaya', 'Margahayu', 'Katapang'],
    'Bandung Barat': ['Padalarang', 'Lembang', 'Ngamprah', 'Parongpong', 'Cisarua', 'Cikalong Wetan', 'Cipeundeuy'],
    'Cimahi': ['Cimahi Selatan', 'Cimahi Tengah', 'Cimahi Utara'],
    'Bogor': ['Bogor Barat', 'Bogor Selatan', 'Bogor Tengah', 'Bogor Timur', 'Bogor Utara', 'Tanah Sareal'],
    'Depok': ['Beji', 'Bojongsari', 'Cilodong', 'Cimanggis', 'Cinere', 'Cipayung', 'Limo', 'Pancoran Mas', 'Sawangan', 'Sukmajaya', 'Tapos'],
    'Bekasi': ['Bantar Gebang', 'Bekasi Barat', 'Bekasi Selatan', 'Bekasi Timur', 'Bekasi Utara', 'Jatiasih', 'Jatisampurna', 'Medan Satria', 'Mustika Jaya', 'Pondok Gede', 'Pondok Melati', 'Rawalumbu'],
    'Cikarang': ['Cikarang Pusat', 'Cikarang Barat', 'Cikarang Timur', 'Cikarang Utara', 'Cikarang Selatan'],
    'Karawang': ['Karawang Barat', 'Karawang Timur', 'Telukjambe', 'Klari', 'Cikampek', 'Rengasdengklok'],

    // --- DKI JAKARTA ---
    'Jakarta Selatan': ['Cilandak', 'Jagakarsa', 'Kebayoran Baru', 'Kebayoran Lama', 'Mampang Prapatan', 'Pancoran', 'Pasar Minggu', 'Pesanggrahan', 'Setiabudi', 'Tebet'],
    'Jakarta Pusat': ['Cempaka Putih', 'Gambir', 'Johar Baru', 'Kemayoran', 'Menteng', 'Sawah Besar', 'Senen', 'Tanah Abang'],
    'Jakarta Barat': ['Cengkareng', 'Grogol Petamburan', 'Taman Sari', 'Tambora', 'Kebon Jeruk', 'Kalideres', 'Palmerah', 'Kembangan'],
    'Jakarta Timur': ['Cakung', 'Cipayung', 'Ciracas', 'Duren Sawit', 'Jatinegara', 'Kramat Jati', 'Makasar', 'Matraman', 'Pasar Rebo', 'Pulo Gadung'],
    'Jakarta Utara': ['Cilincing', 'Kelapa Gading', 'Koja', 'Pademangan', 'Penjaringan', 'Tanjung Priok'],

    // --- BANTEN ---
    'Tangerang Selatan': ['Serpong', 'Serpong Utara', 'Ciputat', 'Ciputat Timur', 'Pondok Aren', 'Pamulang', 'Setu'],
    'Tangerang': ['Tangerang', 'Cibodas', 'Ciledug', 'Cipondoh', 'Jatiuwung', 'Karang Tengah', 'Karawaci', 'Larangan', 'Neglasari', 'Periuk', 'Pinang'],

    // --- JAWA TENGAH ---
    'Semarang': ['Banyumanik', 'Candisari', 'Gajahmungkur', 'Gayamsari', 'Genuk', 'Gunungpati', 'Mijen', 'Ngaliyan', 'Pedurungan', 'Semarang Barat', 'Semarang Selatan', 'Semarang Tengah', 'Semarang Timur', 'Semarang Utara', 'Tembalang', 'Tugu'],
    'Solo (Surakarta)': ['Banjarsari', 'Jebres', 'Laweyan', 'Pasar Kliwon', 'Serengan'],
    'Magelang': ['Magelang Selatan', 'Magelang Tengah', 'Magelang Utara'],
    'Tegal': ['Margadana', 'Tegal Barat', 'Tegal Selatan', 'Tegal Timur'],
    'Banyumas (Purwokerto)': ['Purwokerto Barat', 'Purwokerto Selatan', 'Purwokerto Timur', 'Purwokerto Utara', 'Baturraden', 'Sokaraja'],

    // --- DI YOGYAKARTA ---
    'Yogyakarta': ['Danurejan (Malioboro)', 'Gedongtengen', 'Gondokusuman', 'Gondomanan', 'Jetis', 'Kotagede', 'Kraton', 'Mantrijeron', 'Mergangsan', 'Ngampilan', 'Pakualaman', 'Tegalrejo', 'Umbulharjo', 'Wirobrajan'],
    'Sleman': ['Depok', 'Gamping', 'Godean', 'Kalasan', 'Mlati', 'Ngaglik', 'Prambanan', 'Seyegan', 'Sleman', 'Tempel'],
    'Bantul': ['Banguntapan', 'Bantul', 'Kasihan', 'Sewon', 'Imogiri', 'Parangtritis'],

    // --- JAWA TIMUR ---
    'Surabaya': ['Tegalsari', 'Simokerto', 'Genteng', 'Bubutan', 'Gubeng', 'Gunung Anyar', 'Sukolilo', 'Tambaksari', 'Mulyorejo', 'Rungkut', 'Tenggilis Mejoyo', 'Benowo', 'Pakal', 'Asemrowo', 'Sukomanunggal', 'Tandes', 'Sambikerep', 'Lakarsantri', 'Bulak', 'Kenjeran', 'Semampir', 'Pabean Cantian', 'Krembangan', 'Wonokromo', 'Wonocolo', 'Wiyung', 'Karang Pilang', 'Jambangan', 'Gayungan', 'Dukuh Pakis', 'Sawahan'],
    'Malang': ['Blimbing', 'Kedungkandang', 'Klojen', 'Lowokwaru', 'Sukun'],
    'Kab. Malang': ['Singosari', 'Lawang', 'Kepanjen', 'Pakis', 'Dau', 'Karangploso'],
    'Sidoarjo': ['Sidoarjo', 'Waru', 'Gedangan', 'Buduran', 'Candi', 'Taman', 'Sedati', 'Sukodono'],
    'Gresik': ['Gresik', 'Kebomas', 'Manyar', 'Driyorejo', 'Menganti'],
    'Kediri': ['Kediri', 'Mojoroto', 'Pesantren'],
  }; 
  
  // --- STATE VARIABLE ---
  String _name = "Loading...";
  String _photoUrl = "https://i.pravatar.cc/150";
  String _email = "Loading...";
  String _phone = "-";
  String _address = "-";
  String _gender = "-";
  String _dob = "-";
  String _memberType = "Regular";
  String _memberId = "ID-000000";
  
  bool _isUploading = false; 

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- 1. FETCH DATA ---
  Future<void> _fetchUserData() async {
    if (user == null) return;
    await user?.reload(); 
    final updatedUser = FirebaseAuth.instance.currentUser;
    
    setState(() {
      _name = updatedUser?.displayName ?? "Pengguna Baru";
      _email = updatedUser?.email ?? "-";
      _photoUrl = updatedUser?.photoURL ?? "https://i.pravatar.cc/150";
      _memberId = "MEM-${updatedUser!.uid.substring(0, 5).toUpperCase()}";
    });

    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(updatedUser!.uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _phone = data['phone'] ?? "-";
          _address = data['address'] ?? "-";
          _gender = data['gender'] ?? "-";
          _dob = data['dob'] ?? "-";
          _memberType = data['memberType'] ?? "Regular";
        });
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  // --- 2. SAVE DATA ---
  Future<void> _saveFirestoreData(String field, String value) async {
    if (user == null) return;
    setState(() {
      if (field == 'gender') _gender = value;
      if (field == 'dob') _dob = value;
      if (field == 'phone') _phone = value;
      if (field == 'address') _address = value;
      if (field == 'memberType') _memberType = value;
    });
    await _firestore.collection('users').doc(user!.uid).set({ field: value }, SetOptions(merge: true));
  }

  // --- 3. UPDATE AUTH (NAMA & FOTO) ---
  Future<void> _updateAuthProfile({String? newName, String? newPhotoUrl}) async {
    if (user == null) return;
    try {
      if (newName != null) {
        await user!.updateDisplayName(newName);
        await _firestore.collection('users').doc(user!.uid).set({'displayName': newName}, SetOptions(merge: true));
      }
      if (newPhotoUrl != null) {
        await user!.updatePhotoURL(newPhotoUrl);
        await _firestore.collection('users').doc(user!.uid).set({'photoUrl': newPhotoUrl}, SetOptions(merge: true));
      }
      await _fetchUserData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil diperbarui!"), backgroundColor: Colors.green));
    } catch (e) { debugPrint("Error update: $e"); }
  }

  // --- 4. UPLOAD FOTO ---
  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        setState(() => _isUploading = true);
        String fileName = "profile_${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg";
        final storageRef = _storage.ref().child('profile_images').child(fileName);
        await storageRef.putFile(File(image.path));
        String downloadUrl = await storageRef.getDownloadURL();
        await _updateAuthProfile(newPhotoUrl: downloadUrl);
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal upload: $e"), backgroundColor: Colors.red));
    }
  }

  // --- 5. LOGOUT ---
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FITUR ALAMAT: CASCADING DROPDOWN (PROVINSI -> KOTA -> KEC)
  // ============================================================
  void _editAddress(BuildContext context, AppThemeData theme) {
    // Parsing Alamat Lama
    String currentStreet = "";
    String? currentProv;
    String? currentCity;
    String? currentDist;

    List<String> parts = _address.split(', ');
    if (parts.length >= 4) {
      currentProv = parts.last;
      currentCity = parts[parts.length - 2];
      currentDist = parts[parts.length - 3].replaceAll("Kec. ", "");
      currentStreet = parts.sublist(0, parts.length - 3).join(", ");
    } else { 
      currentStreet = _address == "-" ? "" : _address; 
    }

    final streetController = TextEditingController(text: currentStreet);
    
    // Inisialisasi State Dropdown
    String? selectedProv = _indonesiaData.containsKey(currentProv) ? currentProv : null;
    String? selectedCity = selectedProv != null && (_indonesiaData[selectedProv]?.contains(currentCity) ?? false) ? currentCity : null;
    String? selectedDist = selectedCity != null && (_kecamatanData[selectedCity]?.contains(currentDist) ?? false) ? currentDist : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: theme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Ubah Alamat", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                    IconButton(icon: Icon(Icons.close, color: theme.textMain), onPressed: () => Navigator.pop(context))
                  ]),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildLabel("Provinsi"),
                        _buildDropdown(theme, selectedProv, "Pilih Provinsi", _indonesiaData.keys.toList(), (val) { 
                          setModalState(() { selectedProv = val; selectedCity = null; selectedDist = null; }); 
                        }),
                        const SizedBox(height: 16),
                        
                        _buildLabel("Kota / Kabupaten"),
                        _buildDropdown(theme, selectedCity, "Pilih Kota", selectedProv != null ? _indonesiaData[selectedProv]! : [], (val) { 
                          setModalState(() { selectedCity = val; selectedDist = null; }); 
                        }),
                        const SizedBox(height: 16),

                        _buildLabel("Kecamatan"),
                        _buildDropdown(theme, selectedDist, "Pilih Kecamatan", selectedCity != null ? (_kecamatanData[selectedCity] ?? ['Lainnya']) : [], (val) { 
                          setModalState(() { selectedDist = val; }); 
                        }),
                        const SizedBox(height: 16),

                        _buildLabel("Detail Jalan / Gedung / No. Rumah"),
                        TextField(
                          controller: streetController, 
                          maxLines: 3, 
                          style: GoogleFonts.plusJakartaSans(color: theme.textMain), 
                          decoration: InputDecoration(hintText: "Jl. Mawar No. 12, RT 01/02", filled: true, fillColor: theme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: double.infinity, child: ElevatedButton(
                    onPressed: () {
                      if (selectedProv != null && selectedCity != null && streetController.text.isNotEmpty) {
                        String fullAddress = "${streetController.text}, Kec. ${selectedDist ?? '-'}, $selectedCity, $selectedProv";
                        _saveFirestoreData('address', fullAddress); 
                        Navigator.pop(context);
                      } else { 
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi alamat!"))); 
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Simpan Alamat"),
                  ))
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown(AppThemeData theme, String? value, String hint, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16), 
      decoration: BoxDecoration(color: theme.background, borderRadius: BorderRadius.circular(12)), 
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, 
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400)), 
          isExpanded: true, 
          dropdownColor: theme.surface, 
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: theme.textMain)))).toList(), 
          onChanged: onChanged
        )
      )
    );
  }

  // ============================================================
  // FITUR MEMBER: UPGRADE & DOWNGRADE
  // ============================================================
  void _showMemberDetail(BuildContext context, AppThemeData theme) {
    bool isPro = _memberType == "Pro";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: theme.background, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))), 
              const SizedBox(height: 20),
              
              Row(children: [Text("Status Member", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textMain)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isPro ? const Color(0xFFFFD700).withOpacity(0.2) : Colors.grey.shade200, borderRadius: BorderRadius.circular(20), border: Border.all(color: isPro ? const Color(0xFFFFD700) : Colors.grey)), child: Text(isPro ? "PRO" : "REGULAR", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: isPro ? const Color(0xFFD4AF37) : Colors.grey)))]), 
              const SizedBox(height: 20),
              
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.textMain.withOpacity(0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Benefit Kamu Saat Ini:", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)), const SizedBox(height: 10), _buildBenefitItem(Icons.check_circle, "Akses layanan dasar.", theme), _buildBenefitItem(Icons.check_circle, "Dukungan standar.", theme), if (!isPro) _buildBenefitItem(Icons.cancel, "Tidak ada gratis ongkir.", theme, isNegative: true), if (!isPro) _buildBenefitItem(Icons.cancel, "Antrian reguler.", theme, isNegative: true)])), 
              const SizedBox(height: 24),

              if (!isPro) ...[
                // --- REGULAR MEMBER (OFFER UPGRADE) ---
                Text("Upgrade ke PRO ✨", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)), 
                const SizedBox(height: 12),
                Container(
                  width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), 
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF1E1E2C).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
                  child: Column(children: [
                    Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(children: [SizedBox(width: 60, height: 60, child: Lottie.asset('assets/lottie/trophy.json', errorBuilder: (c,e,s) => const Icon(Icons.emoji_events, color: Colors.amber, size: 40))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Chupatu PRO", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), Text("Rp 49.000 / bulan", style: GoogleFonts.plusJakartaSans(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14))]))])),
                    const Divider(color: Colors.white24, height: 1), const SizedBox(height: 16), 
                    Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(children: [_buildDarkBenefitItem("Gratis Antar Jemput"), _buildDarkBenefitItem("Prioritas Pengerjaan"), _buildDarkBenefitItem("Diskon 20%")])), 
                    
                    ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)), child: Material(color: const Color(0xFFFFD700), child: InkWell(onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => MemberPaymentPage(onPaymentSuccess: () => _saveFirestoreData('memberType', 'Pro')))); }, child: Container(height: 60, alignment: Alignment.center, child: Text("UPGRADE SEKARANG", style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1))))))
                  ]),
                ),
                const SizedBox(height: 40),
              ] else ...[
                // --- PRO MEMBER (OFFER DOWNGRADE) ---
                Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green)), child: Row(children: [const Icon(Icons.verified, color: Colors.green, size: 30), const SizedBox(width: 12), Expanded(child: Text("Status PRO Anda aktif.", style: GoogleFonts.plusJakartaSans(color: Colors.green.shade800, fontWeight: FontWeight.bold)))])), 
                const SizedBox(height: 24),
                
                SizedBox(width: double.infinity, child: OutlinedButton(
                  onPressed: () { 
                    Navigator.pop(context); 
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: const Text("Batalkan Langganan?"), 
                      content: const Text("Anda akan kembali ke Regular."), 
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Kembali")), 
                        ElevatedButton(onPressed: () { _saveFirestoreData('memberType', 'Regular'); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paket dibatalkan."))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Batalkan"))
                      ]
                    )); 
                  }, 
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.red.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                  child: Text("Berhenti Langganan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.red)))), 
                const SizedBox(height: 40),
              ]
            ]
          )
        )
      )
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildBenefitItem(IconData icon, String text, AppThemeData theme, {bool isNegative = false}) { return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(children: [Icon(icon, size: 18, color: isNegative ? Colors.red : Colors.green), const SizedBox(width: 8), Text(text, style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontSize: 13))])); }
  Widget _buildDarkBenefitItem(String text) { return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(children: [const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFD700)), const SizedBox(width: 10), Text(text, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))])); }
  Widget _buildLabel(String text) { return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))); }

  // --- EDIT DIALOGS ---
  void _editNameDialog(BuildContext context, AppThemeData theme) { TextEditingController controller = TextEditingController(text: _name); showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Ubah Nama"), content: TextField(controller: controller), actions: [ElevatedButton(onPressed: () { if(controller.text.isNotEmpty) _updateAuthProfile(newName: controller.text); Navigator.pop(context); }, child: const Text("Simpan"))])); }
  
  void _editGender(BuildContext context, AppThemeData theme) { showModalBottomSheet(context: context, builder: (context) => Container(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.male, color: Colors.blue), title: const Text("Laki-laki"), onTap: () { _saveFirestoreData('gender', 'Laki-laki'); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.female, color: Colors.pink), title: const Text("Perempuan"), onTap: () { _saveFirestoreData('gender', 'Perempuan'); Navigator.pop(context); })]))); }
  
  void _editDOB(BuildContext context, AppThemeData theme) async { DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now()); if (pickedDate != null) { _saveFirestoreData('dob', DateFormat('dd MMMM yyyy').format(pickedDate)); } }
  
  void _editPhone(BuildContext context, AppThemeData theme) { 
    String val = _phone.replaceAll("+62", "").replaceAll(" ", "").replaceAll("-", ""); 
    TextEditingController controller = TextEditingController(text: val); 
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Nomor Handphone", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)), const SizedBox(height: 16), TextField(controller: controller, keyboardType: TextInputType.number, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16, color: theme.textMain), decoration: InputDecoration(prefixText: "+62 ", prefixStyle: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold, fontSize: 16), hintText: "81234567890", hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade300, fontWeight: FontWeight.normal), filled: true, fillColor: theme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary, width: 2), borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))), const SizedBox(height: 20), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { if (controller.text.isNotEmpty) { _saveFirestoreData('phone', "+62 ${controller.text}"); } Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Simpan")))])))); 
  }
  
  Widget _buildSectionHeader(String title, AppThemeData theme) { return Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)))); }
  
  Widget _buildInfoTile(IconData icon, String title, String value, AppThemeData theme, {VoidCallback? onTap, bool isMultiLine = false}) { bool canEdit = onTap != null; return GestureDetector(onTap: canEdit ? onTap : null, child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.textMain.withOpacity(0.1))), child: Row(children: [Icon(icon, color: theme.primary), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textMain), maxLines: isMultiLine ? 3 : 1, overflow: TextOverflow.ellipsis)])), if (canEdit) const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)]))); }

  // --- BUILD UTAMA ---
  @override
  Widget build(BuildContext context) {
    // --- MENGAMBIL TEMA DARI MAIN.DART ---
    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        bool isPro = _memberType == "Pro";

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(title: Text("Informasi Pribadi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)), centerTitle: true, backgroundColor: theme.surface, elevation: 0, iconTheme: IconThemeData(color: theme.textMain)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]), child: Column(children: [
                Stack(children: [CircleAvatar(radius: 50, backgroundImage: NetworkImage(_photoUrl), backgroundColor: Colors.grey.shade200), if (_isUploading) const Positioned.fill(child: CircularProgressIndicator()), Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _pickAndUploadImage, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18))))]), const SizedBox(height: 16),
                GestureDetector(onTap: () => _editNameDialog(context, theme), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_name, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)), const SizedBox(width: 8), Icon(Icons.edit, size: 16, color: Colors.grey.shade400)])), Text("Member ID: $_memberId", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)), const SizedBox(height: 12),
                GestureDetector(onTap: () => _showMemberDetail(context, theme), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(gradient: isPro ? const LinearGradient(colors: [Color(0xFFFFF9E6), Color(0xFFFDF4D4)]) : LinearGradient(colors: [Colors.grey.shade100, Colors.grey.shade200]), borderRadius: BorderRadius.circular(30), border: Border.all(color: isPro ? const Color(0xFFFFD700) : Colors.grey.shade300)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isPro ? Icons.emoji_events : Icons.info_outline, size: 18, color: isPro ? const Color(0xFFD4AF37) : Colors.grey), const SizedBox(width: 8), Text(isPro ? "Chupatu PRO Member" : "Regular Member", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: isPro ? const Color(0xFFD4AF37) : Colors.grey.shade700)), const SizedBox(width: 4), Icon(Icons.arrow_forward_ios, size: 10, color: isPro ? const Color(0xFFD4AF37) : Colors.grey)])))
              ])), const SizedBox(height: 24),
              _buildSectionHeader("Data Diri", theme), _buildInfoTile(Icons.person_outline, "Jenis Kelamin", _gender, theme, onTap: () => _editGender(context, theme)), _buildInfoTile(Icons.cake_outlined, "Tanggal Lahir", _dob, theme, onTap: () => _editDOB(context, theme)), const SizedBox(height: 24),
              _buildSectionHeader("Kontak & Alamat", theme), _buildInfoTile(Icons.email_outlined, "Email", _email, theme), _buildInfoTile(Icons.phone_outlined, "No. Handphone", _phone, theme, onTap: () => _editPhone(context, theme)), _buildInfoTile(Icons.location_on_outlined, "Alamat Lengkap", _address, theme, isMultiLine: true, onTap: () => _editAddress(context, theme)), const SizedBox(height: 30),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _showLogoutConfirmation(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text("Keluar Akun", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)))),
            ]), 
          ),
        );
      },
    );
  }
}