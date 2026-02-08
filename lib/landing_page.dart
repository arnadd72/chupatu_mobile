import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Data Onboarding
  final List<Map<String, String>> _onboardingData = [
    {
      "image": "https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=1000&auto=format&fit=crop",
      "title": "Revive Your Sole",
      "desc": "Premium cleaning that restores factory freshness to your favorite kicks."
    },
    {
      "image": "https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?q=80&w=1000&auto=format&fit=crop",
      "title": "Fast Delivery",
      "desc": "Sit back and relax. We pick up and deliver your shoes straight to your door."
    },
    {
      "image": "https://images.unsplash.com/photo-1549298916-b41d501d3772?q=80&w=1000&auto=format&fit=crop",
      "title": "Best Quality",
      "desc": "We use premium materials and techniques to ensure your shoes look brand new."
    },
  ];

  void _nextPage() {
    if (_currentIndex < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0606F9);
    const Color accentCyan = Color(0xFF00D4FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // ============================================================
          // 1. REVOLUTIONARY BACKGROUND (Mesh Gradient)
          // ============================================================
          Positioned(
            top: -50,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primaryBlue.withOpacity(0.3), Colors.transparent],
                  radius: 0.6,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentCyan.withOpacity(0.3), Colors.transparent],
                  radius: 0.6,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.white.withOpacity(0.1)),
            ),
          ),

          // ============================================================
          // 2. KONTEN UTAMA
          // ============================================================
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 60),

              // SLIDER GAMBAR
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(_onboardingData[index]['image']!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Floating Badge (Gradient)
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF0F2F5)]),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                                        ],
                                      ),
                                      child: const Icon(Icons.auto_awesome_rounded, color: primaryBlue, size: 22),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // INDIKATOR DOTS (Gradient Colors)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingData.length,
                  (dotIndex) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 8),
                    width: _currentIndex == dotIndex ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: _currentIndex == dotIndex 
                          ? const LinearGradient(colors: [primaryBlue, accentCyan])
                          : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // BOTTOM CARD (White with Top Gradient Border hint)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(color: primaryBlue.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, -10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Teks Animasi
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return SlideTransition(
                          position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(animation),
                          child: child,
                        );
                      },
                      child: Container(
                        key: ValueKey<int>(_currentIndex),
                        child: Column(
                          children: [
                            Text(
                              _onboardingData[_currentIndex]['title']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0B0F19),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _onboardingData[_currentIndex]['desc']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 28),

                    // BUTTON: GRADIENT GLOW
                    Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [primaryBlue, accentCyan],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _nextPage,
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _currentIndex == _onboardingData.length - 1 ? 'Get Started' : 'Next Step',
                                  key: ValueKey<String>(_currentIndex == _onboardingData.length - 1 ? 'start' : 'next'),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account? ", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500)),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                          },
                          child: Text("Sign In", style: GoogleFonts.plusJakartaSans(color: primaryBlue, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // HEADER (Logo & Skip)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                         // 1. Gambar Logo
                        Image.asset(
                          'assets/images/Login.png', // Pastikan nama file dan ekstensi sama persis
                          height: 32,
                           errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.checkroom_rounded,
                            color: primaryBlue, // Pakai kode warna langsung biar aman
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Chupatu', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0B0F19))),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      },
                      child: Text('Skip', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}