import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Wajib ada
import 'firebase_options.dart'; // File hasil konfigurasi CLI tadi
import 'booking_page.dart';
import 'login_page.dart';
import 'landing_page.dart'; // Import LandingPage

void main() async {
  // 1. Pastikan binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Firebase dengan opsi otomatis dari CLI
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ChupatuApp());
}

class ChupatuApp extends StatelessWidget {
  const ChupatuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chupatu Mobile',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      // Aplikasi akan selalu dimulai dari halaman Landing Page
      home: const LandingPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chupatu Mobile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Saldo/Poin Chupatu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, Pelanggan!',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'Poin Kamu: 150',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Utama Booking
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.blue.shade50,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookingPage()),
                );
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text(
                'Mulai Booking Cuci Sekarang',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 25),
            const Text(
              'Layanan Kami',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Grid Menu Layanan
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildMenuCard(
                  context,
                  Icons.cleaning_services,
                  'Deep Clean',
                  'Rp 35.000',
                ),
                _buildMenuCard(
                  context,
                  Icons.wb_sunny,
                  'Unyellowing',
                  'Rp 50.000',
                ),
                _buildMenuCard(context, Icons.build, 'Repair', 'Rp 75.000'),
                _buildMenuCard(
                  context,
                  Icons.local_shipping,
                  'Antar Jemput',
                  'Gratis*',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    String price,
  ) {
    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookingPage()),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(price, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
