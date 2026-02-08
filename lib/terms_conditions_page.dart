import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Tema (Konsisten dengan Login/Register Page)
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
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primaryBlue.withOpacity(0.3), Colors.transparent],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentCyan.withOpacity(0.3), Colors.transparent],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          // Glass Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.white.withOpacity(0.1)),
            ),
          ),

          // ============================================================
          // 2. KONTEN UTAMA
          // ============================================================
          SafeArea(
            child: Column(
              children: [
                // Header: Tombol Back & Judul
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                      const SizedBox(width: 16),
                      Text(
                        'Terms & Conditions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content Area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                          color: primaryBlue.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('1. Introduction', primaryBlue),
                              _buildSectionContent(
                                'Welcome to Chupatu! These Terms and Conditions govern your use of our shoe cleaning services. By using our app, you agree to these terms.'
                              ),
                              const SizedBox(height: 20),

                              _buildSectionTitle('2. Services Provided', primaryBlue),
                              _buildSectionContent(
                                'Chupatu provides premium shoe cleaning, repair, and restoration services. We strive to deliver the best results, but the outcome may vary based on the shoe condition.'
                              ),
                              const SizedBox(height: 20),

                              _buildSectionTitle('3. User Responsibilities', primaryBlue),
                              _buildSectionContent(
                                'You agree to provide accurate information regarding your shoes and any specific cleaning requirements. You represent that you are the owner of the shoes submitted.'
                              ),
                              const SizedBox(height: 20),
                              
                              _buildSectionTitle('4. Payments', primaryBlue),
                              _buildSectionContent(
                                'All payments are processed securely. Prices are final and non-refundable once the service has commenced.'
                              ),
                              const SizedBox(height: 20),

                              _buildSectionTitle('5. Liability', primaryBlue),
                              _buildSectionContent(
                                'While we take utmost care, Chupatu is not liable for pre-existing damage or wear and tear that becomes apparent after cleaning.'
                              ),
                              const SizedBox(height: 20),

                              _buildSectionTitle('6. Changes to Terms', primaryBlue),
                              _buildSectionContent(
                                'We reserve the right to modify these terms at any time. Continued use of the service constitutes acceptance of the new terms.'
                              ),
                              
                              const SizedBox(height: 40),
                              Center(
                                child: Text(
                                  'Last Updated: October 2023',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        content,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
          height: 1.6,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
