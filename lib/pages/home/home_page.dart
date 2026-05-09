import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chupatu_mobile/main.dart';

// PAGE IMPORTS
import 'package:chupatu_mobile/pages/profile/profile_page.dart';
import 'package:chupatu_mobile/pages/profile/member_payment_page.dart';
import 'package:chupatu_mobile/pages/order/service_detail_page.dart';
import 'package:chupatu_mobile/pages/order/order_detail_page.dart';
import 'package:chupatu_mobile/pages/home/widgets/auto_magic_card.dart';
import 'package:chupatu_mobile/pages/home/magic_result_detail_page.dart';
import 'package:chupatu_mobile/pages/notification/notification_page.dart';
import 'package:chupatu_mobile/pages/home/garage/garage_page.dart';
import 'package:chupatu_mobile/pages/order/custom_service_page.dart';
import 'package:chupatu_mobile/pages/home/review_rating_section.dart';
import 'package:chupatu_mobile/pages/notification/customer_chat_page.dart';

// WIDGET IMPORTS
import 'package:chupatu_mobile/pages/home/widgets/shoe_tips_widget.dart';
import 'package:chupatu_mobile/pages/home/widgets/live_tracking_widget.dart';
import 'package:chupatu_mobile/pages/home/widgets/mini_garage_widget.dart';
import 'package:chupatu_mobile/pages/home/widgets/promo_banner_widget.dart';
import 'package:chupatu_mobile/pages/home/widgets/gemini_ai_scanner.dart'; // <--- IMPORT WIDGET AI GEMINI BARU

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _showFloatingPromo = true;
  late AnimationController _upgradeAnimController;
  final User? user = FirebaseAuth.instance.currentUser;
  StreamSubscription<QuerySnapshot>? _bookingSubscription;

  @override
  void initState() {
    super.initState();

    _setupPushNotifications();

    _upgradeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (user != null) {
      _bookingSubscription = FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user!.uid)
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            var data = change.doc.data() as Map<String, dynamic>;
            String serviceName = data['serviceName'] ?? 'Pesanan Anda';
            String newStatus = data['status'] ?? 'Diperbarui';
            String docId = change.doc.id;

            _showStatusUpdatePopup(docId, data, serviceName, newStatus);

            FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
              'hasUnreadNotif': true
            }, SetOptions(merge: true));
          }
        }
      });
    }
  }

  Future<void> _setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;

    NotificationSettings settings = await fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User ngasih izin notif!');

      String? token = await fcm.getToken();
      debugPrint('FCM Token HP ini: $token');

      if (token != null && user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
    }
  }

  void _showStatusUpdatePopup(String docId, Map<String, dynamic> data, String serviceName, String newStatus) {
    if (!mounted) return;
    final theme = ThemeConfig.currentTheme.value;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "TopNotif",
      barrierColor: Colors.black.withOpacity(0.1),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _TopNotificationPopup(
          docId: docId,
          data: data,
          serviceName: serviceName,
          newStatus: newStatus,
          theme: theme,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) return 'Good Morning,';
    if (hour < 15) return 'Good Afternoon,';
    if (hour < 19) return 'Good Evening,';
    return 'Good Night,';
  }

  @override
  void dispose() {
    _upgradeAnimController.dispose();
    _bookingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Silakan Login Kembali"));

    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
          builder: (context, userSnapshot) {

            bool isPro = false;
            String displayName = user?.displayName ?? 'Guest';
            String photoURL = user?.photoURL ?? 'https://i.pravatar.cc/150';
            bool unreadNotif = true;

            if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
              var userData = userSnapshot.data!.data() as Map<String, dynamic>;

              String mType = (userData['memberType'] ?? "").toString();
              String uRole = (userData['role'] ?? "").toString();
              isPro = (mType == 'Pro' || uRole == 'Pro');

              String dbUsername = (userData['username'] ?? '').toString().trim();
              String dbName = (userData['name'] ?? '').toString().trim();
              String dbDisplayName = (userData['displayName'] ?? '').toString().trim();

              if (dbUsername.isNotEmpty) {
                displayName = dbUsername;
              } else if (dbName.isNotEmpty) {
                displayName = dbName;
              } else if (dbDisplayName.isNotEmpty) {
                displayName = dbDisplayName;
              }

              if (userData['photoUrl'] != null && userData['photoUrl'].toString().isNotEmpty) {
                photoURL = userData['photoUrl'];
              } else if (userData['photoURL'] != null && userData['photoURL'].toString().isNotEmpty) {
                photoURL = userData['photoURL'];
              }

              photoURL = photoURL.replaceAll("http://", "https://");

              if (userData.containsKey('hasUnreadNotif')) {
                unreadNotif = userData['hasUnreadNotif'] == true;
              }
            }

            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.surface,
                      theme.background,
                      theme.primary.withOpacity(0.08),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                        top: -80, left: -60,
                        child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [theme.primary.withOpacity(0.4), Colors.transparent], radius: 0.6)))
                    ),
                    Positioned(
                        top: 150, right: -120,
                        child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [theme.secondary.withOpacity(0.35), Colors.transparent], radius: 0.6)))
                    ),
                    Positioned.fill(
                        child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                            child: Container(color: theme.surface.withOpacity(0.15))
                        )
                    ),

                    SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEADER PROFILE
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
                                        child: Row(
                                            children: [
                                              Container(
                                                  width: 50, height: 50,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: theme.surface, width: 2),
                                                      image: DecorationImage(
                                                          image: NetworkImage(
                                                              photoURL,
                                                              headers: const {
                                                                'ngrok-skip-browser-warning': 'true',
                                                                'User-Agent': 'ChupatuApp'
                                                              }
                                                          ),
                                                          fit: BoxFit.cover
                                                      ),
                                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
                                                  )
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(_getGreeting(), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                                                    Row(
                                                        children: [
                                                          Text(displayName, style: GoogleFonts.plusJakartaSans(fontSize: 18, color: theme.textMain, fontWeight: FontWeight.w800)),
                                                          if (isPro) ...[const SizedBox(width: 6), const Icon(Icons.verified, color: Colors.blue, size: 16)]
                                                        ]
                                                    )
                                                  ]
                                              )
                                            ]
                                        )
                                    ),
                                    Row(
                                        children: [
                                          GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => const CustomerChatPage())
                                                );
                                              },
                                              child: Container(
                                                  width: 42, height: 42,
                                                  decoration: BoxDecoration(
                                                      color: theme.surface.withOpacity(0.8),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: theme.surface),
                                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                                                  ),
                                                  child: Icon(Icons.chat_bubble_outline_rounded, color: theme.primary, size: 20)
                                              )
                                          ),
                                          const SizedBox(width: 12),
                                          AnimatedNotificationIcon(
                                            hasNewNotif: unreadNotif,
                                            theme: theme,
                                            onTap: () {
                                              FirebaseFirestore.instance.collection('users').doc(user!.uid).set({'hasUnreadNotif': false}, SetOptions(merge: true));
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
                                            },
                                          ),
                                        ]
                                    ),
                                  ]
                              ),
                            ),
                            const SizedBox(height: 12),

                            PromoBannerWidget(theme: theme),
                            const SizedBox(height: 16),

                            // MENU LAYANAN
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Our Services', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                                  const SizedBox(height: 16),
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 20,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.7,
                                    children: [
                                      _buildLottieServiceItem('water_drop.json', 'Deep Clean', theme, Colors.blue, Icons.water_drop_rounded, () => _navigateToService(context, 'Deep Clean')),
                                      _buildLottieServiceItem('Stopwatch.json', 'Fast Clean', theme, Colors.orange, Icons.timer_rounded, () => _navigateToService(context, 'Fast Clean')),
                                      _buildLottieServiceItem('sparkle.json', 'Unyellow', theme, Colors.amber, Icons.wb_sunny_rounded, () => _navigateToService(context, 'Unyellowing')),
                                      _buildLottieServiceItem('wrench.json', 'Repair', theme, Colors.grey, Icons.build_rounded, () => _navigateToService(context, 'Repair')),
                                      _buildLottieServiceItem('paint.json', 'Repaint', theme, Colors.purple, Icons.format_paint_rounded, () => _navigateToService(context, 'Repaint')),
                                      _buildLottieServiceItem('umbrella.json', 'Waterproof', theme, Colors.teal, Icons.umbrella_rounded, () => _navigateToService(context, 'Waterproof')),
                                      _buildLottieServiceItem('pencil.json', 'Custom', theme, Colors.pink, Icons.design_services_rounded, () => _navigateToService(context, 'Custom Painting')),
                                      _buildLottieServiceItem('delivery.json', 'Pickup', theme, Colors.green, Icons.local_shipping_rounded, () => _navigateToService(context, 'Pickup Service')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (!isPro) ...[
                              _buildChupatuPro(theme),
                              const SizedBox(height: 24),
                            ],

                            // LIVE TRACKING
                            LiveTrackingWidget(userId: user!.uid, theme: theme),
                            const SizedBox(height: 24),

                            // --- CARD AI SCANNER GEMINI (TAMBAHAN BARU) ---
                            const GeminiScanCard(),
                            const SizedBox(height: 24),

                            // mini garage
                            MiniGarageWidget(theme: theme),

                            // MAGIC RESULTS
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Magic Results ✨', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                        height: 240,
                                        child: ListView(
                                            scrollDirection: Axis.horizontal,
                                            clipBehavior: Clip.none,
                                            children: [
                                              AutoMagicCard(
                                                  beforeUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=600',
                                                  afterUrl: 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?q=80&w=600',
                                                  title: 'Nike Air Force 1',
                                                  theme: theme,
                                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MagicResultDetailPage(title: 'Nike Air Force 1', beforeImg: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=600', afterImg: 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?q=80&w=600')))
                                              ),
                                              const SizedBox(width: 16),
                                              AutoMagicCard(
                                                  beforeUrl: 'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?q=80&w=600',
                                                  afterUrl: 'https://images.unsplash.com/photo-1515955656352-a1fa3ffcd111?q=80&w=600',
                                                  title: 'Jordan Repaint',
                                                  theme: theme,
                                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MagicResultDetailPage(title: 'Jordan Repaint', beforeImg: 'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?q=80&w=600', afterImg: 'https://images.unsplash.com/photo-1515955656352-a1fa3ffcd111?q=80&w=600')))
                                              ),
                                            ]
                                        )
                                    ),
                                  ]
                              ),
                            ),

                            const SizedBox(height: 30),

                            // SHOE TIPS
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tips Merawat Sepatu 💡', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
                                  const SizedBox(height: 12),
                                  ShoeTipsWidget(theme: theme),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // REVIEW & RATING
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const ReviewRatingSection(),
                                ],
                              ),
                            ),

                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),

                    if (_showFloatingPromo)
                      Positioned(
                          bottom: 100,
                          left: 20,
                          right: 20,
                          child: Dismissible(
                              key: const Key('promo'),
                              onDismissed: (_) => setState(() => _showFloatingPromo = false),
                              child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E2C).withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                                      ]
                                  ),
                                  child: Row(
                                      children: [
                                        const Icon(Icons.local_offer_rounded, color: Color(0xFFFFD700), size: 24),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Promo Gajian!', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                  Text('Diskon 30% semua layanan hari ini.', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12))
                                                ]
                                            )
                                        ),
                                        IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                                            onPressed: () => setState(() => _showFloatingPromo = false)
                                        )
                                      ]
                                  )
                              )
                          )
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

