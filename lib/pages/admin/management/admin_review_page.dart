import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart'; // IMPORT TEMA
import 'package:skeletonizer/skeletonizer.dart';

class AdminReviewPage extends StatefulWidget {
  const AdminReviewPage({super.key});

  @override
  State<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends State<AdminReviewPage> {

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  // ==========================================================
  // FITUR: Buka Form Balasan (Bisa untuk Create dan Update)
  // ==========================================================
  void _openReplyDialog(String docId, String existingReply, AppThemeData theme) {
    TextEditingController replyController = TextEditingController(text: existingReply);

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: theme.surface,
            title: Text(
                existingReply.isEmpty ? "Balas Ulasan" : "Edit Balasan",
                style: TextStyle(color: theme.textMain)
            ),
            content: TextField(
              controller: replyController,
              maxLines: 3,
              style: TextStyle(color: theme.textMain),
              decoration: InputDecoration(
                hintText: "Ketik balasan profesional dari admin...",
                hintStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))
                ),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.primary)
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
                onPressed: () async {
                  if (replyController.text.trim().isEmpty) return;

                  Navigator.pop(context); // Tutup dialog dulu

                  // Simpan ke Firestore
                  await FirebaseFirestore.instance
                      .collection('reviews')
                      .doc(docId)
                      .update({'adminReply': replyController.text.trim()});

                  if(mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Balasan berhasil disimpan!"))
                    );
                  }
                },
                child: Text(
                    existingReply.isEmpty ? "Kirim Balasan" : "Update",
                    style: const TextStyle(color: Colors.white)
                ),
              ),
            ],
          );
        }
    );
  }

  // ==========================================================
  // FITUR: Hapus Balasan Admin
  // ==========================================================
  void _deleteReply(String docId) async {
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(docId)
        .update({'adminReply': FieldValue.delete()}); // Hapus field-nya

    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Balasan admin telah dihapus."))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            title: Text(
              "Monitor Ulasan",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: theme.textMain,
              ),
            ),
            backgroundColor: theme.surface,
            elevation: 1,
            iconTheme: IconThemeData(color: theme.textMain),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Terjadi kesalahan sistem."));
              }

              final isLoading = snapshot.connectionState == ConnectionState.waiting;

              if (!isLoading && snapshot.requireData.docs.isEmpty) {
                return Center(
                  child: Text(
                    "Belum ada ulasan dari pelanggan.",
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                  ),
                );
              }

              final docs = isLoading ? [] : snapshot.requireData.docs;

              return Skeletonizer(
                enabled: isLoading,
                child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: isLoading ? 3 : docs.length,
                itemBuilder: (context, index) {
                  if (isLoading) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: const SizedBox(height: 150),
                    );
                  }
                  var doc = docs[index];
                  var review = doc.data() as Map<String, dynamic>;

                  // =========================================================
                  // MAPPING DATA SESUAI FIREBASE LO
                  // =========================================================
                  String reviewerName = review['userName'] ?? 'Anonim';
                  int rating = (review['rating'] ?? 0).toInt();
                  String comment = review['reviewText'] ?? 'Tidak ada komentar.'; // <-- INI YANG BIKIN MUNCUL
                  String serviceName = review['serviceName'] ?? 'Layanan Chupatu'; // Tambahan
                  String userPhotoUrl = review['userPhoto'] ?? ''; // Tambahan
                  String adminReply = review['adminReply'] ?? '';

                  // Perbaikan URL Foto agar bisa diload dengan aman (Mencegah error HTTP vs HTTPS)
                  userPhotoUrl = userPhotoUrl.replaceAll('http://', 'https://');

                  String timeString = "Waktu tidak diketahui";
                  if (review['createdAt'] != null) {
                    DateTime dt = (review['createdAt'] as Timestamp).toDate();
                    timeString = "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}";
                  }

                  return Card(
                    color: theme.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // BAGIAN 1: REVIEW PELANGGAN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // NAMPILIN FOTO PROFIL PELANGGAN
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: theme.primary.withOpacity(0.2),
                                    backgroundImage: userPhotoUrl.isNotEmpty
                                        ? NetworkImage(userPhotoUrl)
                                        : null,
                                    child: userPhotoUrl.isEmpty
                                        ? Icon(Icons.person, size: 20, color: theme.primary)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reviewerName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: theme.textMain,
                                        ),
                                      ),
                                      Text(
                                        serviceName, // Nampilin nama layanan (misal: Fast Clean)
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: theme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              _buildStars(rating),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            comment, // Isi komentar pelanggan
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.textMain.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Dikirim pada: $timeString",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                          const SizedBox(height: 12),

                          // BAGIAN 2: BALASAN ADMIN
                          if (adminReply.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.primary.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.storefront_rounded, size: 14, color: theme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Balasan Admin Chupatu",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: theme.primary
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    adminReply,
                                    style: TextStyle(color: theme.textMain, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),

                          // TOMBOL AKSI
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (adminReply.isNotEmpty)
                                  TextButton(
                                    onPressed: () => _deleteReply(doc.id),
                                    child: const Text(
                                        "Hapus Balasan",
                                        style: TextStyle(color: Colors.red, fontSize: 12)
                                    ),
                                  ),
                                TextButton(
                                  onPressed: () => _openReplyDialog(doc.id, adminReply, theme),
                                  child: Text(
                                    adminReply.isEmpty ? "Balas" : "Edit Balasan",
                                    style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              );
            },
          ),
        );
      },
    );
  }
}