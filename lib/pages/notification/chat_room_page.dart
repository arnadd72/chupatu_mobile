import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

  @override
  void initState() {
    super.initState();

    // LOGIKA RESET YANG SANGAT JELAS
    if (widget.isAdmin) {
      // Jika Admin yang buka, reset notif admin jadi 0
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'unreadAdmin': 0,
      }).catchError((e) => debugPrint("Gagal reset unreadAdmin: $e"));
    } else {
      // Jika User yang buka, reset notif user jadi 0
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'unreadUser': 0,
      }).catchError((e) => debugPrint("Gagal reset unreadUser: $e"));
    }
  }

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

      // LOGIKA TRIGGER YANG SANGAT JELAS
      if (widget.isAdmin) {
        // ADMIN MENGIRIM PESAN -> Tambahkan unreadUser
        await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
          'lastMessage': message,
          'lastTime': FieldValue.serverTimestamp(),
          'unreadUser': FieldValue.increment(1),
        });
      } else {
        // USER MENGIRIM PESAN -> Tambahkan unreadAdmin
        await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
          'lastMessage': message,
          'lastTime': FieldValue.serverTimestamp(),
          'unreadAdmin': FieldValue.increment(1),
        });
      }

    } catch (e) {
      debugPrint("Gagal kirim pesan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              backgroundColor: theme.surface,
              elevation: 0,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name, style: GoogleFonts.plusJakartaSans(color: theme.textMain, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (widget.isOnline)
                          Text("Online", style: GoogleFonts.plusJakartaSans(color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatId)
                        .collection('messages')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final isLoading = snapshot.connectionState == ConnectionState.waiting;
                      var docs = isLoading ? [] : (snapshot.data?.docs ?? []);
                      if (!isLoading && docs.isEmpty) return Center(child: Text("Mulai percakapan dengan ${widget.name} 👋", style: GoogleFonts.plusJakartaSans(color: theme.textMain.withOpacity(0.5))));

                      return Skeletonizer(
                        enabled: isLoading,
                        child: ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: isLoading ? 3 : docs.length,
                          itemBuilder: (context, index) {
                            if (isLoading) {
                              return _buildChatBubble('Ini skeleton text yang lumayan panjang', index % 2 == 0, null, theme);
                            }
                            var data = docs[index].data() as Map<String, dynamic>;
                          bool isSenderAdmin = false;
                          
                          // Web admin writes `isAdmin: true` or `type: 'admin'` / `senderId: 'admin'`
                          // Mobile admin writes `isSenderAdmin: true`
                          var rawSender = data['isSenderAdmin'] ?? data['isAdmin'];
                          if (rawSender is bool) {
                            isSenderAdmin = rawSender;
                          } else if (rawSender is String) {
                            isSenderAdmin = rawSender.toLowerCase() == 'true';
                          } else if (rawSender is int) {
                            isSenderAdmin = rawSender == 1;
                          }

                          // Fallback check for web admin specific sender type fields
                          if (!isSenderAdmin) {
                            var senderType = data['type'] ?? data['senderId'];
                            if (senderType is String && senderType.toLowerCase() == 'admin') {
                              isSenderAdmin = true;
                            }
                          }

                          bool isMe = (widget.isAdmin == isSenderAdmin);
                          return _buildChatBubble(data['text'], isMe, data['createdAt'], theme);
                        },
                      ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.surface,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: theme.background, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.primary.withOpacity(0.1))),
                          child: TextField(
                            controller: _msgController,
                            style: GoogleFonts.plusJakartaSans(color: theme.textMain),
                            decoration: InputDecoration(hintText: "Tulis pesan...", hintStyle: GoogleFonts.plusJakartaSans(color: theme.textMain.withOpacity(0.4)), border: InputBorder.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: theme.primary,
                        child: IconButton(icon: Icon(Icons.send_rounded, color: theme.isDark ? Colors.black : Colors.white, size: 20), onPressed: _sendMessage),
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

  Widget _buildChatBubble(String text, bool isMe, Timestamp? timestamp, AppThemeData theme) {
    String timeStr = "";
    if (timestamp != null) timeStr = DateFormat('HH:mm').format(timestamp.toDate());
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? theme.primary : theme.surface,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 0), bottomRight: Radius.circular(isMe ? 0 : 16)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
          border: isMe ? null : Border.all(color: theme.textMain.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: GoogleFonts.plusJakartaSans(color: isMe ? Colors.white : theme.textMain, height: 1.4)),
            const SizedBox(height: 4),
            Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: isMe ? Colors.white.withOpacity(0.7) : theme.textMain.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}