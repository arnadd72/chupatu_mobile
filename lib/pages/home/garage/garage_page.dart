import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chupatu_mobile/main.dart';
// import 'package:chupatu_mobile/pages/order/booking_page.dart'; // Aktifkan nanti untuk navigasi

class GaragePage extends StatefulWidget {
  // Parameter untuk memperbaiki posisi tombol tambah
  final bool isFromNavbar;

  // Defaultnya false (anggap dari Home Widget), di MainPage nanti kita set true
  const GaragePage({super.key, this.isFromNavbar = false});

  @override
  State<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends State<GaragePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // State untuk Filter
  String _selectedBrandFilter = 'All';

  // --- 1. FUNGSI PILIH LAYANAN (SERVICES) ---
  void _showServicePicker(BuildContext context, Map<String, dynamic> shoeData, AppThemeData theme) {
    // Daftar Layanan Dummy
    final services = [
      {'name': 'Deep Clean', 'price': 'Rp 40.000', 'icon': Icons.water_drop_rounded, 'color': Colors.blue},
      {'name': 'Fast Clean', 'price': 'Rp 25.000', 'icon': Icons.timer_rounded, 'color': Colors.orange},
      {'name': 'Unyellowing', 'price': 'Rp 50.000', 'icon': Icons.wb_sunny_rounded, 'color': Colors.amber},
      {'name': 'Repair', 'price': 'Start Rp 30rb', 'icon': Icons.build_rounded, 'color': Colors.grey},
      {'name': 'Repaint', 'price': 'Start Rp 100rb', 'icon': Icons.format_paint_rounded, 'color': Colors.purple},
      {'name': 'Waterproof', 'price': 'Rp 35.000', 'icon': Icons.umbrella_rounded, 'color': Colors.teal},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text("Mau diapakan sepatu ini?", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
            Text("${shoeData['brand']} - ${shoeData['name']}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),

            // Grid Menu Layanan
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                var s = services[index];
                return InkWell(
                  onTap: () {
                    Navigator.pop(context); // Tutup modal
                    // TODO: Arahkan ke Booking Page dengan membawa data sepatu & layanan
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Memilih layanan ${s['name']} untuk ${shoeData['name']}"))
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (s['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (s['color'] as Color).withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(s['icon'] as IconData, color: s['color'] as Color, size: 28),
                        const SizedBox(height: 8),
                        Text(s['name'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textMain)),
                        Text(s['price'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- 2. FUNGSI FILTER BRAND ---
  void _showFilterModal(BuildContext context, List<String> availableBrands, AppThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Filter Berdasarkan Brand", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFilterChip('All', theme),
                ...availableBrands.map((brand) => _buildFilterChip(brand, theme)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, AppThemeData theme) {
    bool isSelected = _selectedBrandFilter == label;
    return ChoiceChip(
      label: Text(label),
      labelStyle: GoogleFonts.plusJakartaSans(
          color: isSelected ? Colors.white : theme.textMain,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedBrandFilter = label;
        });
        Navigator.pop(context);
      },
      selectedColor: theme.primary,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.transparent)),
    );
  }

  // --- FUNGSI TAMBAH SEPATU (Tetap sama) ---
  void _showAddShoeModal(BuildContext context, AppThemeData theme) {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final sizeController = TextEditingController();
    final noteController = TextEditingController();

    final List<String> dummyImages = [
      "https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=400",
      "https://images.unsplash.com/photo-1607522370275-f14206abe5d3?q=80&w=400",
      "https://images.unsplash.com/photo-1549298916-b41d501d3772?q=80&w=400",
      "https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?q=80&w=400",
    ];

    String selectedImage = dummyImages[0];

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(color: theme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Text("Tambah Koleksi Baru", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textMain)),
                    const SizedBox(height: 24),

                    Expanded(
                      child: ListView(
                        children: [
                          Text("Pilih Tampilan Sepatu", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textMain)),
                          const SizedBox(height: 12),
                          SizedBox(height: 100, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: dummyImages.length, separatorBuilder: (c, i) => const SizedBox(width: 12), itemBuilder: (context, index) { bool isSelected = selectedImage == dummyImages[index]; return GestureDetector(onTap: () { setModalState(() { selectedImage = dummyImages[index]; }); }, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 100, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: isSelected ? Border.all(color: theme.primary, width: 3) : null, image: DecorationImage(image: NetworkImage(dummyImages[index]), fit: BoxFit.cover, colorFilter: isSelected ? null : ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken))), child: isSelected ? Center(child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.check, size: 16, color: theme.primary))) : null)); })),
                          const SizedBox(height: 24),
                          _buildInputLabel("Nama Sepatu", theme), _buildTextField(nameController, "Contoh: Air Jordan 1 High", theme), const SizedBox(height: 16),
                          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel("Brand", theme), _buildTextField(brandController, "Nike, Adidas...", theme)])), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel("Ukuran (Size)", theme), _buildTextField(sizeController, "42 / 9 US", theme, isNumber: true)]))]),
                          const SizedBox(height: 16),
                          _buildInputLabel("Catatan Kondisi (Opsional)", theme), _buildTextField(noteController, "Ada noda di bagian sol...", theme, maxLines: 3),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty || brandController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama dan Brand wajib diisi!"), backgroundColor: Colors.orange)); return; }
                          try {
                            await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('garage').add({'name': nameController.text, 'brand': brandController.text, 'size': sizeController.text, 'note': noteController.text, 'image': selectedImage, 'createdAt': FieldValue.serverTimestamp()});
                            if (context.mounted) Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sepatu berhasil masuk garasi!"), backgroundColor: Colors.green));
                          } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red)); }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: theme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5, shadowColor: theme.primary.withOpacity(0.4)),
                        child: Text("Simpan ke Garasi", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.background,

          // --- PERBAIKAN BUG POSISI TOMBOL ---
          // Jika dari Navbar (isFromNavbar = true), kita angkat 90px agar tidak ketutup.
          // Jika dari Home (isFromNavbar = false), padding standar 16px saja.
          floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: widget.isFromNavbar ? 90.0 : 16.0),
            child: FloatingActionButton.extended(
              onPressed: () => _showAddShoeModal(context, theme),
              backgroundColor: theme.textMain,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text("Tambah Sepatu", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),

          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: theme.background,
                elevation: 0,
                pinned: true,
                expandedHeight: 100.0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text("My Garage", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.w800)),
                  background: Container(color: theme.background),
                ),
                actions: [
                  // --- TOMBOL FILTER ---
                  StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('garage').snapshots(),
                      builder: (context, snapshot) {
                        List<String> brands = [];
                        if (snapshot.hasData) {
                          // Ambil semua brand yang unik
                          brands = snapshot.data!.docs.map((doc) => (doc.data() as Map)['brand'].toString()).toSet().toList();
                        }

                        return IconButton(
                          icon: Icon(Icons.filter_list_rounded, color: theme.textMain),
                          onPressed: () => _showFilterModal(context, brands, theme),
                        );
                      }
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('garage').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.checkroom_rounded, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text("Garasi Masih Kosong", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                            Text("Mulai tambahkan koleksi sepatumu!", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }

                  var shoes = snapshot.data!.docs;

                  // --- LOGIC FILTER CLIENT SIDE ---
                  if (_selectedBrandFilter != 'All') {
                    shoes = shoes.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data['brand'] == _selectedBrandFilter;
                    }).toList();
                  }

                  if (shoes.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(child: Text("Tidak ada sepatu brand $_selectedBrandFilter", style: GoogleFonts.plusJakartaSans(color: Colors.grey))),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 16, mainAxisSpacing: 16),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          var data = shoes[index].data() as Map<String, dynamic>;
                          return _buildShoeCard(data, theme);
                        },
                        childCount: shoes.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET KARTU SEPATU ---
  Widget _buildShoeCard(Map<String, dynamic> data, AppThemeData theme) {
    return Container(
      decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(data['image'] ?? '', width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image_not_supported)))),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)), child: Text(data['brand'] ?? '-', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name'] ?? 'Sepatu', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain)),
                      Text("Size: ${data['size'] ?? '-'}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                    ],
                  ),

                  // --- TOMBOL PILIH LAYANAN ---
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () => _showServicePicker(context, data, theme), // Buka Bottom Sheet
                      style: OutlinedButton.styleFrom(side: BorderSide(color: theme.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero),
                      child: Text("Pilih Layanan", style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primary)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, AppThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textMain)));
  }

  Widget _buildTextField(TextEditingController controller, String hint, AppThemeData theme, {bool isNumber = false, int maxLines = 1}) {
    return Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: TextField(controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, maxLines: maxLines, decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey.shade400), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))));
  }
}