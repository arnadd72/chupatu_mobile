import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Dibutuhkan untuk format tanggal di AllReviewsPage
import 'package:chupatu_mobile/main.dart';

// ==============================================================
// 1. WIDGET UNTUK DI HOME PAGE (Tampil Horizontal, Limit 5)
// ==============================================================
class ReviewRatingSection extends StatelessWidget {
  const ReviewRatingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER DENGAN TOMBOL LIHAT SEMUA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Review & Rating ⭐",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textMain,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Langsung memanggil class AllReviewsPage yang ada di bawah file ini
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AllReviewsPage())
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Lihat Semua",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.primary,
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .orderBy('createdAt', descending: true)
                    .limit(5) // <-- TAMPIL CUMA 5 TERATAS DI HOME
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "Belum ada ulasan.",
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      ),
                    );
                  }

                  var reviews = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: reviews.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      var data = reviews[index].data() as Map<String, dynamic>;
                      int rating = data['rating'] ?? 5;

                      return Container(
                        width: 260,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: theme.primary.withOpacity(0.2),
                                  backgroundImage: (data['userPhoto'] != null && data['userPhoto'].toString().isNotEmpty)
                                      ? NetworkImage(data['userPhoto'])
                                      : null,
                                  child: (data['userPhoto'] == null || data['userPhoto'].toString().isEmpty)
                                      ? Icon(Icons.person, size: 16, color: theme.primary)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    data['userName'] ?? 'Pelanggan',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: theme.textMain,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Text(
                                '"${data['reviewText'] ?? ''}"',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==============================================================
// 2. HALAMAN LIHAT SEMUA ULASAN (Tampil Vertikal, Tanpa Limit)
// ==============================================================
class AllReviewsPage extends StatelessWidget {
  const AllReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text("Semua Ulasan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              backgroundColor: theme.surface,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
              centerTitle: true,
            ),
            body: StreamBuilder<QuerySnapshot>(
              // MENGAMBIL SEMUA DATA REVIEW TANPA LIMIT
              stream: FirebaseFirestore.instance.collection('reviews').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("Belum ada ulasan.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                var reviews = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    var data = reviews[index].data() as Map<String, dynamic>;
                    int rating = data['rating'] ?? 5;

                    // Format Tanggal
                    String dateStr = '';
                    if (data['createdAt'] != null) {
                      dateStr = DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate());
                    }

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: theme.primary.withOpacity(0.2),
                                backgroundImage: (data['userPhoto'] != null && data['userPhoto'].toString().isNotEmpty)
                                    ? NetworkImage(data['userPhoto'])
                                    : null,
                                child: (data['userPhoto'] == null || data['userPhoto'].toString().isEmpty)
                                    ? Icon(Icons.person, size: 20, color: theme.primary)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['userName'] ?? 'Pelanggan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(data['serviceName'] ?? 'Layanan Chupatu', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: List.generate(5, (starIndex) {
                                      return Icon(starIndex < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 16);
                                    }),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(dateStr, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey.shade400)),
                                ],
                              ),
                            ],
                          ),
                          if (data['reviewText'] != null && data['reviewText'].toString().trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text('"${data['reviewText']}"', style: GoogleFonts.plusJakartaSans(color: theme.textMain.withOpacity(0.8), fontSize: 13, height: 1.5, fontStyle: FontStyle.italic)),
                          ]
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