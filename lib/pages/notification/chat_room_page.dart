import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomPage extends StatefulWidget {
  final String name;
  final bool isOnline;

  // --- TAMBAHAN BARU UNTUK ADMIN ---
  final String? chatId; // Kunci Kamar (Opsional)
  final bool isAdmin;   // Penanda apakah yang buka ini Admin?

  const ChatRoomPage({
    super.key,
    required this.name,
    required this.isOnline,
    this.chatId,          // Admin wajib isi ini
    this.isAdmin = false, // Default: False (User Biasa)
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  late String roomChatId;

  @override
  void initState() {
    super.initState();
    // LOGIKA PENENTUAN ROOM ID
    if (widget.chatId != null) {
      // Jika Admin yang buka, pakai ID yang dikirim dari AdminChatPage
      roomChatId = widget.chatId!;
    } else {
      // Jika User yang buka, generate ID sendiri (UID_admin)
      roomChatId = "${user!.uid}_admin";
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    // Tentukan siapa pengirimnya
    String senderId = widget.isAdmin ? 'admin' : user!.uid;

    // 1. Kirim Pesan
    FirebaseFirestore.instance
        .collection('chats')
        .doc(roomChatId)
        .collection('messages')
        .add({
      'text': _messageController.text.trim(),
      'senderId': senderId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Update Info Terakhir di List Chat
    FirebaseFirestore.instance.collection('chats').doc(roomChatId).set({
      'lastMessage': _messageController.text.trim(),
      'lastTime': FieldValue.serverTimestamp(),
      // Jangan update userId/userName kalau Admin yang balas, biarkan tetap punya user
      if (!widget.isAdmin) 'userId': user!.uid,
      if (!widget.isAdmin) 'userName': user!.displayName ?? 'User',
    }, SetOptions(merge: true));

    _messageController.clear();

    // Scroll ke bawah
    Future.delayed(const Duration(milliseconds: 100), () {
      if(_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: widget.isAdmin ? Colors.orange.shade100 : Colors.blue.shade100,
              child: Text(widget.name[0].toUpperCase(), style: TextStyle(color: widget.isAdmin ? Colors.orange : Colors.blue)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                Text("Online", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // LIST PESAN
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(roomChatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if(_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    // LOGIKA BUBBLE CHAT:
                    // Jika Saya Admin -> Pesan 'admin' ada di Kanan.
                    // Jika Saya User  -> Pesan 'user.uid' ada di Kanan.
                    bool isMe;
                    if (widget.isAdmin) {
                      isMe = data['senderId'] == 'admin';
                    } else {
                      isMe = data['senderId'] == user!.uid;
                    }

                    String text = data['text'] ?? '';
                    String time = "";
                    if (data['createdAt'] != null) {
                      DateTime d = (data['createdAt'] as Timestamp).toDate();
                      time = "${d.hour}:${d.minute.toString().padLeft(2,'0')}";
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? (widget.isAdmin ? Colors.orange : Colors.blue) : Colors.grey.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(text, style: GoogleFonts.plusJakartaSans(color: isMe ? Colors.white : Colors.black87)),
                            const SizedBox(height: 4),
                            Text(time, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT TEXT
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Tulis pesan...",
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: widget.isAdmin ? Colors.orange : Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
}