// --- HELPER METHODS ---
  Future<void> _navigateToService(BuildContext context, String serviceName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white)
      ),
    );

    try {
      int price = 30000;
      String description = "Layanan perawatan sepatu profesional.";
      String imageUrl = "https://images.unsplash.com/photo-1542291026-7eec264c27ff";

      if (serviceName == 'Deep Clean') {
        imageUrl = "https://images.unsplash.com/photo-1595341888016-a392ef81b7de?q=80&w=800";
      } else if (serviceName == 'Fast Clean') {
        imageUrl = "https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?q=80&w=800";
      } else if (serviceName == 'Custom Painting' || serviceName == 'Custom') {
        imageUrl = "https://images.unsplash.com/photo-1560769629-975ec94e6a86?q=80&w=800";
      }

      var querySnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('name', isEqualTo: serviceName)
          .limit(1)
          .get();

      if (context.mounted) Navigator.pop(context);

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data();

        if (data['price'] != null) {
          price = int.tryParse(data['price'].toString()) ?? price;
        }
        if (data['description'] != null && data['description'].toString().isNotEmpty) {
          description = data['description'];
        }
      } else {
        debugPrint("Layanan $serviceName belum disetting di Firebase. Pakai harga default.");
      }

      if (context.mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ServiceDetailPage(
                    serviceName: serviceName,
                    price: price,
                    description: description,
                    imageUrl: imageUrl
                )
            )
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint("Error Fetching Service Price: $e");
    }
  }

  Widget _buildLottieServiceItem(String fileName, String label, AppThemeData theme, Color itemColor, IconData fallbackIcon, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: Column(
            children: [
              Expanded(
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: itemColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: itemColor.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(color: itemColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
                          ]
                      ),
                      child: Lottie.asset(
                          'assets/lottie/$fileName',
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => Icon(fallbackIcon, color: itemColor, size: 30)
                      )
                  )
              ),
              const SizedBox(height: 8),
              Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textMain
                  )
              )
            ]
        )
    );
  }

  Widget _buildChupatuPro(AppThemeData theme) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFF9E6), Color(0xFFFDF4D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))
                ]
            ),
            child: Row(
                children: [
                  Container(
                      height: 60, width: 60, padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]
                      ),
                      child: Lottie.asset(
                          'assets/lottie/trophy.json',
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(Icons.emoji_events, color: Color(0xFFD4AF37), size: 30)
                      )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Join Chupatu Pro', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0B0F19), fontWeight: FontWeight.w800, fontSize: 16)),
                            Text('Priority service & Gold status.', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 12))
                          ]
                      )
                  ),
                  AnimatedBuilder(
                      animation: _upgradeAnimController,
                      builder: (context, child) {
                        double scale = 1.0 + (_upgradeAnimController.value * 0.1);
                        double rotate = math.sin(_upgradeAnimController.value * math.pi * 2) * 0.05;
                        return Transform.scale(
                            scale: scale,
                            child: Transform.rotate(
                                angle: rotate,
                                child: GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemberPaymentPage(onPaymentSuccess: (){}))),
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF1E1E2C),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))]
                                        ),
                                        child: Text("Upgrade", style: GoogleFonts.plusJakartaSans(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12))
                                    )
                                )
                            )
                        );
                      }
                  )
                ]
            )
        )
    );
  }
}

