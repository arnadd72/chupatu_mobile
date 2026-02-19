import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart'; // IMPORT TEMA
import 'package:chupatu_mobile/pages/notification/chat_room_page.dart';

// ==========================================================
// 1. HALAMAN LIST PELANGGAN (DENGAN FILTER & SEARCH)
// ==========================================================
class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _sortOption = 'Terbaru';

  final List<String> _sortOptions = [
    'Terbaru',
    'Terlama',
    'Nama (A-Z)',
    'Nama (Z-A)',
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>( // BUNGKUS DENGAN TEMA
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background, // Adaptif
            appBar: AppBar(
              title: Text("Data Pelanggan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              backgroundColor: theme.surface, // Adaptif
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
            ),
            body: Column(
              children: [
                // --- BAGIAN FILTER & SEARCH ---
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  color: theme.surface, // Adaptif
                  child: Column(
                    children: [
                      // 1. SEARCH BAR
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: theme.textMain), // Adaptif
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: "Cari Nama atau User ID...",
                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: theme.background, // Adaptif (Background lebih gelap dari surface)
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. DROPDOWN SORTIR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Urutkan:", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                              color: theme.background, // Adaptif
                            ),
                            child: DropdownButton<String>(
                              value: _sortOption,
                              dropdownColor: theme.surface, // Warna pop-up dropdown adaptif
                              underline: const SizedBox(),
                              icon: Icon(Icons.sort, size: 20, color: theme.textMain),
                              items: _sortOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: theme.textMain)),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) setState(() => _sortOption = newValue);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- LIST DATA PELANGGAN ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text("Belum ada data pelanggan", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
                      }

                      var allDocs = snapshot.data!.docs;

                      var filteredDocs = allDocs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String name = (data['displayName'] ?? '').toLowerCase();
                        String id = doc.id.toLowerCase();
                        return name.contains(_searchQuery) || id.contains(_searchQuery);
                      }).toList();

                      filteredDocs.sort((a, b) {
                        var dataA = a.data() as Map<String, dynamic>;
                        var dataB = b.data() as Map<String, dynamic>;

                        DateTime timeA = (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2020);
                        DateTime timeB = (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2020);
                        String nameA = (dataA['displayName'] ?? '').toLowerCase();
                        String nameB = (dataB['displayName'] ?? '').toLowerCase();

                        switch (_sortOption) {
                          case 'Terlama': return timeA.compareTo(timeB);
                          case 'Nama (A-Z)': return nameA.compareTo(nameB);
                          case 'Nama (Z-A)': return nameB.compareTo(nameA);
                          case 'Terbaru': default: return timeB.compareTo(timeA);
                        }
                      });

                      if (filteredDocs.isEmpty) {
                        return Center(child: Text("Tidak ditemukan '$_searchQuery'", style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          var doc = filteredDocs[index];
                          var data = doc.data() as Map<String, dynamic>;
                          String userId = doc.id;

                          String dateStr = "-";
                          if (data['createdAt'] != null) {
                            dateStr = DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate());
                          }

                          return Container(
                            decoration: BoxDecoration(
                                color: theme.surface, // Adaptif
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Hero(
                                tag: 'avatar_$userId',
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: theme.primary.withOpacity(0.1),
                                  backgroundImage: (data['photoURL'] != null && data['photoURL'] != '')
                                      ? NetworkImage(data['photoURL'])
                                      : null,
                                  child: (data['photoURL'] == null || data['photoURL'] == '')
                                      ? Icon(Icons.person, color: theme.primary)
                                      : null,
                                ),
                              ),
                              title: Text(data['displayName'] ?? 'Tanpa Nama', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)), // Adaptif
                              subtitle: Text("Join: $dateStr", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerDetailPage(userId: userId, userData: data)));
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
    );
  }
}

