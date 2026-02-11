import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Wajib untuk database
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chupatu_mobile/pages/auth/register_page.dart';
import 'package:chupatu_mobile/pages/auth/landing_page.dart';
import 'package:chupatu_mobile/pages/home/home_page.dart'; 
import 'package:chupatu_mobile/pages/admin/admin_home_page.dart';

import '../../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNGSI UTAMA: CEK ROLE & SIMPAN DATA ---
  Future<void> _checkRoleAndNavigate(User user) async {
    try {
      // 1. Referensi ke Dokumen User di Firestore
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      DocumentSnapshot doc = await userDoc.get();

      String role = 'user'; // Default role

      // 2. LOGIKA PENYIMPANAN DATA (FIX DATABASE KOSONG)
      // Kita pakai set(..., SetOptions(merge: true))
      // Artinya: Kalau belum ada, dibuatkan. Kalau sudah ada, diupdate (tanpa menghapus data lama).
      await userDoc.set({
        'email': user.email, // PAKSA SIMPAN EMAIL
        'displayName': user.displayName ?? 'User Tanpa Nama',
        'photoURL': user.photoURL,
        'lastLogin': DateTime.now(),
        // Jangan timpa role kalau sudah ada, tapi kalau belum ada set jadi 'user'
        'role': (doc.exists && (doc.data() as Map)['role'] != null) ? (doc.data() as Map)['role'] : 'user',
      }, SetOptions(merge: true));

      // 3. Ambil role terbaru untuk navigasi
      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        role = data?['role'] ?? 'user';
      }

      if (!mounted) return;

      // 4. Navigasi Sesuai Role
      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminHomePage()), (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Admin Berhasil 👮‍♂️'), backgroundColor: Colors.indigo));
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AuthWrapper()), (route) => false);
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Tampilkan error biar ketahuan kenapa
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal database: $e')));
      }
    }
  }

  // --- 1. LOGIC LOGIN EMAIL ---
  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Cek Role & Simpan Data sebelum pindah
      if (userCredential.user != null) {
        await _checkRoleAndNavigate(userCredential.user!);
      }

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = 'An error occurred';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'No user found or wrong password.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
        );
      }
    } catch (e) {
       setState(() => _isLoading = false);
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to server')),
        );
      }
    }
  }
  
  // --- 2. LOGIC LOGIN GOOGLE ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        // CLIENT ID (Sesuaikan jika perlu)
        clientId: '1017641487559-5olaoc5mdbdm8psf9v80roj4n9keio2n.apps.googleusercontent.com', 
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: null,
        );

        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        
        // Cek Role & Simpan Data sebelum pindah
        if (userCredential.user != null) {
          await _checkRoleAndNavigate(userCredential.user!);
        }
      } else {
        setState(() => _isLoading = false); // User cancel login
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0606F9); 
    const Color accentCyan = Color(0xFF00D4FF);
    const Color textDark = Color(0xFF0B0F19);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // Background Mesh Gradient
          Positioned(
            top: -100, left: -50,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primaryBlue.withOpacity(0.4), Colors.transparent],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100, right: -50,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentCyan.withOpacity(0.4), Colors.transparent],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.white.withOpacity(0.1)),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LandingPage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Login Card
                    Container(
                      padding: const EdgeInsets.all(2), 
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, primaryBlue, accentCyan],
                        ),
                        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.25), blurRadius: 40, offset: const Offset(0, 20))],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            // Logo
                            Container(
                              width: 70, height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: 40,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.checkroom_rounded, size: 40, color: primaryBlue),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            Text('Welcome Back!', style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
                            const SizedBox(height: 8),
                            Text('Please enter your details.', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),

                            const SizedBox(height: 32),

                            _buildModernInput(controller: _emailController, label: 'Email Address', icon: Icons.alternate_email_rounded, isObscure: false),
                            const SizedBox(height: 16),
                            _buildModernInput(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              isObscure: !_isPasswordVisible,
                              suffix: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey.shade400),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text('Forgot Password?', style: GoogleFonts.plusJakartaSans(color: primaryBlue, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ),

                            const SizedBox(height: 20),

                            _isLoading 
                            ? const CircularProgressIndicator(color: primaryBlue)
                            : Container(
                              width: double.infinity, height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(colors: [Color(0xFF0606F9), Color(0xFF00D4FF)]),
                                boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _login,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Center(child: Text('Sign In', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Google Button
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _signInWithGoogle,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                                        height: 24,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata),
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Continue with Google', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: textDark, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account? ", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                                  child: Text("Sign Up", style: GoogleFonts.plusJakartaSans(color: primaryBlue, fontWeight: FontWeight.w800, fontSize: 13)),
                                ),
                              ],
                            ),
                            
                            // TOMBOL AKSES ADMIN (SEMENTARA)
                            // Jika sudah implementasi role admin, tombol ini bisa dihapus/di-comment
                            // const SizedBox(height: 20),
                            // TextButton(
                            //   onPressed: () {
                            //     Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminHomePage()));
                            //   },
                            //   child: Text("(Dev Only) Masuk sebagai Admin", style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 12)),
                            // )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInput({required TextEditingController controller, required String label, required IconData icon, required bool isObscure, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0B0F19))),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.transparent),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
              suffixIcon: suffix,
              hintText: 'Enter your $label',
              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0606F9), width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
          ),
        ),
      ],
    );
  }
}