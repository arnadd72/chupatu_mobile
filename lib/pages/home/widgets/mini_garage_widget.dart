import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/home/garage/garage_page.dart'; // Import halaman Garage lengkap

class MiniGarageWidget extends StatelessWidget {
  final AppThemeData theme;

  const MiniGarageWidget({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Column(
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('My Garage', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text("PREMIUM", style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold, color: theme.primary)),
                  )
                ],
              ),
              GestureDetector(
                  onTap: () {
                    // Navigasi ke Halaman Garage Lengkap
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const GaragePage(isFromNavbar: false))); // Matikan mode navbar
                  },
                  child: Text('Lihat Semua', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: theme.primary, fontWeight: FontWeight.bold))
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List Horizontal
        SizedBox(
          height: 140, // Tinggi area list
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('garage')
                .orderBy('createdAt', descending: true)
                .limit(5) // Ambil 5 sepatu terakhir
                .snapshots(),
            builder: (context, snapshot) {
              // 1. Handle Error Silent
              if (snapshot.hasError) return const SizedBox();

              // 2. REVISI LOGIC (ANTI KEDIP)
              // Hanya tampilkan loading jika BENAR-BENAR belum ada data.
              if (!snapshot.hasData) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (c, i) => const SizedBox(width: 12),
                  itemBuilder: (c, i) => _buildShimmerItem(),
                );
              }

              var docs = snapshot.data!.docs;

              // Empty State (Jika belum punya sepatu)
              if (docs.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GaragePage())),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, color: theme.primary, size: 32),
                        const SizedBox(height: 8),
                        Text("Tambah Koleksi Pertama", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textMain)),
                      ],
                    ),
                  ),
                );
              }

              // Data List
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (c, i) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  return _buildMiniShoeCard(context, data, theme); // Pass context untuk navigasi
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget Shimmer Loading
  Widget _buildShimmerItem() {
    return Container(
      width: 110,
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildMiniShoeCard(BuildContext context, Map<String, dynamic> data, AppThemeData theme) {
    // REVISI: Bungkus dengan GestureDetector agar bisa diklik
    return GestureDetector(
      onTap: () {
        // Arahkan ke Garage Page saat kartu diklik
        Navigator.push(context, MaterialPageRoute(builder: (context) => const GaragePage()));
      },
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  data['image'] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c,e,s) => Container(color: Colors.grey.shade200, child: Icon(Icons.checkroom, color: Colors.grey.shade400)),
                ),
              ),
            ),
            // Info Nama
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['brand'] ?? '-',
                      style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold, color: theme.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['name'] ?? 'Sepatu',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textMain),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}