import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;   // KUNCI UTAMA (ID Dokumen di Firebase)
  final String name;     // Nama Lawan Bicara
  final bool isOnline;   // Status (Visual aja)
  final bool isAdmin;    // Penanda: Kita ini Admin atau Customer?

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.name,
    this.isOnline = false,
    required this.isAdmin, // Wajib diisi biar tau posisi chat bubble
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
    _msgController.clear(); // Langsung kosongkan input biar cepet

    try {
      // 1. Masukkan Pesan ke Sub-Collection 'messages'
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': message,
        'isSenderAdmin': widget.isAdmin, // True jika Admin, False jika Customer
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. UPDATE Data Luar (Parent Document)
      // Ini PENTING biar di List Chat Home (Admin) atau List Chat Customer berubah 'Last Message'-nya
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'lastMessage': message,
        'lastTime': FieldValue.serverTimestamp(),
        // Jika perlu update status read/unread bisa disini
      });

    } catch (e) {
      debugPrint("Gagal kirim pesan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Warna background abu muda
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: widget.isAdmin ? Colors.blue.shade100 : Colors.green.shade100,
              radius: 18,
              child: Text(widget.name[0].toUpperCase(), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: GoogleFonts.plusJakartaSans(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  .doc(widget.chatId) // Masuk ke Room spesifik
                  .collection('messages') // Ambil pesan
                  .orderBy('createdAt', descending: true) // Pesan baru di bawah (logic reverse ListView)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text("Mulai percakapan dengan ${widget.name} 👋", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
                }

                return ListView.builder(
                  reverse: true, // Biar scroll mulai dari bawah
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    // Cek siapa pengirimnya
                    bool isSenderAdmin = data['isSenderAdmin'] ?? false;

                    // Logika Bubble:
                    // Jika kita Admin (widget.isAdmin == true) dan pesannya dari Admin (isSenderAdmin == true) -> Posisi Kanan (Saya)
                    // Jika kita Customer (widget.isAdmin == false) dan pesannya BUKAN Admin (isSenderAdmin == false) -> Posisi Kanan (Saya)
                    bool isMe = (widget.isAdmin == isSenderAdmin);

                    return _buildChatBubble(data['text'], isMe, data['createdAt']);
                  },
                );
              },
            ),
          ),

          // --- INPUT FIELD ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: "Tulis pesan...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: widget.isAdmin ? Colors.blue : Colors.green,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
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

  Widget _buildChatBubble(String text, bool isMe, Timestamp? timestamp) {
    String timeStr = "";
    if (timestamp != null) {
      timeStr = DateFormat('HH:mm').format(timestamp.toDate());
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? (widget.isAdmin ? Colors.blue : Colors.green) // Biru kalau Admin, Hijau kalau Customer
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: GoogleFonts.plusJakartaSans(color: isMe ? Colors.white : Colors.black87)),
            const SizedBox(height: 4),
            Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}