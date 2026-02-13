import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/pages/notification/chat_room_page.dart';

class AdminChatPage extends StatelessWidget {
  const AdminChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Pelanggan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').orderBy('lastTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Belum ada pesan masuk.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
          }

          var docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id; // INI ADALAH CHAT ID (KUNCI KAMAR)

              String userName = data['userName'] ?? 'User';
              String lastMsg = data['lastMessage'] ?? '-';

              // Format Waktu
              String timeStr = "";
              if (data['lastTime'] != null) {
                DateTime d = (data['lastTime'] as Timestamp).toDate();
                timeStr = "${d.hour}:${d.minute.toString().padLeft(2, '0')}";
              }

              return ListTile(
                onTap: () {
                  // SAAT DIKLIK, KITA KIRIM 'docId' (Chat ID) KE DALAM
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChatRoomPage(
                            name: userName,
                            isOnline: true,
                            chatId: docId, // <--- INI KUNCINYA (Supaya admin masuk ke kamar yang benar)
                            isAdmin: true, // <--- TANDAI SEBAGAI ADMIN
                          )
                      )
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : "U", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ),
                title: Text(userName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              );
            },
          );
        },
      ),
    );
  }
}