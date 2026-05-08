import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/notification/chat_room_page.dart';

class CustomerChatPage extends StatelessWidget {
  const CustomerChatPage({super.key});

  Future<void> _openCSChat(BuildContext context, User user) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      var existingChat = await FirebaseFirestore.instance
          .collection('chats')
          .where('userId', isEqualTo: user.uid)
          .where('adminName', isEqualTo: 'CS Chupatu Pusat')
          .limit(1).get();

      String chatId;
      if (existingChat.docs.isNotEmpty) {
        chatId = existingChat.docs.first.id;
      } else {
        var newChat = await FirebaseFirestore.instance.collection('chats').add({
          'userId': user.uid,
          'userName': user.displayName ?? 'Customer',
          'adminName': 'CS Chupatu Pusat',
          'lastMessage': 'Halo CS Chupatu, saya butuh bantuan.',
          'lastTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        });
        chatId = newChat.id;
      }
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomPage(chatId: chatId, name: "CS Chupatu Pusat", isOnline: true, isAdmin: false)));
      }
    } catch (e) {
      if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(title: Text("Pesan dan Bantuan", style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontWeight: FontWeight.bold)), backgroundColor: theme.surface, elevation: 0, iconTheme: IconThemeData(color: theme.textMain)),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 12), child: Text("Pesan Aktif", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textMain))),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('chats').where('userId', isEqualTo: user?.uid).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState(theme);
                      }

                      var docs = snapshot.data!.docs.toList();
                      docs.sort((a, b) {
                        Timestamp? tA = (a.data() as Map<String, dynamic>)['lastTime'] as Timestamp?;
                        Timestamp? tB = (b.data() as Map<String, dynamic>)['lastTime'] as Timestamp?;
                        if (tA == null) return 1;
                        if (tB == null) return -1;
                        return tB.compareTo(tA);
                      });

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          String chatTitle = data['adminName'] ?? 'Admin Chupatu';
                          String lastMessage = data['lastMessage'] ?? 'Mengirim file...';
                          int unread = data['unreadCount'] ?? 0; // JUMLAH PESAN MASUK

                          String timeStr = "";
                          if (data['lastTime'] != null) {
                            DateTime date = (data['lastTime'] as Timestamp).toDate();
                            timeStr = DateFormat('HH:mm').format(date);
                          }
                          IconData avatarIcon = chatTitle.contains('CS') ? Icons.support_agent_rounded : Icons.admin_panel_settings_rounded;

                          return InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomPage(chatId: docs[index].id, name: chatTitle, isOnline: true, isAdmin: false))),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // FOTO AVATAR
                                  CircleAvatar(radius: 26, backgroundColor: theme.primary.withOpacity(0.1), child: Icon(avatarIcon, color: theme.primary, size: 28)),
                                  const SizedBox(width: 16),

                                  // BAGIAN TENGAH (NAMA & PESAN TERAKHIR)
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(chatTitle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)),
                                            const SizedBox(height: 4),
                                            Text(
                                                lastMessage,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 13,
                                                    color: unread > 0 ? theme.textMain : Colors.grey,
                                                    fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal
                                                )
                                            ),
                                          ]
                                      )
                                  ),

                                  const SizedBox(width: 8),

                                  // BAGIAN KANAN (WAKTU & BADGE WHATSAPP STYLE)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: unread > 0 ? theme.primary : Colors.grey, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal)),
                                      const SizedBox(height: 6),
                                      if (unread > 0)
                                        Container(
                                            alignment: Alignment.center,
                                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(10)),
                                            child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                                        )
                                      else
                                        const SizedBox(height: 20), // Placeholder biar tinggi tetep konsisten
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text("Pertanyaan Umum (FAQ)", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textMain))),
                  const SizedBox(height: 12),
                  _buildFAQSection(theme),
                  const SizedBox(height: 32),
                  _buildCSButton(context, theme, user),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildEmptyState(AppThemeData theme) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1))), child: Column(children: [Icon(Icons.forum_outlined, size: 40, color: Colors.grey.shade400), const SizedBox(height: 12), Text("Belum ada pesan aktif.", style: GoogleFonts.plusJakartaSans(color: Colors.grey))])));
  }

  Widget _buildFAQSection(AppThemeData theme) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1))), child: Column(children: [_buildFAQItem("Berapa lama proses cuci?", "Fast Clean 1 hari, Deep Clean 3-5 hari.", theme), _buildFAQItem("Ada garansi?", "Ya, kami menjamin keamanan sepatu Anda.", theme, isLast: true)])));
  }

  Widget _buildFAQItem(String q, String a, AppThemeData theme, {bool isLast = false}) {
    return Container(decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))), child: ExpansionTile(title: Text(q, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textMain)), children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(a, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade600)))]));
  }

  Widget _buildCSButton(BuildContext context, AppThemeData theme, User? user) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.primary.withOpacity(0.2))), child: Column(children: [Text("Butuh bantuan?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)), const SizedBox(height: 16), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => user != null ? _openCSChat(context, user) : null, icon: const Icon(Icons.support_agent_rounded), label: const Text("Hubungi Customer Service"), style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))))])));
  }
}