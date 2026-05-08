import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chupatu_mobile/pages/notification/chat_room_page.dart';

class AdminChatPage extends StatelessWidget {
  const AdminChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50, // Backgound sedikit abu biar card chat nonjol
        appBar: AppBar(
          title: Text("Pusat Pesan Admin", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            indicatorColor: Color(0xFFD4AF37), labelColor: Color(0xFFD4AF37), unselectedLabelColor: Colors.grey,
            tabs: [Tab(icon: Icon(Icons.shopping_bag_outlined), text: "Chat Pesanan"), Tab(icon: Icon(Icons.support_agent_rounded), text: "Chat CS")],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChatList(context, isCS: false),
            _buildChatList(context, isCS: true),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, {required bool isCS}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada pesan."));

        var allDocs = snapshot.data!.docs;
        var filteredDocs = allDocs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = data['adminName'] ?? 'Admin Chupatu';
          return isCS ? name.contains('CS') : !name.contains('CS');
        }).toList();

        filteredDocs.sort((a, b) {
          Timestamp? tA = (a.data() as Map<String, dynamic>)['lastTime'] as Timestamp?;
          Timestamp? tB = (b.data() as Map<String, dynamic>)['lastTime'] as Timestamp?;
          return (tB ?? Timestamp.now()).compareTo(tA ?? Timestamp.now());
        });

        if (filteredDocs.isEmpty) return const Center(child: Text("Belum ada pesan masuk."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var data = filteredDocs[index].data() as Map<String, dynamic>;
            String userName = data['userName'] ?? 'User';
            String lastMessage = data['lastMessage'] ?? '-';
            int unread = data['unreadCount'] ?? 0;

            String timeStr = "";
            if (data['lastTime'] != null) {
              DateTime d = (data['lastTime'] as Timestamp).toDate();
              timeStr = "${d.hour}:${d.minute.toString().padLeft(2, '0')}";
            }

            return InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomPage(name: userName, isOnline: true, chatId: filteredDocs[index].id, isAdmin: true))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // FOTO AVATAR PELANGGAN
                    CircleAvatar(
                        radius: 24,
                        backgroundColor: isCS ? Colors.orange.shade50 : Colors.blue.shade50,
                        child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : "U", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isCS ? Colors.orange : Colors.blue))
                    ),
                    const SizedBox(width: 16),

                    // TENGAH (NAMA & PESAN TERAKHIR)
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(userName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: unread > 0 ? Colors.black87 : Colors.grey.shade600,
                                      fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal
                                  )
                              ),
                            ]
                        )
                    ),

                    const SizedBox(width: 8),

                    // KANAN (WAKTU & BADGE MERAH WHATSAPP STYLE)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(timeStr, style: TextStyle(fontSize: 11, color: unread > 0 ? Colors.red : Colors.grey, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal)),
                        const SizedBox(height: 6),
                        if (unread > 0)
                          Container(
                              alignment: Alignment.center,
                              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                              child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                          )
                        else
                          const SizedBox(height: 20), // Placeholder agar layout tidak lompat
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}