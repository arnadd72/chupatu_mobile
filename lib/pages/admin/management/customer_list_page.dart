import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart';
import 'package:chupatu_mobile/pages/notification/chat_room_page.dart';
import 'package:chupatu_mobile/pages/admin/orders/admin_order_detail_page.dart';

// ==========================================================
// 1. HALAMAN LIST PELANGGAN (DENGAN FILTER SULTAN)
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
    'Order Terbanyak',
    'Belanja Terbesar',
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text("Data Pelanggan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              backgroundColor: theme.surface,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  color: theme.surface,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: theme.textMain),
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: "Cari Nama atau User ID...",
                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: theme.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Urutkan:", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                              color: theme.background,
                            ),
                            child: DropdownButton<String>(
                              value: _sortOption,
                              dropdownColor: theme.surface,
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
                        // SMART FALLBACK UNTUK NAMA DI LIST
                        String name = (data['displayName'] ?? data['name'] ?? data['fullName'] ?? '').toLowerCase();
                        String id = doc.id.toLowerCase();
                        return name.contains(_searchQuery) || id.contains(_searchQuery);
                      }).toList();

                      filteredDocs.sort((a, b) {
                        var dataA = a.data() as Map<String, dynamic>;
                        var dataB = b.data() as Map<String, dynamic>;

                        DateTime timeA = (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2020);
                        DateTime timeB = (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2020);
                        String nameA = (dataA['displayName'] ?? dataA['name'] ?? '').toLowerCase();
                        String nameB = (dataB['displayName'] ?? dataB['name'] ?? '').toLowerCase();

                        int orderA = dataA['totalOrders'] ?? 0;
                        int orderB = dataB['totalOrders'] ?? 0;
                        int spentA = dataA['totalSpent'] ?? 0;
                        int spentB = dataB['totalSpent'] ?? 0;

                        switch (_sortOption) {
                          case 'Terlama': return timeA.compareTo(timeB);
                          case 'Nama (A-Z)': return nameA.compareTo(nameB);
                          case 'Nama (Z-A)': return nameB.compareTo(nameA);
                          case 'Order Terbanyak': return orderB.compareTo(orderA);
                          case 'Belanja Terbesar': return spentB.compareTo(spentA);
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

                          // SMART FALLBACK
                          String displayName = data['displayName'] ?? data['name'] ?? data['fullName'] ?? 'Tanpa Nama';
                          String photoUrl = data['photoURL'] ?? data['photoUrl'] ?? data['avatar'] ?? '';
                          bool isBanned = data['isBanned'] ?? false;

                          String dateStr = "-";
                          if (data['createdAt'] != null) {
                            dateStr = DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate());
                          }

                          return Container(
                            decoration: BoxDecoration(
                                color: isBanned ? Colors.red.withOpacity(0.05) : theme.surface,
                                border: Border.all(color: isBanned ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Hero(
                                tag: 'avatar_$userId',
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: isBanned ? Colors.red.withOpacity(0.1) : theme.primary.withOpacity(0.1),
                                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                  child: photoUrl.isEmpty ? Icon(Icons.person, color: isBanned ? Colors.red : theme.primary) : null,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isBanned)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                      child: const Text("BANNED", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    )
                                ],
                              ),
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
// 2. HALAMAN DETAIL PELANGGAN (REALTIME & DEFENSIVE PROGRAMMING)
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

  Future<void> _openChatRoom(String customerName) async {
    setState(() => _isLoadingChat = true);
    try {
      var querySnapshot = await FirebaseFirestore.instance.collection('chats').where('userId', isEqualTo: widget.userId).limit(1).get();
      String chatDocId;
      if (querySnapshot.docs.isNotEmpty) {
        chatDocId = querySnapshot.docs.first.id;
      } else {
        var newChat = await FirebaseFirestore.instance.collection('chats').add({
          'userId': widget.userId,
          'userName': customerName,
          'lastMessage': '',
          'lastTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        });
        chatDocId = newChat.id;
      }
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomPage(chatId: chatDocId, name: customerName, isOnline: false, isAdmin: true)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if(mounted) setState(() => _isLoadingChat = false);
    }
  }

  Future<void> _toggleBanStatus(bool currentBanStatus) async {
    String actionWord = currentBanStatus ? "PULIHKAN (Unban)" : "BLOKIR (Ban)";

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ThemeConfig.currentTheme.value.surface,
          title: Text("$actionWord Akun Ini?", style: TextStyle(color: ThemeConfig.currentTheme.value.textMain, fontWeight: FontWeight.bold)),
          content: Text(
              currentBanStatus
                  ? "Pengguna akan dapat menggunakan aplikasi kembali."
                  : "Pengguna tidak akan bisa memesan layanan dan login ke dalam aplikasi.",
              style: TextStyle(color: ThemeConfig.currentTheme.value.textMain)
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: currentBanStatus ? Colors.green : Colors.red),
              onPressed: () async {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
                  'isBanned': !currentBanStatus
                });
                if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status akun berhasil diubah.")));
              },
              child: Text(actionWord, style: const TextStyle(color: Colors.white)),
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
              backgroundColor: theme.background,
              appBar: AppBar(
                title: Text("Detail Pelanggan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
                backgroundColor: theme.surface,
                elevation: 0,
                iconTheme: IconThemeData(color: theme.textMain),
              ),
              // STREAMBUILDER AGAR DATA SELALU REALTIME DAN AKURAT
              body: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Ambil data live, kalau gagal pakai data awal (widget.userData)
                    Map<String, dynamic> liveData = widget.userData;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      liveData = snapshot.data!.data() as Map<String, dynamic>;
                    }

                    // --- SMART FALLBACK FIELD MAPPING ---
                    // Cek semua kemungkinan nama field yang mungkin dibuat Frontend
                    String displayName = liveData['displayName'] ?? liveData['name'] ?? liveData['fullName'] ?? 'Tanpa Nama';
                    String phone = liveData['phoneNumber'] ?? liveData['phone'] ?? liveData['no_hp'] ?? liveData['noHp'] ?? '-';
                    String address = liveData['address'] ?? liveData['alamat'] ?? liveData['mainAddress'] ?? '-';
                    String email = liveData['email'] ?? '-';
                    String photoUrl = liveData['photoURL'] ?? liveData['photoUrl'] ?? liveData['avatar'] ?? '';
                    String memberType = liveData['memberType'] ?? 'Regular Member';
                    bool isBanned = liveData['isBanned'] ?? false;

                    // --- PENGELOLAAN TANGGAL GABUNG (DENGAN FALLBACK) ---
                    String joinedDate = "Tidak Diketahui";
                    if (liveData['createdAt'] != null) {
                      try {
                        DateTime dt = (liveData['createdAt'] as Timestamp).toDate();
                        joinedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);
                      } catch (_) {}
                    } else if (liveData['lastLogin'] != null) {
                      // Fallback: Jika createdAt tidak ada, pakai lastLogin
                      try {
                        DateTime dt = (liveData['lastLogin'] as Timestamp).toDate();
                        joinedDate = "${DateFormat('dd MMMM yyyy').format(dt)} (Aktivitas Terakhir)";
                      } catch (_) {}
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- PROFILE HEADER ---
                          Center(child: Column(children: [
                            Hero(
                                tag: 'avatar_${widget.userId}',
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(radius: 50, backgroundColor: theme.primary.withOpacity(0.1), backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null, child: photoUrl.isEmpty ? Icon(Icons.person, size: 50, color: theme.primary) : null),
                                    if (isBanned)
                                      Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.block, color: Colors.white, size: 20))
                                  ],
                                )
                            ),
                            const SizedBox(height: 16),
                            Text(displayName, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textMain)),
                            Text(email, style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: isBanned ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: isBanned ? Colors.red : Colors.green.withOpacity(0.3))),
                                child: Text(
                                    isBanned ? 'AKUN DIBLOKIR' : memberType,
                                    style: GoogleFonts.plusJakartaSans(color: isBanned ? Colors.red : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)
                                )
                            )
                          ])),
                          const SizedBox(height: 30),

                          // --- STATISTIK OTOMATIS ---
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: widget.userId).snapshots(),
                            builder: (context, orderSnap) {
                              int totalOrders = 0;
                              int activeOrders = 0;
                              int totalSpent = 0;
                              if (orderSnap.hasData) {
                                totalOrders = orderSnap.data!.docs.length;
                                for (var doc in orderSnap.data!.docs) {
                                  var data = doc.data() as Map<String, dynamic>;
                                  if (data['status'] != 'Done' && data['status'] != 'Cancelled') activeOrders++;
                                  if (data['status'] == 'Done') totalSpent += (data['totalPrice'] as int? ?? 0);
                                }
                              }
                              return Column(children: [
                                Row(children: [_buildStatCard("Total Order", "$totalOrders", Colors.blue, theme), const SizedBox(width: 12), _buildStatCard("Sedang Proses", "$activeOrders", Colors.orange, theme)]),
                                const SizedBox(height: 12),
                                Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withOpacity(0.3))), child: Column(children: [Text("Total Belanja Terekam", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.green)), Text(currencyFormatter.format(totalSpent), style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green))]))
                              ]);
                            },
                          ),
                          const SizedBox(height: 30),

                          // --- PANEL TINDAKAN ADMIN ---
                          Text("Manajemen & Tindakan", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                          const SizedBox(height: 12),

                          _buildAdminActionCard(
                            icon: Icons.chat_bubble_outline,
                            title: "Kirim Pesan (Chat)",
                            subtitle: "Hubungi pelanggan via chat internal",
                            color: theme.primary,
                            theme: theme,
                            onTap: _isLoadingChat ? () {} : () => _openChatRoom(displayName),
                          ),
                          const SizedBox(height: 12),

                          _buildAdminActionCard(
                            icon: Icons.shopping_bag_outlined,
                            title: "Pantau Transaksi",
                            subtitle: "Lihat semua riwayat order pelanggan ini",
                            color: Colors.blue,
                            theme: theme,
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CustomerTransactionHistoryPage(
                                        userId: widget.userId,
                                        userName: displayName,
                                      )
                                  )
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildAdminActionCard(
                            icon: Icons.block,
                            title: isBanned ? "Pulihkan Akun (Unban)" : "Blokir Akses (Banned)",
                            subtitle: isBanned ? "Kembalikan akses pelanggan ke aplikasi" : "Cegah pelanggan melakukan order & login",
                            color: isBanned ? Colors.green : Colors.red,
                            theme: theme,
                            onTap: () => _toggleBanStatus(isBanned),
                          ),
                          const SizedBox(height: 30),

                          // --- INFO PRIBADI (DENGAN SMART FALLBACK) ---
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: theme.surface, border: Border.all(color: Colors.grey.withOpacity(0.2)), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Informasi Pribadi", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                                  Icon(Icons.shield_outlined, color: Colors.grey.shade400, size: 20)
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(Icons.confirmation_number_outlined, "User ID", widget.userId, theme),
                              _buildInfoRow(Icons.phone_outlined, "No. Handphone", phone, theme),
                              _buildInfoRow(Icons.location_on_outlined, "Alamat Utama", address, theme),
                              _buildInfoRow(Icons.calendar_today_outlined, "Bergabung Sejak", joinedDate, theme),
                            ]),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  }
              )
          );
        }
    );
  }

  Widget _buildStatCard(String label, String value, Color color, AppThemeData theme) {
    return Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.2))), child: Column(children: [Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 4), Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey))])));
  }

  Widget _buildInfoRow(IconData icon, String label, String value, AppThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)), const SizedBox(height: 2), Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textMain))]))]));
  }

  Widget _buildAdminActionCard({required IconData icon, required String title, required String subtitle, required Color color, required AppThemeData theme, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain)),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400)
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// 3. HALAMAN BARU: RIWAYAT TRANSAKSI SPESIFIK PELANGGAN
// ==========================================================
class CustomerTransactionHistoryPage extends StatelessWidget {
  final String userId;
  final String userName;

