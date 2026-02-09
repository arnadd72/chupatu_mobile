import 'dart:async';
import 'dart:ui'; // Untuk ImageFilter
import 'dart:math' as math; // Untuk animasi goyang
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:chupatu_mobile/main.dart'; 
import 'package:chupatu_mobile/pages/profile/profile_page.dart';

// --- IMPORT HALAMAN LAYANAN ---
import 'package:chupatu_mobile/pages/order/service_detail_page.dart'; 
import 'package:chupatu_mobile/pages/home/widgets/auto_magic_card.dart';
import 'package:chupatu_mobile/pages/home/magic_result_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  bool _showFloatingPromo = true;

  // Controller untuk Animasi Tombol Upgrade
  late AnimationController _upgradeAnimController;
  
  // Data User dari Firebase Auth
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkUserData();

    // Auto Slide Banner
    Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentBannerIndex < 3) {
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

    // Animasi Tombol Upgrade
    _upgradeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  // --- LOGIC SAPAAN DINAMIS (WAKTU REAL-TIME) ---
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Good Morning,';
    } else if (hour < 15) {
      return 'Good Afternoon,';
    } else if (hour < 19) {
      return 'Good Evening,';
    } else {
      return 'Good Night,';
    }
  }

  Future<void> _checkUserData() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (!doc.exists || (doc.data()?['phone'] == null) || (doc.data()?['address'] == null)) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _showCompleteProfileDialog();
    }
  }

  void _showCompleteProfileDialog() {
    final theme = ThemeConfig.currentTheme.value;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 120,
                child: Lottie.asset('assets/lottie/pencil.json', fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(Icons.edit, size: 60, color: theme.primary)),
              ),
              const SizedBox(height: 16),
              Text("Lengkapi Profilmu", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textMain), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text("Halo ${user?.displayName?.split(' ')[0] ?? 'Kak'}! Agar kurir kami tidak nyasar, yuk lengkapi data dulu.", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())); }, style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text("Isi Data Sekarang", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)))),
              const SizedBox(height: 12),
              GestureDetector(onTap: () => Navigator.pop(context), child: Text("Nanti Saja", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontWeight: FontWeight.w600))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _upgradeAnimController.dispose();
    super.dispose();
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("Select App Theme", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: List.generate(ThemeConfig.themes.length, (index) {
                  final theme = ThemeConfig.themes[index];
                  return GestureDetector(onTap: () { ThemeConfig.changeTheme(index); Navigator.pop(context); }, child: Container(margin: const EdgeInsets.symmetric(horizontal: 8), child: Column(children: [Container(width: 60, height: 60, decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2), boxShadow: [BoxShadow(color: theme.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]), child: ThemeConfig.currentTheme.value == theme ? const Icon(Icons.check, color: Colors.white) : null), const SizedBox(height: 8), Text(theme.name, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600))])));
                }))), const SizedBox(height: 20)]),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
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
                      // HEADER
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
                              child: Row(children: [
                                  Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme.surface, width: 2), image: DecorationImage(image: NetworkImage(user?.photoURL ?? 'https://i.pravatar.cc/150'), fit: BoxFit.cover), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)])),
                                  const SizedBox(width: 12),
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      // GREETING DINAMIS
                                      Text(_getGreeting(), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                                      Text(user?.displayName ?? 'Guest', style: GoogleFonts.plusJakartaSans(fontSize: 18, color: theme.textMain, fontWeight: FontWeight.w800)),
                                    ]),
                                ]),
                            ),
                            Row(children: [
                                GestureDetector(onTap: () => _showThemePicker(context), child: Container(width: 42, height: 42, decoration: BoxDecoration(color: theme.surface.withOpacity(0.8), shape: BoxShape.circle, border: Border.all(color: theme.surface), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Icon(Icons.palette_rounded, color: theme.primary, size: 20))),
                                const SizedBox(width: 12),
                                Container(width: 42, height: 42, decoration: BoxDecoration(color: theme.surface.withOpacity(0.8), shape: BoxShape.circle, border: Border.all(color: theme.surface), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Stack(alignment: Alignment.center, children: [Icon(Icons.notifications_none_rounded, color: theme.textMain.withOpacity(0.8)), Positioned(top: 10, right: 10, child: CircleAvatar(radius: 3.5, backgroundColor: Colors.redAccent))])),
                              ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // HERO SLIDER
                      SizedBox(height: 180, child: PageView(controller: _bannerController, onPageChanged: (index) => setState(() => _currentBannerIndex = index), children: [_buildImageBanner('https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=800&auto=format&fit=crop', 'New Member Deal', '50% OFF Deep Clean', theme.primary), _buildImageBanner('https://images.unsplash.com/photo-1616401784845-180882ba9ba8?q=80&w=800&auto=format&fit=crop', 'Free Pickup & Delivery', 'Min. order \$30', theme.secondary), _buildImageBanner('https://images.unsplash.com/photo-1512314889357-e157c22f938d?q=80&w=800&auto=format&fit=crop', 'Express 24H', 'Get it back tomorrow.', Colors.indigo)])),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), width: _currentBannerIndex == index ? 24 : 6, height: 6, decoration: BoxDecoration(color: _currentBannerIndex == index ? theme.primary : Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(3))))),
                      const SizedBox(height: 16),

                      // --- MENU LAYANAN (NAVIGASI) ---
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
                                // NAVIGASI KE ServiceDetailPage dengan parameter berbeda
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
                      _buildChupatuPro(theme),
                      const SizedBox(height: 24),
                      
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Live Tracking', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)), Text('Order #8821', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: theme.primary, fontWeight: FontWeight.bold))]), const SizedBox(height: 12), Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))], border: Border.all(color: theme.surface.withOpacity(0.5))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.local_laundry_service_rounded, color: theme.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Nike Dunk Low Panda', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: theme.textMain, fontWeight: FontWeight.bold)), Text('Deep Clean • Express', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text("Washing", style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)))]), const SizedBox(height: 20), Row(children: [_buildStepLine(true, theme.primary), _buildStepLine(true, Colors.orange), _buildStepLine(false, Colors.grey.shade300), _buildStepLine(false, Colors.grey.shade300)])]))])),
                      
                      const SizedBox(height: 24),

                      // --- MAGIC RESULTS ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Magic Results ✨', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 240, 
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                clipBehavior: Clip.none,
                                children: [
                                  AutoMagicCard(
                                    beforeUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=600&auto=format&fit=crop', 
                                    afterUrl: 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?q=80&w=600&auto=format&fit=crop',  
                                    title: 'Nike Air Force 1',
                                    theme: theme, 
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const MagicResultDetailPage(
                                            title: 'Nike Air Force 1',
                                            beforeImg: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=600&auto=format&fit=crop',
                                            afterImg: 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?q=80&w=600&auto=format&fit=crop',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  const SizedBox(width: 16),

                                  AutoMagicCard(
                                    beforeUrl: 'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?q=80&w=600&auto=format&fit=crop',
                                    afterUrl: 'https://images.unsplash.com/photo-1515955656352-a1fa3ffcd111?q=80&w=600&auto=format&fit=crop',
                                    title: 'Jordan High Repaint',
                                    theme: theme,
                                    onTap: () {
                                       Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const MagicResultDetailPage(
                                            title: 'Jordan High Repaint',
                                            beforeImg: 'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?q=80&w=600&auto=format&fit=crop',
                                            afterImg: 'https://images.unsplash.com/photo-1515955656352-a1fa3ffcd111?q=80&w=600&auto=format&fit=crop',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // --- MY COLLECTION ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('My Collection', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                            const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            _buildMiniGarageItem('Dunk Panda', 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=1000&auto=format&fit=crop', theme),
                            const SizedBox(width: 12),
                            _buildMiniGarageItem('Yeezy 350', 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?q=80&w=1000&auto=format&fit=crop', theme),
                            const SizedBox(width: 12),
                            Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: theme.surface.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_circle_outline_rounded, color: theme.primary, size: 28),
                                    const SizedBox(height: 4),
                                    Text('Add Shoe', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              
              if (_showFloatingPromo) Positioned(bottom: 100, left: 20, right: 20, child: Dismissible(key: const Key('promo'), onDismissed: (_) => setState(() => _showFloatingPromo = false), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: const Color(0xFF1E1E2C).withOpacity(0.95), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]), child: Row(children: [const Icon(Icons.local_offer_rounded, color: Color(0xFFFFD700), size: 24), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('Promo Gajian!', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), Text('Diskon 30% semua layanan hari ini.', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12))])), IconButton(icon: const Icon(Icons.close, color: Colors.white54, size: 18), onPressed: () => setState(() => _showFloatingPromo = false))])))),
              
              // NAVBAR
              Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.only(top: 10, bottom: 20), decoration: BoxDecoration(color: theme.surface.withOpacity(0.95), borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildNavItem(0, Icons.home_rounded, 'Home', theme.primary), _buildNavItem(1, Icons.inventory_2_rounded, 'Garage', theme.primary), GestureDetector(onTap: () {}, child: Container(width: 56, height: 56, decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: theme.primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]), child: const Icon(Icons.add_rounded, color: Colors.white, size: 32))), _buildNavItem(2, Icons.receipt_long_rounded, 'Orders', theme.primary), GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_rounded, color: Colors.grey.shade400, size: 26), const SizedBox(height: 4), Text('Akun', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade400))]))]))),
            ],
          ),
        );
      },
    );
  }

  // --- HELPER FUNCTION UNTUK NAVIGASI ---
  void _navigateToService(BuildContext context, String serviceName) {
    // Navigasi ke halaman detail layanan yang sama, tapi datanya beda
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => ServiceDetailPage(serviceName: serviceName)
      )
    );
  }

  // --- WIDGET LAINNYA ---
  Widget _buildLottieServiceItem(String fileName, String label, AppThemeData theme, Color itemColor, IconData fallbackIcon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // Sekarang bisa diklik!
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: itemColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: itemColor.withOpacity(0.3)), boxShadow: [BoxShadow(color: itemColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]),
              child: Lottie.asset('assets/lottie/$fileName', fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(fallbackIcon, color: itemColor, size: 30)),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: theme.textMain)),
        ],
      ),
    );
  }

  Widget _buildChupatuPro(AppThemeData theme) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF9E6), Color(0xFFFDF4D4)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)), boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))]), child: Row(children: [Container(height: 60, width: 60, padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]), child: Lottie.asset('assets/lottie/trophy.json', fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.emoji_events, color: Color(0xFFD4AF37), size: 30))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Join Chupatu Pro', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0B0F19), fontWeight: FontWeight.w800, fontSize: 16)), Text('Priority service & Gold status.', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 12))])), AnimatedBuilder(animation: _upgradeAnimController, builder: (context, child) { double scale = 1.0 + (_upgradeAnimController.value * 0.1); double rotate = math.sin(_upgradeAnimController.value * math.pi * 2) * 0.05; return Transform.scale(scale: scale, child: Transform.rotate(angle: rotate, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))]), child: Text("Upgrade", style: GoogleFonts.plusJakartaSans(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12))))); })])));
  }

  Widget _buildImageBanner(String imgUrl, String title, String subtitle, Color accentColor) { return Container(margin: const EdgeInsets.symmetric(horizontal: 24), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: accentColor.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))]), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(children: [Image.network(imgUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover), Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [accentColor.withOpacity(0.9), accentColor.withOpacity(0.2)]))), Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(8)), child: Text('PROMO', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))), const SizedBox(height: 8), Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.95), fontSize: 12))]))]))); }
  Widget _buildStepLine(bool isActive, Color activeColor) { return Expanded(child: Container(height: 6, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: isActive ? activeColor : Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(3)))); }
  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor) { bool isSelected = _selectedIndex == index; return GestureDetector(onTap: () => _onItemTapped(index), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: isSelected ? activeColor : Colors.grey.shade400, size: 26), const SizedBox(height: 4), Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? activeColor : Colors.grey.shade400))])); }
  
  // Widget helper untuk Magic Results dan Collection (missing in user snippet but present in previous file)


  Widget _buildMiniGarageItem(String title, String imgUrl, AppThemeData theme) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(imgUrl, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textMain)),
          )
        ],
      ),
    );
  }
}