import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chupatu_mobile/main.dart';

class ManagePromoPage extends StatefulWidget {
  const ManagePromoPage({super.key});

  @override
  State<ManagePromoPage> createState() => _ManagePromoPageState();
}

class _ManagePromoPageState extends State<ManagePromoPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  // URL Gambar Default (Kalau admin malas upload foto)
  final String _defaultPromoImage = "https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=800";

  // --- 1. PILIH GAMBAR DARI GALERI ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // --- 2. KIRIM PROMO & BROADCAST ---
  Future<void> _sendBroadcast() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Judul dan Isi Pesan wajib diisi!")));
      return;
    }

    // CATATAN: Validasi gambar wajib SUDAH DIHAPUS.
    // Sekarang kalau gambar kosong, lanjut terus.

    setState(() => _isLoading = true);

    try {
      String imageUrl = _defaultPromoImage; // Default awal

      // A. Cek: Apakah Admin upload gambar baru?
      if (_imageFile != null) {
        // Kalau ada file, Upload ke Storage
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = FirebaseStorage.instance.ref().child('promo_banners/$fileName.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL(); // Timpa URL default dengan URL hasil upload
      }

      // B. Simpan ke Collection 'promos' (Untuk Banner Home)
      await FirebaseFirestore.instance.collection('promos').add({
        'title': _titleController.text,
        'description': _bodyController.text,
        'imageUrl': imageUrl, // Pakai URL (entah itu default atau hasil upload)
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // C. Broadcast Notifikasi ke Semua User (Lonceng)
      var users = await FirebaseFirestore.instance.collection('users').get();
      var batch = FirebaseFirestore.instance.batch();

      for (var doc in users.docs) {
        var ref = FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .collection('notifications')
            .doc();

        batch.set(ref, {
          'title': _titleController.text,
          'body': _bodyController.text,
          'type': 'promo',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'imageUrl': imageUrl, // Opsional: Simpan gambar di notif juga
        });
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Promo berhasil dikirim ke ${users.docs.length} user!")));
        _titleController.clear();
        _bodyController.clear();
        setState(() => _imageFile = null);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Promo & Broadcast", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Buat Promo Baru", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Promo akan muncul di Banner Home dan Notifikasi User.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            const SizedBox(height: 24),

            // INPUT GAMBAR (OPSIONAL)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
                ),
                child: _imageFile == null
                    ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
                      const SizedBox(height: 8),
                      Text("Upload Banner (Opsional)", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text("Jika kosong, akan pakai gambar default", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ]
                )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Judul Promo", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _bodyController, maxLines: 3, decoration: const InputDecoration(labelText: "Deskripsi Promo", border: OutlineInputBorder())),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendBroadcast,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("KIRIM BROADCAST 🚀", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}