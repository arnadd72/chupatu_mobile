import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FinanceReportPage extends StatelessWidget {
  const FinanceReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: Text("Laporan Keuangan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: Colors.black)),
      body: StreamBuilder<QuerySnapshot>(
        // Hanya ambil yang statusnya DONE
        stream: FirebaseFirestore.instance.collection('bookings').where('status', isEqualTo: 'Done').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;

          // Hitung Total
          int totalRevenue = docs.fold(0, (sum, doc) => sum + ((doc.data() as Map)['totalPrice'] as int? ?? 0));

          return Column(
            children: [
              // CARD TOTAL
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.green, Colors.teal]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
                child: Column(
                  children: [
                    const Text("Total Pendapatan Bersih", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(currencyFormatter.format(totalRevenue), style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text("${docs.length} Transaksi Selesai", style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: const Icon(Icons.attach_money, color: Colors.green)),
                      title: Text(data['serviceName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['customerName'] ?? 'User'),
                      trailing: Text(currencyFormatter.format(data['totalPrice'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}