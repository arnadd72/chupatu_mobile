import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:chupatu_mobile/main.dart'; // Import AuthWrapper

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {

  // 1. Controller utk animasi Logo
  late AnimationController _logoController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoAuraAnimation;

  // 2. Controller utk animasi Teks ala Netflix
  late AnimationController _textController;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textLetterSpacingAnimation;

  bool _showText = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // --- LOGIKA LOGO MUNCUL (0s - 1.2s) ---
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Efek memantul pas logo muncul
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut)
    );

    // Efek aura emas muncul perlahan di belakang logo
    _logoAuraAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _logoController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeIn)
        )
    );

    // --- LOGIKA TEKS MEREGANG (1.0s - 2.5s) ---
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)
        )
    );

    // Efek spasi huruf mengecil (seperti ditarik)
    _textLetterSpacingAnimation = Tween<double>(begin: 30.0, end: 6.0).animate(
        CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)
        )
    );

    _runTimeline();
  }

  void _runTimeline() async {
    // 1. Mulai animasi logo
    _logoController.forward();

    // 2. Tunggu 800ms, lalu mulai animasi teks
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() { _showText = true; });
    _textController.forward();

    // 3. Pindah halaman dengan transisi halus (Fade) setelah 3 detik
    await Future.delayed(const Duration(seconds: 3));
    if(mounted) {
      Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (c, a1, a2) => const AuthWrapper(),
            transitionsBuilder: (c, a1, a2, child) =>
                FadeTransition(opacity: a1, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          )
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- TEMA WARNA SULTAN (PUTIH & GOLD) ---
    const Color goldColor = Color(0xFFD4AF37);
    const Color lightGold = Color(0xFFFBF5E6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- LAYER 1: BACKGROUND GRADIENT HALUS ---
          Container(
            decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [lightGold, Colors.white],
                  radius: 1.2,
                  center: Alignment.center,
                )
            ),
          ),

          // --- LAYER 2: LOGO CHUPATU & AURA EMAS ---
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Lingkaran Aura Glow
                    Opacity(
                      opacity: _logoAuraAnimation.value,
                      child: Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: goldColor.withOpacity(0.3), width: 2
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: goldColor.withOpacity(0.2),
                                  blurRadius: 40, spreadRadius: 10
                              )
                            ]
                        ),
                      ),
                    ),
                    // Tempat Taruh Logo Lo Nanti
                    ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: goldColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10, offset: const Offset(0, 5)
                            )
                          ], // <-- 1. INI KOMANYA UDAH DITAMBAHIN
                          image: const DecorationImage(
                            image: AssetImage('assets/images/welcome_logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ), // <-- 2. INI PENUTUP CONTAINER-NYA UDAH DIRAPIHIN
                    ),
                  ],
                );
              },
            ),
          ),

          // --- LAYER 3: TEKS GLASSMORPISM ---
          if (_showText)
            Positioned(
              bottom: 100, left: 0, right: 0,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFadeAnimation.value,
                    child: Center(
                      child: GlassmorphicContainer(
                        width: 320, height: 80,
                        borderRadius: 20,
                        linearGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.8),
                              Colors.white.withOpacity(0.4)
                            ]
                        ),
                        border: 1,
                        blur: 15,
                        borderGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              goldColor.withOpacity(0.5),
                              Colors.white.withOpacity(0.5)
                            ]
                        ),
                        child: Center(
                          // Teks Shimmer Emas & Putih
                          child: Shimmer.fromColors(
                            baseColor: goldColor,
                            highlightColor: Colors.white,
                            period: const Duration(seconds: 2),
                            child: Text(
                              "CHUPATU",
                              style: GoogleFonts.plusJakartaSans(
                                textStyle: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: goldColor,
                                  letterSpacing: _textLetterSpacingAnimation.value,
                                  shadows: [
                                    Shadow(
                                        color: goldColor.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2)
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}