import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart'; // WAJIB IMPORT INI UNTUK TEMA

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String name;
  final bool isOnline;
  final bool isAdmin;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.name,
    this.isOnline = false,
    required this.isAdmin,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _msgController = TextEditingController();

  // --- FUNGSI KIRIM PESAN ---
  void _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    String message = _msgController.text.trim();
    _msgController.clear();

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': message,
        'isSenderAdmin': widget.isAdmin,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'lastMessage': message,
        'lastTime': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      debugPrint("Gagal kirim pesan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. BUNGKUS DENGAN LISTENER TEMA
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {

          return Scaffold(
            backgroundColor: theme.background, // Ganti warna hardcode jadi tema
            appBar: AppBar(
              backgroundColor: theme.surface,
              elevation: 0, // Flat design biar modern
              iconTheme: IconThemeData(color: theme.textMain),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.primary.withOpacity(0.2),
                    radius: 18,
                    child: Text(
                        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : "?",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.primary)
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name, style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (widget.isOnline)
                        Text("Online", style: GoogleFonts.plusJakartaSans(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                // --- LIST PESAN ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatId)
                        .collection('messages')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(child: Text("Mulai percakapan dengan ${widget.name} 👋", style: GoogleFonts.plusJakartaSans(color: theme.textMain.withOpacity(0.5))));
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          bool isSenderAdmin = data['isSenderAdmin'] ?? false;

                          // Logika 'Saya'
                          bool isMe = (widget.isAdmin == isSenderAdmin);

                          return _buildChatBubble(data['text'], isMe, data['createdAt'], theme);
                        },
                      );
                    },
                  ),
                ),

                // --- INPUT FIELD ---
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.surface, // Warna surface tema (bukan putih hardcode)
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              color: theme.background, // Warna input field mengikuti background tema
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: theme.primary.withOpacity(0.1))
                          ),
                          child: TextField(
                            controller: _msgController,
                            style: GoogleFonts.plusJakartaSans(color: theme.textMain),
                            decoration: InputDecoration(
                              hintText: "Tulis pesan...",
                              hintStyle: GoogleFonts.plusJakartaSans(color: theme.textMain.withOpacity(0.4)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: theme.primary, // Tombol kirim ikut warna tema utama
                        child: IconButton(
                          icon: Icon(Icons.send_rounded, color: theme.isDark ? Colors.black : Colors.white, size: 20),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  // Tambahkan parameter 'theme' disini
  Widget _buildChatBubble(String text, bool isMe, Timestamp? timestamp, AppThemeData theme) {
    String timeStr = "";
    if (timestamp != null) {
      timeStr = DateFormat('HH:mm').format(timestamp.toDate());
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280), // Batasi lebar bubble biar rapi
        decoration: BoxDecoration(
          // Logic Warna:
          // Kalau Saya: Pakai Theme Primary (misal: Retro=Orange, Midnight=Ungu)
          // Kalau Lawan: Pakai Theme Surface (misal: Retro=Kuning Pucat, Midnight=Abu Gelap)
          color: isMe ? theme.primary : theme.surface,

          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
          border: isMe ? null : Border.all(color: theme.textMain.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  // Logic Text Color:
                  // Kalau Saya: Putih/Hitam tergantung DarkMode tema (biasanya Primary textnya kontras)
                  // Kalau Lawan: Pakai textMain tema
                  color: isMe
                      ? (theme.isDark ? Colors.white : Colors.white)
                      : theme.textMain,
                  height: 1.4,
                )
            ),
            const SizedBox(height: 4),
            Text(
                timeStr,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isMe ? Colors.white.withOpacity(0.7) : theme.textMain.withOpacity(0.5)
                )
            ),
          ],
        ),
      ),
    );
  }
}