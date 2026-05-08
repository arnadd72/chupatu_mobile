import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/notification/chat_room_page.dart';

class CustomerChatPage extends StatelessWidget {
  const CustomerChatPage({super.key});

  Future<void> _openChat(
      BuildContext context, User user, String targetAdminName) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      var existingChat = await FirebaseFirestore.instance
          .collection('chats')
          .where('userId', isEqualTo: user.uid)
          .where('adminName', isEqualTo: targetAdminName)
          .limit(1)
          .get();

      String chatId;
      if (existingChat.docs.isNotEmpty) {
        chatId = existingChat.docs.first.id;
      } else {
        String initialMsg = targetAdminName.contains('CS')
            ? 'Halo CS Chupatu, saya butuh bantuan.'
            : 'Halo Admin, saya ingin bertanya soal pesanan.';

        var newChat = await FirebaseFirestore.instance.collection('chats').add({
          'userId': user.uid,
          'userName': user.displayName ?? 'Customer',
          'adminName': targetAdminName,
          'lastMessage': initialMsg,
          'lastTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'unreadAdmin': 1,
          'unreadUser': 0,
        });
        chatId = newChat.id;
      }

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatRoomPage(
                    chatId: chatId,
                    name: targetAdminName,
                    isOnline: true,
                    isAdmin: false)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal: $e")));
      }
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
            appBar: AppBar(
                title: Text("Pesan dan Bantuan",
                    style: GoogleFonts.plusJakartaSans(
                        color: theme.textMain, fontWeight: FontWeight.bold)),
                backgroundColor: theme.surface,
                elevation: 0,
                iconTheme: IconThemeData(color: theme.textMain)),
            body: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('userId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  bool hasAdminChat = false;
                  bool hasCSChat = false;
                  List<QueryDocumentSnapshot> activeChats = [];

                  if (snapshot.hasData) {
                    activeChats = snapshot.data!.docs.toList();
                    for (var doc in activeChats) {
                      String name = doc['adminName'] ?? '';
                      if (name == 'Admin Chupatu') hasAdminChat = true;
                      if (name == 'CS Chupatu Pusat') hasCSChat = true;
                    }
                    // Urutkan Pesan Aktif berdasarkan waktu
                    activeChats.sort((a, b) {
                      Timestamp? tA = (a.data() as Map<String, dynamic>)['lastTime'] as Timestamp?;
                      Timestamp? tB = (b.data() as Map<String, dynamic>)['lastTime'] as Timestamp?;
                      return (tB ?? Timestamp.now()).compareTo(tA ?? Timestamp.now());
                    });
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- BAGIAN 1: PESAN AKTIF ---
                        Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                            child: Text("Pesan Aktif",
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textMain))),

                        activeChats.isEmpty
                            ? _buildEmptyState(theme)
                            : _buildActiveChatList(activeChats, theme),

                        const SizedBox(height: 32),

                        // --- BAGIAN 2: TOMBOL MULAI CHAT (DI ATAS FAQ) ---
                        // Sembunyikan jika user sudah punya kedua jenis chat
                        if (!hasAdminChat || !hasCSChat)
                          _buildContactButtons(
                              context, theme, user, hasAdminChat, hasCSChat),

                        if (!hasAdminChat || !hasCSChat)
                          const SizedBox(height: 32),

                        // --- BAGIAN 3: FAQ ---
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text("Pertanyaan Umum (FAQ)",
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textMain))),
                        const SizedBox(height: 12),
                        _buildFAQSection(theme),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                }),
          );
        });
  }

  Widget _buildActiveChatList(List<QueryDocumentSnapshot> docs, AppThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var data = docs[index].data() as Map<String, dynamic>;
        String chatTitle = data['adminName'] ?? 'Admin Chupatu';
        String lastMessage = data['lastMessage'] ?? 'Mengirim file...';
        int unread = data['unreadUser'] ?? 0;

        String timeStr = "";
        if (data['lastTime'] != null) {
          DateTime date = (data['lastTime'] as Timestamp).toDate();
          timeStr = DateFormat('HH:mm').format(date);
        }
        IconData avatarIcon = chatTitle.contains('CS')
            ? Icons.support_agent_rounded
            : Icons.admin_panel_settings_rounded;

        return InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatRoomPage(
                      chatId: docs[index].id,
                      name: chatTitle,
                      isOnline: true,
                      isAdmin: false))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02), blurRadius: 8)
                ]),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.primary.withOpacity(0.1),
                    child: Icon(avatarIcon, color: theme.primary, size: 28)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(chatTitle,
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: theme.textMain)),
                            Text(timeStr,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: unread > 0 ? theme.primary : Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                                child: Text(lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: unread > 0 ? theme.textMain : Colors.grey,
                                        fontWeight: unread > 0
                                            ? FontWeight.bold
                                            : FontWeight.normal))),
                            if (unread > 0)
                              Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                      color: theme.primary, shape: BoxShape.circle),
                                  child: Text(unread.toString(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)))
                          ],
                        ),
                      ],
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppThemeData theme) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1))),
            child: Column(children: [
              Icon(Icons.forum_outlined, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text("Belum ada pesan aktif.",
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey))
            ])));
  }

  Widget _buildContactButtons(BuildContext context, AppThemeData theme,
      User? user, bool hasAdmin, bool hasCS) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primary.withOpacity(0.2))),
            child: Column(children: [
              Text("Mulai Obrolan Baru",
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.textMain)),
              const SizedBox(height: 8),
              Text("Pilih layanan yang ingin Anda hubungi.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              if (!hasAdmin)
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                        onPressed: () => user != null
                            ? _openChat(context, user, 'Admin Chupatu')
                            : null,
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text("Chat Admin (Info Pesanan)"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0))),
              if (!hasAdmin && !hasCS) const SizedBox(height: 12),
              if (!hasCS)
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                        onPressed: () => user != null
                            ? _openChat(context, user, 'CS Chupatu Pusat')
                            : null,
                        icon: const Icon(Icons.support_agent_rounded),
                        label: const Text("Chat CS (Keluhan/Bantuan)"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0))),
            ])));
  }

  Widget _buildFAQSection(AppThemeData theme) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
            decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1))),
            child: Column(children: [
              _buildFAQItem("Berapa lama proses cuci?",
                  "Fast Clean 1 hari, Deep Clean 3-5 hari.", theme),
              _buildFAQItem("Ada garansi?",
                  "Ya, kami menjamin keamanan sepatu Anda.", theme,
                  isLast: true)
            ])));
  }

  Widget _buildFAQItem(String q, String a, AppThemeData theme,
      {bool isLast = false}) {
    return Container(
        decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
        child: ExpansionTile(
            title: Text(q,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.textMain)),
            children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(a,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: Colors.grey.shade600)))
            ]));
  }
}