// ==========================================================
// 2. HALAMAN DETAIL PELANGGAN
// ==========================================================
class CustomerDetailPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const CustomerDetailPage({super.key, required this.userId, required this.userData});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  bool _isLoadingChat = false;

  Future<void> _openChatRoom() async {
    setState(() => _isLoadingChat = true);
    try {
      var querySnapshot = await FirebaseFirestore.instance.collection('chats').where('userId', isEqualTo: widget.userId).limit(1).get();
      String chatDocId;
      if (querySnapshot.docs.isNotEmpty) {
        chatDocId = querySnapshot.docs.first.id;
      } else {
        var newChat = await FirebaseFirestore.instance.collection('chats').add({
          'userId': widget.userId,
          'userName': widget.userData['displayName'] ?? 'Customer',
          'lastMessage': '',
          'lastTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        });
        chatDocId = newChat.id;
      }
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomPage(chatId: chatDocId, name: widget.userData['displayName'] ?? 'Customer', isOnline: false, isAdmin: true)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if(mounted) setState(() => _isLoadingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String joinedDate = "Tidak Diketahui";
    if (widget.userData['createdAt'] != null) {
      try {
        DateTime dt = (widget.userData['createdAt'] as Timestamp).toDate();
        joinedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);
      } catch (_) {}
    }

    return ValueListenableBuilder<AppThemeData>( // BUNGKUS DENGAN TEMA
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background, // Adaptif
            appBar: AppBar(
              title: Text("Detail Pelanggan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              backgroundColor: theme.surface, // Adaptif
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(child: Column(children: [
                    Hero(tag: 'avatar_${widget.userId}', child: CircleAvatar(radius: 50, backgroundColor: theme.primary.withOpacity(0.1), backgroundImage: (widget.userData['photoURL'] != null && widget.userData['photoURL'] != '') ? NetworkImage(widget.userData['photoURL']) : null, child: (widget.userData['photoURL'] == null || widget.userData['photoURL'] == '') ? Icon(Icons.person, size: 50, color: theme.primary) : null)),
                    const SizedBox(height: 16),
                    Text(widget.userData['displayName'] ?? 'Tanpa Nama', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textMain)), // Adaptif
                    Text(widget.userData['email'] ?? '-', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.3))), child: Text(widget.userData['memberType'] ?? 'Regular Member', style: GoogleFonts.plusJakartaSans(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)))
                  ])),
                  const SizedBox(height: 30),

                  SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _isLoadingChat ? null : _openChatRoom, icon: _isLoadingChat ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.chat_bubble_outline), label: const Text("Chat Customer", style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(height: 30),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: widget.userId).snapshots(),
                    builder: (context, snapshot) {
                      int totalOrders = 0;
                      int activeOrders = 0;
                      int totalSpent = 0;
                      if (snapshot.hasData) {
                        totalOrders = snapshot.data!.docs.length;
                        for (var doc in snapshot.data!.docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          if (data['status'] != 'Done' && data['status'] != 'Cancelled') activeOrders++;
                          if (data['status'] == 'Done') totalSpent += (data['totalPrice'] as int? ?? 0);
                        }
                      }
                      return Column(children: [
                        Row(children: [_buildStatCard("Total Order", "$totalOrders", Colors.blue, theme), const SizedBox(width: 12), _buildStatCard("Sedang Proses", "$activeOrders", Colors.orange, theme)]),
                        const SizedBox(height: 12),
                        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withOpacity(0.3))), child: Column(children: [Text("Total Belanja", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.green)), Text(currencyFormatter.format(totalSpent), style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green))]))
                      ]);
                    },
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: theme.surface, border: Border.all(color: Colors.grey.withOpacity(0.2)), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Informasi Pribadi", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)), // Adaptif
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.confirmation_number_outlined, "User ID", widget.userId, theme),
                      _buildInfoRow(Icons.phone_outlined, "No. Handphone", widget.userData['phoneNumber'] ?? '-', theme),
                      _buildInfoRow(Icons.location_on_outlined, "Alamat Utama", widget.userData['address'] ?? '-', theme),
                      _buildInfoRow(Icons.calendar_today_outlined, "Bergabung Sejak", joinedDate, theme),
                    ]),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }
    );
  }

  // PERUBAHAN: Tambahkan parameter theme agar box solid adaptif
  Widget _buildStatCard(String label, String value, Color color, AppThemeData theme) {
    return Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.2))), child: Column(children: [Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 4), Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey))])));
  }

  Widget _buildInfoRow(IconData icon, String label, String value, AppThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)), const SizedBox(height: 2), Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textMain))]))]));
  }
}