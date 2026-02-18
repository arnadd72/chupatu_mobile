import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';

// PAGE IMPORTS
import 'package:chupatu_mobile/pages/profile/profile_page.dart';
import 'package:chupatu_mobile/pages/profile/member_payment_page.dart';
import 'package:chupatu_mobile/pages/order/service_detail_page.dart';
import 'package:chupatu_mobile/pages/home/widgets/auto_magic_card.dart';
import 'package:chupatu_mobile/pages/home/magic_result_detail_page.dart';
import 'package:chupatu_mobile/pages/notification/notification_page.dart';
// Tambahkan import ini
import 'package:chupatu_mobile/pages/home/garage/garage_page.dart';

// WIDGET IMPORTS
import 'package:chupatu_mobile/pages/home/widgets/shoe_tips_widget.dart';
import 'package:chupatu_mobile/pages/home/widgets/live_tracking_widget.dart';
import 'package:chupatu_mobile/pages/home/widgets/mini_garage_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  bool _showFloatingPromo = true;
  late AnimationController _upgradeAnimController;
  final User? user = FirebaseAuth.instance.currentUser;
  int _totalBanners = 3;

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(seconds: 5), (Timer timer) {
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

    _upgradeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) return 'Good Morning,';
    if (hour < 15) return 'Good Afternoon,';
    if (hour < 19) return 'Good Evening,';
    return 'Good Night,';
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _upgradeAnimController.dispose();
    super.dispose();
  }

  // --- FUNGSI GANTI TEMA (TAMPILAN GRID KECIL) ---
  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Supaya bisa menyesuaikan tinggi konten
      builder: (context) {
        // Ambil tema saat ini untuk styling modal
        final currentTheme = ThemeConfig.currentTheme.value;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: currentTheme.surface, // Mengikuti warna tema
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Garis Indikator di atas
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),

              Text(
                "Pilih Tampilan Aplikasi",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: currentTheme.textMain
                ),
              ),
              const SizedBox(height: 24),

              // GRID TEMA (WRAP)
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 20,     // Jarak antar kolom
                    runSpacing: 20,  // Jarak antar baris
                    alignment: WrapAlignment.center,
                    children: List.generate(ThemeConfig.themes.length, (index) {
                      final themeItem = ThemeConfig.themes[index];
                      final bool isSelected = currentTheme.name == themeItem.name;

                      return GestureDetector(
                        onTap: () {
                          ThemeConfig.changeTheme(index);
                          Navigator.pop(context); // Tutup modal setelah pilih
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // BULATAN WARNA (DIPERKECIL)
                            Container(
                              width: 50,  // Ukuran diperkecil (sebelumnya mungkin 60-70)
                              height: 50,
                              decoration: BoxDecoration(
                                  color: themeItem.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: isSelected ? currentTheme.textMain : Colors.transparent,
                                      width: 2
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2)
                                    )
                                  ]
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                                  : null,
                            ),
                            const SizedBox(height: 8),

                            // LABEL NAMA TEMA
                            SizedBox(
                              width: 60, // Batasi lebar teks
                              child: Text(
                                themeItem.name.replaceAll(' ', '\n'), // Nama jadi 2 baris kalau panjang
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10, // Font diperkecil
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? currentTheme.textMain : Colors.grey,
                                    height: 1.2
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Silakan Login Kembali"));

    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
          builder: (context, userSnapshot) {

            // --- LOGIC PENGECEKAN STATUS PRO ---
            bool isPro = false;
            String displayName = user?.displayName ?? 'Guest';
            String photoURL = user?.photoURL ?? 'https://i.pravatar.cc/150';

            if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
              var userData = userSnapshot.data!.data() as Map<String, dynamic>;

              // Cek field 'memberType' ATAU field 'role'
              String mType = (userData['memberType'] ?? "").toString();
              String uRole = (userData['role'] ?? "").toString();

              isPro = (mType == 'Pro' || uRole == 'Pro');

              if (userData['displayName'] != null) displayName = userData['displayName'];
              if (userData['photoURL'] != null) photoURL = userData['photoURL'];
            }

            return Scaffold(
              backgroundColor: theme.background,
              body: Stack(
                children: [
                  Positioned(top: -80, left: -60, child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [theme.primary.withOpacity(0.3), Colors.transparent], radius: 0.6)))),
                  Positioned(top: 150, right: -120, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [theme.secondary.withOpacity(0.25), Colors.transparent], radius: 0.6)))),
                  Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Container(color: theme.background.withOpacity(0.4)))),

                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER PROFILE
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())), child: Row(children: [Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme.surface, width: 2), image: DecorationImage(image: NetworkImage(photoURL), fit: BoxFit.cover), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)])), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_getGreeting(), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)), Row(children: [Text(displayName, style: GoogleFonts.plusJakartaSans(fontSize: 18, color: theme.textMain, fontWeight: FontWeight.w800)), if (isPro) ...[const SizedBox(width: 6), const Icon(Icons.verified, color: Colors.blue, size: 16)]])])])),
                              Row(children: [
                                GestureDetector(onTap: () => _showThemePicker(context), child: Container(width: 42, height: 42, decoration: BoxDecoration(color: theme.surface.withOpacity(0.8), shape: BoxShape.circle, border: Border.all(color: theme.surface), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Icon(Icons.palette_rounded, color: theme.primary, size: 20))),
                                const SizedBox(width: 12),
                                GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage())), child: Container(width: 42, height: 42, decoration: BoxDecoration(color: theme.surface.withOpacity(0.8), shape: BoxShape.circle, border: Border.all(color: theme.surface), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Stack(alignment: Alignment.center, children: [Icon(Icons.notifications_none_rounded, color: theme.textMain.withOpacity(0.8)), Positioned(top: 10, right: 10, child: CircleAvatar(radius: 3.5, backgroundColor: Colors.redAccent))]))),
                              ]),
                            ]),
                          ),
                          const SizedBox(height: 12),

                          // HERO SLIDER
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('promos').where('isActive', isEqualTo: true).orderBy('createdAt', descending: true).limit(5).snapshots(),
                            builder: (context, snapshot) {
                              List<Widget> hardcodedBanners = [
                                _buildImageBanner('https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=800', 'New Member Deal', '50% OFF Deep Clean', theme.primary),
                                _buildImageBanner('https://images.unsplash.com/photo-1616401784845-180882ba9ba8?q=80&w=800', 'Free Pickup & Delivery', 'Min. order \$30', theme.secondary),
                                _buildImageBanner('https://images.unsplash.com/photo-1512314889357-e157c22f938d?q=80&w=800', 'Express 24H', 'Get it back tomorrow.', Colors.indigo),
                              ];
                              List<Widget> firebaseBanners = [];
                              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                for (var doc in snapshot.data!.docs) {
                                  var data = doc.data() as Map<String, dynamic>;
                                  firebaseBanners.add(_buildImageBanner(data['imageUrl'] ?? 'https://via.placeholder.com/800x400', data['title'] ?? 'Promo Spesial', data['description'] ?? 'Cek sekarang!', theme.primary));
                                }
                              }
                              List<Widget> finalBanners = [...firebaseBanners, ...hardcodedBanners];
                              WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _totalBanners = finalBanners.length; });

                              return Column(
                                children: [
                                  SizedBox(height: 180, child: PageView(controller: _bannerController, onPageChanged: (index) => setState(() => _currentBannerIndex = index), children: finalBanners)),
                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(finalBanners.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), width: _currentBannerIndex == index ? 24 : 6, height: 6, decoration: BoxDecoration(color: _currentBannerIndex == index ? theme.primary : Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(3))))),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // MENU LAYANAN
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Our Services', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                                const SizedBox(height: 16),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.7,
                                  children: [
                                    _buildLottieServiceItem('water_drop.json', 'Deep Clean', theme, Colors.blue, Icons.water_drop_rounded, () => _navigateToService(context, 'Deep Clean')),
                                    _buildLottieServiceItem('Stopwatch.json', 'Fast Clean', theme, Colors.orange, Icons.timer_rounded, () => _navigateToService(context, 'Fast Clean')),
                                    _buildLottieServiceItem('sparkle.json', 'Unyellow', theme, Colors.amber, Icons.wb_sunny_rounded, () => _navigateToService(context, 'Unyellowing')),
                                    _buildLottieServiceItem('wrench.json', 'Repair', theme, Colors.grey, Icons.build_rounded, () => _navigateToService(context, 'Repair')),
                                    _buildLottieServiceItem('paint.json', 'Repaint', theme, Colors.purple, Icons.format_paint_rounded, () => _navigateToService(context, 'Repaint')),
                                    _buildLottieServiceItem('umbrella.json', 'Waterproof', theme, Colors.teal, Icons.umbrella_rounded, () => _navigateToService(context, 'Waterproof')),
                                    _buildLottieServiceItem('pencil.json', 'Custom', theme, Colors.pink, Icons.design_services_rounded, () => _navigateToService(context, 'Custom Painting')),
                                    _buildLottieServiceItem('delivery.json', 'Pickup', theme, Colors.green, Icons.local_shipping_rounded, () => _navigateToService(context, 'Pickup Service')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- KONDISI TAMPILAN BANNER PRO ---
                          if (!isPro) ...[
                            _buildChupatuPro(theme),
                            const SizedBox(height: 24),
                          ],

                          // LIVE TRACKING
                          LiveTrackingWidget(userId: user!.uid, theme: theme),

                          const SizedBox(height: 24),

                          // mini garage
                          MiniGarageWidget(theme: theme),

                          // MAGIC RESULTS
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Magic Results ✨', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                              const SizedBox(height: 12),
                              SizedBox(height: 240, child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: [
                                AutoMagicCard(beforeUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=600', afterUrl: 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?q=80&w=600', title: 'Nike Air Force 1', theme: theme, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MagicResultDetailPage(title: 'Nike Air Force 1', beforeImg: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=600', afterImg: 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?q=80&w=600')))),
                                const SizedBox(width: 16),
                                AutoMagicCard(beforeUrl: 'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?q=80&w=600', afterUrl: 'https://images.unsplash.com/photo-1515955656352-a1fa3ffcd111?q=80&w=600', title: 'Jordan Repaint', theme: theme, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MagicResultDetailPage(title: 'Jordan Repaint', beforeImg: 'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?q=80&w=600', afterImg: 'https://images.unsplash.com/photo-1515955656352-a1fa3ffcd111?q=80&w=600')))),
                              ])),
                            ]),
                          ),

                          const SizedBox(height: 30),

                          // SHOE TIPS
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tips Merawat Sepatu 💡', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                                const SizedBox(height: 12),
                                ShoeTipsWidget(theme: theme),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // TESTIMONI
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Happy Customers ❤️', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                                const SizedBox(height: 12),
                                _buildTestimonials(theme),
                              ],
                            ),
                          ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),

                  if (_showFloatingPromo) Positioned(bottom: 100, left: 20, right: 20, child: Dismissible(key: const Key('promo'), onDismissed: (_) => setState(() => _showFloatingPromo = false), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: const Color(0xFF1E1E2C).withOpacity(0.95), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]), child: Row(children: [const Icon(Icons.local_offer_rounded, color: Color(0xFFFFD700), size: 24), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('Promo Gajian!', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), Text('Diskon 30% semua layanan hari ini.', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12))])), IconButton(icon: const Icon(Icons.close, color: Colors.white54, size: 18), onPressed: () => setState(() => _showFloatingPromo = false))])))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- HELPER METHODS ---
  void _navigateToService(BuildContext context, String serviceName) {
    int price = 0;
    String description = "";
    String imageUrl = "https://images.unsplash.com/photo-1542291026-7eec264c27ff";

    if (serviceName == 'Deep Clean') { price = 40000; description = "Perawatan cuci sepatu secara menyeluruh untuk semua jenis bahan."; imageUrl = "https://images.unsplash.com/photo-1595341888016-a392ef81b7de?q=80&w=800"; }
    else if (serviceName == 'Fast Clean') { price = 25000; description = "Pencucian cepat khusus bagian luar sepatu."; imageUrl = "https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?q=80&w=800"; }
    else { price = 30000; description = "Layanan perawatan sepatu profesional."; }

    Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailPage(serviceName: serviceName, price: price, description: description, imageUrl: imageUrl)));
  }

  Widget _buildLottieServiceItem(String fileName, String label, AppThemeData theme, Color itemColor, IconData fallbackIcon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(children: [Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: itemColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: itemColor.withOpacity(0.3)), boxShadow: [BoxShadow(color: itemColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]), child: Lottie.asset('assets/lottie/$fileName', fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(fallbackIcon, color: itemColor, size: 30)))), const SizedBox(height: 8), Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: theme.textMain))]));
  }

  Widget _buildChupatuPro(AppThemeData theme) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF9E6), Color(0xFFFDF4D4)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)), boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))]), child: Row(children: [Container(height: 60, width: 60, padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]), child: Lottie.asset('assets/lottie/trophy.json', fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.emoji_events, color: Color(0xFFD4AF37), size: 30))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Join Chupatu Pro', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0B0F19), fontWeight: FontWeight.w800, fontSize: 16)), Text('Priority service & Gold status.', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 12))])), AnimatedBuilder(animation: _upgradeAnimController, builder: (context, child) { double scale = 1.0 + (_upgradeAnimController.value * 0.1); double rotate = math.sin(_upgradeAnimController.value * math.pi * 2) * 0.05; return Transform.scale(scale: scale, child: Transform.rotate(angle: rotate, child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemberPaymentPage(onPaymentSuccess: (){}))), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))]), child: Text("Upgrade", style: GoogleFonts.plusJakartaSans(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12)))))); })])));
  }

  Widget _buildImageBanner(String imgUrl, String title, String subtitle, Color accentColor) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: accentColor.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
                children: [
                  Image.network(imgUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [accentColor.withOpacity(0.9), accentColor.withOpacity(0.2)]))),
                  Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(8)), child: Text('PROMO', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))), const SizedBox(height: 8), Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.95), fontSize: 12))]))
                ]
            )
        )
    );
  }

  Widget _buildTestimonials(AppThemeData theme) {
    final reviews = [
      {'name': 'Rizky Billar', 'rating': 5, 'text': 'Gila sih, Air Jordan gue yang udah kuning jadi putih lagi! Pelayanan cepet.', 'img': 'https://i.pravatar.cc/150?u=1'},
      {'name': 'Anya Geraldine', 'rating': 5, 'text': 'Suka banget sama wanginya, ga bau apek lagi. Bakal langganan terus disini.', 'img': 'https://i.pravatar.cc/150?u=2'},
      {'name': 'Deddy C.', 'rating': 4, 'text': 'Pickup service nya membantu banget buat yg sibuk. Hasilnya solid.', 'img': 'https://i.pravatar.cc/150?u=3'},
    ];
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal, clipBehavior: Clip.none, itemCount: reviews.length, separatorBuilder: (c, i) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          var item = reviews[index];
          int rating = item['rating'] as int;
          return Container(width: 280, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [CircleAvatar(radius: 16, backgroundImage: NetworkImage(item['img'] as String)), const SizedBox(width: 10), Expanded(child: Text(item['name'] as String, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textMain))), Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < rating ? Colors.amber : Colors.grey.shade300)))]), const SizedBox(height: 12), Text('"${item['text']}"', maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic))]));
        },
      ),
    );
  }
}