  const CustomerTransactionHistoryPage({super.key, required this.userId, required this.userName});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Pending Payment': return Colors.orangeAccent;
      case 'Confirmed': return Colors.blue;
      case 'Picked Up': return Colors.purple;
      case 'Processing': return Colors.indigo;
      case 'Ready': return Colors.teal;
      case 'Delivery': return Colors.deepPurple;
      case 'Done': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text(
                  "Transaksi: $userName",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain, fontSize: 16)
              ),
              backgroundColor: theme.surface,
              elevation: 1,
              iconTheme: IconThemeData(color: theme.textMain),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text("Belum ada transaksi.", style: GoogleFonts.plusJakartaSans(color: Colors.grey))
                  );
                }

                var docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  Timestamp? tA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  Timestamp? tB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

                return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String docId = docs[index].id;

                      String status = data['status'] ?? 'Pending';
                      Color statusColor = _getStatusColor(status);

                      String dateStr = "-";
                      if (data['createdAt'] != null) {
                        dateStr = DateFormat('dd MMM yyyy, HH:mm').format((data['createdAt'] as Timestamp).toDate());
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AdminOrderDetailPage(
                                    docId: docId,
                                    data: data,
                                  )
                              )
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      "Order #${docId.substring(0, 6).toUpperCase()}",
                                      style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, color: theme.textMain)
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8)
                                    ),
                                    child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), shape: BoxShape.circle),
                                    child: Icon(Icons.cleaning_services_rounded, size: 20, color: theme.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            data['serviceName'] ?? 'Layanan',
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)
                                        ),
                                        Text(dateStr, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                      currencyFormatter.format(data['totalPrice'] ?? 0),
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }
                );
              },
            ),
          );
        }
    );
  }
}