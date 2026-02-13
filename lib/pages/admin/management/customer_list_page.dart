import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerListPage extends StatelessWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Data Pelanggan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: Colors.black)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade50,
                  backgroundImage: data['photoURL'] != null ? NetworkImage(data['photoURL']) : null,
                  child: data['photoURL'] == null ? const Icon(Icons.person, color: Colors.purple) : null,
                ),
                title: Text(data['displayName'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['email'] ?? '-', style: const TextStyle(color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Nanti bisa ditambah detail user
                },
              );
            },
          );
        },
      ),
    );
  }
}