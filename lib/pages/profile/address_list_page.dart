import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:chupatu_mobile/main.dart';

// Import ini untuk memanggil layar peta dari ProfilePage (pastikan pathnya benar)
import 'package:chupatu_mobile/pages/profile/profile_page.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- LOGIKA PEMANGGILAN PETA UNTUK ADD/EDIT ALAMAT ---
  Future<Map<String, dynamic>?> _openMapPicker() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    LatLng initialLoc = const LatLng(-6.974001, 107.630348); // Telkom University Default

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      initialLoc = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("GPS gagal, pakai default.");
    }

    if (!mounted) return null;
    Navigator.pop(context);

    // Memanggil UI Peta yang sudah kita buat sebelumnya di ProfilePage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileMapSelectionScreen(initialLocation: initialLoc)),
    );

    if (result != null && result is Map<String, dynamic>) {
      return result;
    }
    return null;
  }

  // --- FUNGSI MUNCULKAN POP-UP TAMBAH ALAMAT ---
  Future<void> _showAddAddressDialog(AppThemeData theme, List<dynamic> currentAddresses) async {
    TextEditingController labelCtrl = TextEditingController();
    TextEditingController detailCtrl = TextEditingController();

    // Variabel penampung koordinat
    double? selectedLat;
    double? selectedLng;

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

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Map<String, dynamic>? result = await _openMapPicker();
                  if (result != null) {
                    detailCtrl.text = result['address'];
                    selectedLat = result['latitude'];
                    selectedLng = result['longitude'];
                  }
                },
                icon: Icon(Icons.map_rounded, color: theme.primary),
                label: Text("Pilih Otomatis di Peta", style: TextStyle(color: theme.primary)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
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
              if (labelCtrl.text.isEmpty || detailCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Label dan Alamat wajib diisi!")));
                return;
              }

              String newId = DateTime.now().millisecondsSinceEpoch.toString();
              bool isFirst = currentAddresses.isEmpty;

              // MENYIMPAN KE STRUKTUR ARRAY BARU + KOORDINAT
              var newAddress = {
                'id': newId,
                'label': labelCtrl.text.trim(),
                'detail': detailCtrl.text.trim(),
                'latitude': selectedLat ?? -7.4245,  // Default Purwokerto jika tidak pakai map
                'longitude': selectedLng ?? 109.2302,
                'isPrimary': isFirst,
              };

              List<dynamic> updatedList = List.from(currentAddresses)..add(newAddress);
              Map<String, dynamic> payload = {'addresses': updatedList};

              if (isFirst) payload['address'] = detailCtrl.text.trim();

              await FirebaseFirestore.instance.collection('users').doc(user!.uid).update(payload);
              if (mounted) {
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- FUNGSI HAPUS ALAMAT (ARRAY BASED) ---
  void _deleteAddress(List<dynamic> currentAddresses, String targetId) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Hapus Alamat?"),
          content: const Text("Alamat ini akan dihapus permanen."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
            TextButton(onPressed: () async {
              List<dynamic> updatedList = currentAddresses.where((a) => a['id'] != targetId).toList();
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

              await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                'addresses': updatedList,
                'address': newMainAddress.isNotEmpty ? newMainAddress : FieldValue.delete(),
              });

              if (mounted) Navigator.pop(ctx);
            }, child: const Text("Hapus", style: TextStyle(color: Colors.red))),
          ],
        )
    );
  }

  // --- FUNGSI SET ALAMAT UTAMA ---
  Future<void> _setPrimaryAddress(List<dynamic> addresses, String targetId, String fullAddress) async {
    if (user == null) return;

    List<dynamic> updatedList = addresses.map((a) {
      var newAddr = Map<String, dynamic>.from(a);
      newAddr['isPrimary'] = (newAddr['id'] == targetId);
      return newAddr;
    }).toList();

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'addresses': updatedList,
      'address': fullAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(title: Text("Daftar Alamat", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)), backgroundColor: theme.surface, elevation: 0, iconTheme: IconThemeData(color: theme.textMain)),

            // --- LIST ALAMAT DARI ARRAY USERS ---
            body: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                List<dynamic> currentAddrs = userData['addresses'] ?? [];

                return Stack(
                  children: [
                    if (currentAddrs.isEmpty)
                      Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_rounded, size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text("Belum ada alamat tersimpan.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                        ],
                      ))
                    else
                      ListView.builder(
                        padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 100),
                        itemCount: currentAddrs.length,
                        itemBuilder: (context, index) {
                          var data = currentAddrs[index] as Map<String, dynamic>;
                          bool isPrimary = data['isPrimary'] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: theme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isPrimary ? theme.primary : Colors.grey.withOpacity(0.2), width: isPrimary ? 2 : 1),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: isPrimary ? theme.primary.withOpacity(0.1) : Colors.grey.shade100, shape: BoxShape.circle),
                                    child: Icon(Icons.location_on, color: isPrimary ? theme.primary : Colors.grey)
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(data['label'] ?? 'Alamat', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)),
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
                                      Text(data['detail'] ?? '', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  onSelected: (val) {
                                    if (val == 'primary') {
                                      _setPrimaryAddress(currentAddrs, data['id'], data['detail']);
                                    } else if (val == 'delete') {
                                      _deleteAddress(currentAddrs, data['id']);
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
                      ),

                    // --- TOMBOL TAMBAH MELAYANG ---
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0, left: 24, right: 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              onPressed: () => _showAddAddressDialog(theme, currentAddrs),
                              icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
                              label: const Text("Tambah Alamat Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 5,
                              )
                          ),
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          );
        }
    );
  }
}