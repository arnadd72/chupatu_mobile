import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// --- TAMBAHAN IMPORT PENTING ---
import 'package:firebase_auth/firebase_auth.dart';     // Agar kenal FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // Agar kenal QuerySnapshot, Timestamp, FirebaseFirestore
// -------------------------------
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
            backgroundColor: theme.background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              title: Text(
                "Notifikasi",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              bottom: TabBar(
                indicatorColor: theme.primary,
                labelColor: theme.primary,
                unselectedLabelColor: Colors.grey,
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

  // --- WIDGET TAB 1: INFO & PROMO (REAL-TIME FIREBASE) ---
  Widget _buildInfoTab(AppThemeData theme) {
    // SEKARANG ERROR INI SUDAH HILANG KARENA IMPORT SUDAH ADA
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Login dulu bos"));

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
                Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("Belum ada notifikasi", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
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

            // Format Waktu Simpel
            String timeStr = "Baru saja";
            if (data['createdAt'] != null) {
              // ERROR TIMESTAMP JUGA SUDAH HILANG
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
                  color: isRead ? Colors.white : theme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
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
                              Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                              Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
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
    // Kita pakai ChatRoomPage langsung untuk demo User ke Admin
    // Di aplikasi real, ini harusnya list chat. Tapi karena user cuma chat sama 1 admin:
    final user = FirebaseAuth.instance.currentUser;
    if(user == null) return const SizedBox();

    return ChatRoomPage(name: "Admin Pusat", isOnline: true);
  }
}