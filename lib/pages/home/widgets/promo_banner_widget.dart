import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fungsi copy clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart'; // Untuk AppThemeData

class PromoBannerWidget extends StatefulWidget {
  final AppThemeData theme;
  const PromoBannerWidget({super.key, required this.theme});

  @override
  State<PromoBannerWidget> createState() => _PromoBannerWidgetState();
}

class _PromoBannerWidgetState extends State<PromoBannerWidget> {
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  int _totalBanners = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Pindahkan timer auto-scroll ke sini agar eksklusif milik widget ini
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted) return;
      if (_currentBannerIndex < _totalBanners - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Widget _buildImageBanner(
      String imgUrl, String title, String subtitle, Color accentColor, {String? promoCodeId}
      ) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: accentColor.withOpacity(0.25),
                  blurRadius: 15, offset: const Offset(0, 8)
              )
            ]
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
                children: [
                  Image.network(
                      imgUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover
                  ),
                  Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.centerLeft, end: Alignment.centerRight,
                              colors: [accentColor.withOpacity(0.95), accentColor.withOpacity(0.1)]
                          )
                      )
                  ),
                  Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(8)
                                ),
                                child: Text(
                                    'PROMO',
                                    style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold
                                    )
                                )
                            ),
                            const SizedBox(height: 8),
                            Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold
                                )
                            ),
                            const SizedBox(height: 4),
                            Text(
                                subtitle,
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withOpacity(0.95), fontSize: 12
                                )
                            ),

                            // FITUR KODE PROMO & TAP TO COPY
                            if (promoCodeId != null && promoCodeId.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('promo_codes')
                                      .doc(promoCodeId).get(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData || !snapshot.data!.exists) {
                                      return const SizedBox.shrink();
                                    }

                                    var promoData = snapshot.data!.data() as Map<String, dynamic>;
                                    String code = promoData['code'] ?? '';
                                    if (code.isEmpty) return const SizedBox.shrink();

                                    return GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: code));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Kode '$code' disalin!"),
                                              backgroundColor: Colors.teal,
                                              behavior: SnackBarBehavior.floating,
                                            )
                                        );
                                      },
                                      child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.white.withOpacity(0.5), style: BorderStyle.solid
                                            ),
                                          ),
                                          child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.copy, color: Colors.white, size: 14),
                                                const SizedBox(width: 6),
                                                Text(
                                                    "KODE: $code",
                                                    style: GoogleFonts.plusJakartaSans(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1
                                                    )
                                                ),
                                              ]
                                          )
                                      ),
                                    );
                                  }
                              )
                            ]
                          ]
                      )
                  )
                ]
            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promos')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5).snapshots(),
      builder: (context, snapshot) {

        List<Widget> firebaseBanners = [];
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            firebaseBanners.add(_buildImageBanner(
              data['imageUrl'] ?? 'https://via.placeholder.com/800x400',
              data['title'] ?? 'Promo Spesial',
              data['description'] ?? 'Cek sekarang!',
              widget.theme.primary,
              promoCodeId: data['promoCodeId'],
            ));
          }
        }

        // HANYA PAKAI DATA DARI FIREBASE (Dummy dihapus total)
        List<Widget> finalBanners = firebaseBanners;

        // PROTEKSI: Sembunyikan widget kalau belum ada promo dari admin
        if (finalBanners.isEmpty) return const SizedBox.shrink();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _totalBanners = finalBanners.length;
        });

        return Column(
          children: [
            SizedBox(
                height: 200,
                child: PageView(
                    controller: _bannerController,
                    physics: const BouncingScrollPhysics(), // Memastikan user tetap bisa geser manual
                    onPageChanged: (index) => setState(() => _currentBannerIndex = index),
                    children: finalBanners
                )
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    finalBanners.length,
                        (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        width: _currentBannerIndex == index ? 24 : 6, height: 6,
                        decoration: BoxDecoration(
                            color: _currentBannerIndex == index
                                ? widget.theme.primary : Colors.grey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(3)
                        )
                    )
                )
            ),
          ],
        );
      },
    );
  }
}