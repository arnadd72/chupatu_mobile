import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tambah Alamat Baru", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
            const SizedBox(height: 20),
            TextField(controller: labelCtrl, decoration: InputDecoration(labelText: "Label (cth: Rumah, Kosan)", border: const OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: addressCtrl, maxLines: 2, decoration: InputDecoration(labelText: "Alamat Lengkap", border: const OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: detailCtrl, decoration: InputDecoration(labelText: "Patokan / Detail", border: const OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (labelCtrl.text.isNotEmpty && addressCtrl.text.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('addresses').add({
                      'label': labelCtrl.text,
                      'fullAddress': addressCtrl.text,
                      'detail': detailCtrl.text,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("Simpan Alamat", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI HAPUS ALAMAT ---
  void _deleteAddress(String docId) {
    FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('addresses').doc(docId).delete();
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
                  return Center(child: Text("Belum ada alamat tersimpan.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
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
                                Text(data['fullAddress'] ?? '', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade700, fontSize: 14)),
                                if ((data['detail'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text("Patokan: ${data['detail']}", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
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