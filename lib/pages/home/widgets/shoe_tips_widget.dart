import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/main.dart'; // Import ini WAJIB ada di atas!

class ShoeTipsWidget extends StatelessWidget {
  final AppThemeData theme;

  const ShoeTipsWidget({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    // Data Dummy Tips
    final tips = [
      {
        'title': 'Jangan Jemur di Matahari',
        'desc': 'Sinar UV bikin lem sepatu cepat rusak dan warna pudar.',
        'img': 'assets/images/sepatu nike.jpg',
        'content': 'Menjemur sepatu langsung di bawah sinar matahari dapat menyebabkan lem sepatu meleleh dan warna bahan (terutama suede/canvas) menjadi pudar. Sebaiknya angin-anginkan saja di tempat teduh.'
      },
      {
        'title': 'Simpan Pakai Silica Gel',
        'desc': 'Cegah jamur dengan menjaga kelembapan di rak sepatu.',
        'img': 'assets/images/sepatu-hitamputih.jpg',
        'content': 'Kelembapan adalah musuh utama sepatu. Selalu masukkan silica gel ke dalam kotak sepatu atau rak penyimpanan untuk menyerap kelembapan berlebih dan mencegah tumbuhnya jamur.'
      },
      {
        'title': 'Bersihkan Noda Segera',
        'desc': 'Noda tanah atau kopi akan sulit hilang jika dibiarkan > 24 jam.',
        'img': 'assets/images/sepatu-running.jpg',
        'content': 'Jangan menunda membersihkan noda! Semakin lama noda menempel, semakin dalam ia meresap ke serat kain. Gunakan tisu basah atau lap lembab sesegera mungkin saat terkena noda.'
      },
    ];

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: tips.length,
        separatorBuilder: (c, i) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          var item = tips[index];
          return GestureDetector(
            onTap: () {
              // Navigasi ke Halaman Detail Tips
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TipsDetailPage(
                    title: item['title']!,
                    imageUrl: item['img']!,
                    content: item['content']!,
                  ),
                ),
              );
            },
            child: Container(
              width: 260,
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                    child: Image.asset(
                      item['img']!,
                      width: 100,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c,e,s) => Container(width: 100, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item['title']!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textMain)),
                          const SizedBox(height: 6),
                          Text(item['desc']!, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// HALAMAN DETAIL TIPS
class TipsDetailPage extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String content;

  const TipsDetailPage({super.key, required this.title, required this.imageUrl, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Tips & Trick", style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(imageUrl, width: double.infinity, height: 250, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(content, style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.grey.shade800, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}