// ============================================================
// WIDGET KHUSUS: POP-UP NOTIFIKASI DARI ATAS
// ============================================================
class _TopNotificationPopup extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String serviceName;
  final String newStatus;
  final AppThemeData theme;

  const _TopNotificationPopup({
    required this.docId,
    required this.data,
    required this.serviceName,
    required this.newStatus,
    required this.theme,
  });

  @override
  State<_TopNotificationPopup> createState() => _TopNotificationPopupState();
}

class _TopNotificationPopupState extends State<_TopNotificationPopup> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'Pending': return {'color': const Color(0xFFF59E0B), 'icon': Icons.pending_actions_rounded, 'label': 'Menunggu Konfirmasi'};
      case 'Confirmed': return {'color': const Color(0xFF3B82F6), 'icon': Icons.check_circle_outline_rounded, 'label': 'Dikonfirmasi'};
      case 'Picked Up': return {'color': const Color(0xFF8B5CF6), 'icon': Icons.local_shipping_outlined, 'label': 'Sepatu Dijemput'};
      case 'Processing': return {'color': const Color(0xFF10B981), 'icon': Icons.cleaning_services_rounded, 'label': 'Sedang Dicuci'};
      case 'Ready': return {'color': const Color(0xFF14B8A6), 'icon': Icons.inventory_2_outlined, 'label': 'Selesai Dicuci'};
      case 'Delivery': return {'color': const Color(0xFF6366F1), 'icon': Icons.delivery_dining_rounded, 'label': 'Sedang Diantar'};
      case 'Done': return {'color': const Color(0xFF22C55E), 'icon': Icons.task_alt_rounded, 'label': 'Pesanan Selesai'};
      case 'Cancelled': return {'color': const Color(0xFFEF4444), 'icon': Icons.cancel_outlined, 'label': 'Dibatalkan'};
      default: return {'color': Colors.grey, 'icon': Icons.help_outline, 'label': 'Tidak Dikenal'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: widget.theme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
                ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: widget.theme.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.notifications_active_rounded, color: widget.theme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Update Pesanan!", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: widget.theme.textMain)),
                          const SizedBox(height: 4),
                          Text("Status pesanan ${widget.serviceName} Anda telah diperbarui menjadi: ${widget.newStatus.toUpperCase()}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _timer?.cancel();
                        Navigator.pop(context);
                      },
                      child: Text("Tutup", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.theme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _timer?.cancel();
                        Navigator.pop(context);

                        var config = _getStatusConfig(widget.newStatus);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailPage(
                          docId: widget.docId,
                          data: widget.data,
                          statusColor: config['color'],
                          statusIcon: config['icon'],
                          statusLabel: config['label'],
                        )));
                      },
                      child: const Text("Lihat Detail", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET KHUSUS: IKON NOTIFIKASI GOYANG & TITIK MERAH
// ============================================================
class AnimatedNotificationIcon extends StatefulWidget {
  final bool hasNewNotif;
  final VoidCallback onTap;
  final AppThemeData theme;

  const AnimatedNotificationIcon({
    super.key,
    required this.hasNewNotif,
    required this.onTap,
    required this.theme,
  });

  @override
  State<AnimatedNotificationIcon> createState() => _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<AnimatedNotificationIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.hasNewNotif) {
      _startShaking();
    }
  }

  void _startShaking() async {
    _isAnimating = true;
    while (_isAnimating && mounted) {
      await _controller.forward();
      _controller.reset();
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  void didUpdateWidget(AnimatedNotificationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasNewNotif && !oldWidget.hasNewNotif) {
      _startShaking();
    }
    else if (!widget.hasNewNotif && oldWidget.hasNewNotif) {
      _isAnimating = false;
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _isAnimating = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: widget.theme.surface.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: widget.theme.surface),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animation.value,
                    child: Icon(Icons.notifications_none_rounded, color: widget.theme.textMain.withOpacity(0.8)),
                  );
                }
            ),
            if (widget.hasNewNotif)
              Positioned(
                top: 10,
                right: 10,
                child: const CircleAvatar(radius: 3.5, backgroundColor: Colors.redAccent),
              ),
          ],
        ),
      ),
    );
  }
}