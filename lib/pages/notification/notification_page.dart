import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ====================================================================
// 1. HALAMAN DAFTAR NOTIFIKASI & PROMO (FULL SCREEN)
// ====================================================================
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.textMain),
            title: Text(
              "Info & Promo",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: theme.textMain,
              ),
            ),
          ),
          body: user == null
              ? Center(child: Text("Silakan login terlebih dahulu", style: TextStyle(color: theme.textMain)))
              : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              final isLoading = snapshot.connectionState == ConnectionState.waiting;
              if (!isLoading && (!snapshot.hasData || snapshot.data!.docs.isEmpty)) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 80, color: theme.textMain.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text("Belum ada notifikasi atau promo", style: GoogleFonts.plusJakartaSans(color: theme.textMain.withOpacity(0.5))),
                    ],
                  ),
                );
              }

              var docs = isLoading ? [] : snapshot.data!.docs;

              return Skeletonizer(
                enabled: isLoading,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: isLoading ? 4 : docs.length,
                  itemBuilder: (context, index) {
                    if (isLoading) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.textMain.withOpacity(0.05)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(width: 150, height: 14, color: Colors.grey.shade300),
                                  const SizedBox(height: 6),
                                  Container(width: double.infinity, height: 12, color: Colors.grey.shade300),
                                  const SizedBox(height: 4),
                                  Container(width: double.infinity, height: 12, color: Colors.grey.shade300),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
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
                            theme: theme, // Passing theme
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isRead ? theme.background : theme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.textMain.withOpacity(0.05)),
                        boxShadow: [
                          if (!isRead)
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: type == 'promo' ? Colors.orange.withOpacity(0.1) : theme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              type == 'promo' ? Icons.discount_rounded : Icons.local_shipping_rounded,
                              color: type == 'promo' ? Colors.orange : theme.primary,
                              size: 24,
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
                                    Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textMain), overflow: TextOverflow.ellipsis)),
                                    Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: theme.textMain.withOpacity(0.5))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: theme.textMain.withOpacity(0.7), height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              );
            },
          ),
        );
      },
    );
  }
}

// ====================================================================
// 2. HALAMAN DETAIL PROMO / NOTIF (DIGABUNG DI SINI BIAR RAPI)
// ====================================================================
class NotificationDetailPage extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final String type;
  final AppThemeData theme;

  const NotificationDetailPage({
    super.key,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor = type == 'promo' ? Colors.orange : theme.primary;
    IconData typeIcon = type == 'promo' ? Icons.discount_rounded : Icons.local_shipping_rounded;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Detail Info", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)),
        backgroundColor: theme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textMain),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: typeColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(typeIcon, color: typeColor, size: 40),
              ),
            ),
            const SizedBox(height: 24),

            Center(child: Text(time, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 12),

            Center(
              child: Text(title, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textMain)),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 16),

            Text(
              body,
              style: GoogleFonts.plusJakartaSans(fontSize: 15, color: theme.textMain.withOpacity(0.8), height: 1.6),
            ),

            const Spacer(),

            if (type == 'promo')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Balik ke halaman sebelumnya
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text("Gunakan Promo Sekarang", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}