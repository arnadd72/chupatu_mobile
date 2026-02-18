import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/notification/notification_detail_page.dart';
import 'package:chupatu_mobile/pages/notification/chat_room_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: theme.background, // Warna Background Tema
            appBar: AppBar(
              backgroundColor: theme.surface, // Warna Header Tema (Bukan Putih Lagi)
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain), // Ikon ikut warna teks tema
              title: Text(
                "Notifikasi",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: theme.textMain, // Teks ikut warna tema
                ),
              ),
              bottom: TabBar(
                indicatorColor: theme.primary,
                labelColor: theme.primary,
                unselectedLabelColor: theme.textMain.withOpacity(0.5), // Warna abu menyesuaikan tema
                labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Info & Promo"),
                  Tab(text: "Chat Admin"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildInfoTab(theme),
                _buildChatTab(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET TAB 1: INFO & PROMO ---
  Widget _buildInfoTab(AppThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Center(child: Text("Silakan login terlebih dahulu", style: TextStyle(color: theme.textMain)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 60, color: theme.textMain.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text("Belum ada notifikasi", style: GoogleFonts.plusJakartaSans(color: theme.textMain.withOpacity(0.5))),
              ],
            ),
          );
        }

        var docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;

            String title = data['title'] ?? 'Info Chupatu';
            String body = data['body'] ?? '';
            String type = data['type'] ?? 'info';
            bool isRead = data['isRead'] ?? false;

            String timeStr = "Baru saja";
            if (data['createdAt'] != null) {
              DateTime date = (data['createdAt'] as Timestamp).toDate();
              timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
            }

            return GestureDetector(
              onTap: () {
                docs[index].reference.update({'isRead': true});
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationDetailPage(
                      title: title,
                      body: body,
                      time: timeStr,
                      type: type,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Logic Warna Card:
                  // Kalau belum dibaca: Pakai warna Surface Tema (Terang/Gelap sesuai tema)
                  // Kalau sudah dibaca: Pakai warna Background Tema (Lebih redup/gelap)
                  color: isRead ? theme.background : theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.textMain.withOpacity(0.1)),
                  boxShadow: [
                    if (!isRead)
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: type == 'promo' ? Colors.orange.withOpacity(0.1) : theme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        type == 'promo' ? Icons.discount_rounded : Icons.local_shipping_rounded,
                        color: type == 'promo' ? Colors.orange : theme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain), overflow: TextOverflow.ellipsis)),
                              Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: theme.textMain.withOpacity(0.5))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: theme.textMain.withOpacity(0.7))),
                        ],
                      ),
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

  // --- WIDGET TAB 2: CHAT ADMIN ---
  Widget _buildChatTab(AppThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text("Silakan Login untuk Chat", style: TextStyle(color: theme.textMain)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 80, color: theme.textMain.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text("Belum ada riwayat chat", style: GoogleFonts.plusJakartaSans(color: theme.textMain.withOpacity(0.5))),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('chats').add({
                      'userId': user.uid,
                      'userName': user.displayName ?? 'Customer',
                      'lastMessage': 'Halo Admin, saya butuh bantuan.',
                      'lastTime': FieldValue.serverTimestamp(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text("Mulai Chat dengan Admin"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }

        String chatId = snapshot.data!.docs.first.id;

        return ChatRoomPage(
          chatId: chatId,
          name: "Admin Pusat",
          isOnline: true,
          isAdmin: false,
        );
      },
    );
  }
}