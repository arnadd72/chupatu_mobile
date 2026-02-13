import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageServicesPage extends StatelessWidget {
  const ManageServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kelola Layanan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Tambah Layanan (Coming Soon)")));
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Kita anggap nanti Anda simpan data layanan di collection 'services'
        // Jika belum ada, list ini akan kosong.
        stream: FirebaseFirestore.instance.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // JIKA DATA KOSONG (Karna belum input ke firebase), TAMPILKAN DUMMY DULU
          if (snapshot.data!.docs.isEmpty) {
            return _buildDummyList();
          }

          var docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return _buildServiceCard(data['name'] ?? 'Layanan', data['price'] ?? 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildDummyList() {
    // List Sementara biar gak kosong melompong saat didemo
    final services = [
      {'name': 'Deep Clean', 'price': 35000},
      {'name': 'Fast Clean', 'price': 25000},
      {'name': 'Unyellowing', 'price': 50000},
      {'name': 'Repaint', 'price': 120000},
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildServiceCard(services[index]['name'] as String, services[index]['price'] as int),
    );
  }

  Widget _buildServiceCard(String name, int price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.cleaning_services, color: Colors.blue)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)), Text("Rp $price", style: GoogleFonts.plusJakartaSans(color: Colors.grey))])),
          IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: (){}),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: (){}),
        ],
      ),
    );
  }
}