import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chupatu_mobile/main.dart'; // IMPORT TEMA

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

  final String _defaultPromoImage = "https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=800";

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _sendBroadcast() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Judul dan Isi Pesan wajib diisi!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _defaultPromoImage;

      if (_imageFile != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = FirebaseStorage.instance.ref().child('promo_banners/$fileName.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('promos').add({
        'title': _titleController.text,
        'description': _bodyController.text,
        'imageUrl': imageUrl,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

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
          'imageUrl': imageUrl,
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
    return ValueListenableBuilder<AppThemeData>( // BUNGKUS DENGAN TEMA
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background, // Adaptif
            appBar: AppBar(
              title: Text("Promo & Broadcast", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              backgroundColor: theme.surface, // Adaptif
              elevation: 1,
              iconTheme: IconThemeData(color: theme.textMain),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Buat Promo Baru", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(height: 8),
                  Text("Promo akan muncul di Banner Home dan Notifikasi User.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                  const SizedBox(height: 24),

                  // INPUT GAMBAR
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: theme.surface, // Adaptif
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
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

                  // TEXT FIELD ADAPTIF
                  TextField(
                      controller: _titleController,
                      style: TextStyle(color: theme.textMain),
                      decoration: InputDecoration(
                        labelText: "Judul Promo",
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary)),
                      )
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _bodyController,
                      maxLines: 3,
                      style: TextStyle(color: theme.textMain),
                      decoration: InputDecoration(
                        labelText: "Deskripsi Promo",
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary)),
                      )
                  ),
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
    );
  }
}