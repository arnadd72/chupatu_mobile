import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart'; // For TapGestureRecognizer
import 'package:chupatu_mobile/terms_conditions_page.dart'; // For navigation
import 'package:chupatu_mobile/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false; // New state for terms checkbox

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // 1. Validation
    if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _phoneController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the Terms & Conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Create User in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 3. Save additional user details to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': 'customer', // Default role
            'points': 0, // Loyalty points start at 0
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration Successful! Please Login.'),
            backgroundColor: Colors.green.shade400,
          ),
        );
        // Navigate to Login Page after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to server')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definition of Theme Colors
    const Color primaryBlue = Color(0xFF0606F9);
    const Color accentCyan = Color(0xFF00D4FF);
    const Color textDark = Color(0xFF0B0F19);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // ============================================================
          // 1. REVOLUTIONARY BACKGROUND (Mesh Gradient)
          // ============================================================
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
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
            bottom: -100,
            left: -50,
            child: Container(
              width: 350,
              height: 350,
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

          // ============================================================
          // 2. MAIN CONTENT
          // ============================================================
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Header: Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                           Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ============================================================
                    // 3. REVOLUTIONARY GLASS CARD (Register Form)
                    // ============================================================
                    Container(
                      padding: const EdgeInsets.all(2), // Gradient Border width
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, primaryBlue, accentCyan],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.25),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            // Icon Header
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryBlue.withOpacity(0.1),
                              ),
                              child: const Icon(Icons.person_add_alt_1_rounded, color: primaryBlue, size: 30),
                            ),
                            const SizedBox(height: 16),
                            
                            Text(
                              'Create Account',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start your shoe care journey today.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // --- INPUT FIELDS ---
                            _buildModernInput(
                              controller: _nameController,
                              label: 'Full Name', 
                              icon: Icons.person_outline_rounded
                            ),
                            const SizedBox(height: 16),
                            _buildModernInput(
                              controller: _phoneController,
                              label: 'WhatsApp Number', 
                              icon: Icons.call_outlined, 
                              inputType: TextInputType.phone
                            ),
                            const SizedBox(height: 16),
                            _buildModernInput(
                              controller: _emailController,
                              label: 'Email Address', 
                              icon: Icons.alternate_email_rounded, 
                              inputType: TextInputType.emailAddress
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field
                            _buildModernInput(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              isObscure: !_isPasswordVisible,
                              suffix: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Terms Checkbox
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _agreedToTerms,
                                    activeColor: primaryBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'I agree to the ',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600),
                                      children: [
                                        TextSpan(
                                          text: 'Terms & Conditions',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryBlue,
                                            decoration: TextDecoration.underline,
                                            decorationColor: primaryBlue,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const TermsConditionsPage(),
                                                ),
                                              );
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // SIGN UP BUTTON (Gradient)
                            _isLoading 
                            ? const CircularProgressIndicator(color: primaryBlue)
                            : Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [primaryBlue, accentCyan],
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
                                  onTap: _signUp, // Hooked up the function
                                  borderRadius: BorderRadius.circular(20),
                                  child: Center(
                                    child: Text(
                                      'Sign Up',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Footer Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Already have an account? ", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 13)),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                                  },
                                  child: Text("Sign In", style: GoogleFonts.plusJakartaSans(color: primaryBlue, fontWeight: FontWeight.w800, fontSize: 13)),
                                ),
                              ],
                            ),
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

  // Widget Helper Input Modern
  Widget _buildModernInput({
    required TextEditingController controller, // Added controller parameter
    required String label,
    required IconData icon,
    bool isObscure = false,
    Widget? suffix,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0B0F19)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller, // Connected controller
            obscureText: isObscure,
            keyboardType: inputType,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
              suffixIcon: suffix,
              hintText: 'Enter your $label',
              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0606F9), width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.transparent)),
            ),
          ),
        ),
      ],
    );
  }
}