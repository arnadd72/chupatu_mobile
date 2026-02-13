import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagePromoPage extends StatefulWidget {
  const ManagePromoPage({super.key});

  @override
  State<ManagePromoPage> createState() => _ManagePromoPageState();
}

class _ManagePromoPageState extends State<ManagePromoPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendBroadcast() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) return;
    setState(() => _isLoading = true);

    // 1. Ambil SEMUA User
    var users = await FirebaseFirestore.instance.collection('users').get();
    var batch = FirebaseFirestore.instance.batch();

    // 2. Tulis Notifikasi ke Tiap User
    for (var doc in users.docs) {
      var ref = FirebaseFirestore.instance.collection('users').doc(doc.id).collection('notifications').doc();
      batch.set(ref, {
        'title': _titleController.text,
        'body': _bodyController.text,
        'type': 'promo',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    setState(() => _isLoading = false);
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil kirim ke ${users.docs.length} user!")));
      _titleController.clear();
      _bodyController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Promo & Broadcast", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kirim Info Promo", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Pesan ini akan masuk ke menu notifikasi semua user.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Judul Promo (Mis: Diskon Gajian)", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _bodyController, maxLines: 3, decoration: const InputDecoration(labelText: "Isi Pesan", border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendBroadcast,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("KIRIM BROADCAST 🚀", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}