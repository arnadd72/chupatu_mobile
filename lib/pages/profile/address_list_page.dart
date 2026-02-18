import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // Wajib Import ini
import 'package:geocoding/geocoding.dart';   // Wajib Import ini
import 'package:chupatu_mobile/main.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- FUNGSI MUNCULKAN POP-UP TAMBAH ALAMAT ---
  void _showAddAddressDialog(AppThemeData theme) {
    final labelCtrl = TextEditingController(); // cth: Rumah, Kosan
    final addressCtrl = TextEditingController(); // cth: Jl. Sudirman
    final detailCtrl = TextEditingController(); // cth: Pagar hitam

    // Variabel state lokal khusus untuk popup
    bool isLocating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        // Kita pakai StatefulBuilder supaya loading-nya jalan di dalam popup
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {

              // --- LOGIKA GPS DI DALAM MODAL ---
              Future<void> getCurrentLocation() async {
                setModalState(() => isLocating = true); // Loading nyala
                try {
                  // Cek Izin
                  LocationPermission permission = await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.denied) return;
                  }

                  // Ambil Koordinat
                  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

                  // Ubah ke Alamat (Reverse Geocoding)
                  List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

                  if (placemarks.isNotEmpty) {
                    Placemark place = placemarks[0];
                    // Susun format alamat yang rapi
                    String fullAddress = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.postalCode}";

                    // Masukkan ke Controller (Otomatis muncul di TextField)
                    addressCtrl.text = fullAddress;

                    // Jika Label masih kosong, kita tebak ini "Lokasi Saya"
                    if (labelCtrl.text.isEmpty) {
                      labelCtrl.text = "Lokasi Saat Ini";
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal GPS: $e")));
                } finally {
                  setModalState(() => isLocating = false); // Loading mati
                }
              }

              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tambah Alamat Baru", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: Colors.grey.shade400))
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Input Label
                    TextField(controller: labelCtrl, decoration: InputDecoration(labelText: "Label (cth: Rumah, Kantor)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),

                    // TOMBOL GPS (FITUR BARU)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: isLocating ? null : getCurrentLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: theme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.primary.withOpacity(0.2))
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLocating)
                                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: theme.primary))
                              else
                                Icon(Icons.my_location_rounded, color: theme.primary, size: 16),

                              const SizedBox(width: 8),
                              Text(isLocating ? "Mencari Lokasi..." : "Isi Otomatis (GPS)", style: GoogleFonts.plusJakartaSans(color: theme.primary, fontSize: 12, fontWeight: FontWeight.bold))
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input Alamat (Otomatis Terisi tapi Bisa Edit)
                    TextField(
                        controller: addressCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                            labelText: "Alamat Lengkap",
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                        )
                    ),
                    const SizedBox(height: 16),

                    // Input Detail
                    TextField(controller: detailCtrl, decoration: InputDecoration(labelText: "Patokan / Detail (cth: Pagar Hitam)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 24),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (labelCtrl.text.isNotEmpty && addressCtrl.text.isNotEmpty) {
                            // Simpan ke Firestore
                            await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('addresses').add({
                              'label': labelCtrl.text,
                              'fullAddress': addressCtrl.text,
                              'detail': detailCtrl.text,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Label dan Alamat wajib diisi!")));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: const Text("Simpan Alamat", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  // --- FUNGSI HAPUS ALAMAT ---
  void _deleteAddress(String docId) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Hapus Alamat?"),
          content: const Text("Alamat ini akan dihapus permanen."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
            TextButton(onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('addresses').doc(docId).delete();
              Navigator.pop(ctx);
            }, child: const Text("Hapus", style: TextStyle(color: Colors.red))),
          ],
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
            appBar: AppBar(title: Text("Daftar Alamat", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)), backgroundColor: theme.surface, elevation: 0, iconTheme: IconThemeData(color: theme.textMain)),

            // --- TOMBOL TAMBAH ---
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddAddressDialog(theme),
              backgroundColor: theme.primary,
              icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
              label: const Text("Tambah Alamat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),

            // --- LIST ALAMAT DARI FIREBASE ---
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('addresses').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_rounded, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("Belum ada alamat tersimpan.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                    ],
                  ));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.2)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.location_on, color: theme.primary)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['label'] ?? 'Alamat', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)),
                                const SizedBox(height: 4),
                                Text(data['fullAddress'] ?? '', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                                if ((data['detail'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text("Patokan: ${data['detail']}", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 11, fontStyle: FontStyle.italic))),
                                ]
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteAddress(doc.id)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          );
        }
    );
  }
}