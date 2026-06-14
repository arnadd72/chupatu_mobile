import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class LiveTrackingPage extends StatefulWidget {
  final String docId; // <-- WAJIB: Biar tau pesanan mana yang dilacak

  const LiveTrackingPage({super.key, required this.docId});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final MapController _mapController = MapController();

  // Titik lokasi default (Sebelum GPS Firebase ketarik)
  LatLng _driverLocation = const LatLng(-6.974001, 107.630348);
  LatLng? _customerLocation;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('bookings').doc(widget.docId).get();
      var data = doc.data();
      if (data != null) {
        GeoPoint? custGeo = data['customerLocation'];
        GeoPoint? driverGeo = data['driverLocation'];
        
        if (custGeo != null) {
          _customerLocation = LatLng(custGeo.latitude, custGeo.longitude);
        }
        if (driverGeo != null) {
          _driverLocation = LatLng(driverGeo.latitude, driverGeo.longitude);
        }
        
        if (_customerLocation != null && driverGeo != null) {
           await _getRoute();
        }
      }
    } catch (e) {
      debugPrint("Gagal get data awal: $e");
    }
  }

  Future<void> _getRoute() async {
    if (_customerLocation == null) return;
    
    setState(() => _isLoadingRoute = true);
    try {
      final start = _driverLocation;
      final end = _customerLocation!;
      // Format OSRM: longitude,latitude
      final url = 'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['coordinates'];
          setState(() {
            // OSRM return [longitude, latitude], kita balik jadi LatLng(latitude, longitude)
            _routePoints = geometry.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal fetch route OSRM: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Lacak Kurir Full (Gratis)',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').doc(widget.docId).snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: goldColor));
                }

                var docData = snapshot.data!.data() as Map<String, dynamic>?;
                GeoPoint? driverGeo = docData?['driverLocation'];
                GeoPoint? custGeo = docData?['customerLocation'];

                // Update posisi kurir secara realtime
                if (driverGeo != null) {
                  _driverLocation = LatLng(driverGeo.latitude, driverGeo.longitude);
                  
                  // Geser kamera otomatis mengikuti driver
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    try {
                      _mapController.move(_driverLocation, 16.0);
                    } catch(e) {
                      // catch jika map belum siap
                    }
                  });
                }

                // Cek ulang kalau lokasi customer baru ketarik
                if (custGeo != null && _customerLocation == null) {
                  _customerLocation = LatLng(custGeo.latitude, custGeo.longitude);
                  _getRoute();
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _driverLocation,
                    initialZoom: 16.0,
                    // minZoom: 5, maxZoom: 18
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.chupatu.mobile',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 4.0,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Marker Customer (Lokasi Tujuan)
                        if (_customerLocation != null)
                          Marker(
                            point: _customerLocation!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        // Marker Kurir (Selalu terupdate)
                        Marker(
                          point: _driverLocation,
                          width: 50,
                          height: 50,
                          child: Container(
                             decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)]
                             ),
                             child: const Icon(
                               Icons.motorcycle_rounded,
                               color: goldColor,
                               size: 30,
                             ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
          ),
          
          if (_isLoadingRoute)
            Positioned(
               top: 20,
               left: 0,
               right: 0,
               child: Center(
                 child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                       color: Colors.black87,
                       borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Mencari rute jalan...",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                 ),
               ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: goldColor,
        onPressed: () {
          _mapController.move(_driverLocation, 16.0);
        },
        child: const Icon(Icons.center_focus_strong, color: Colors.white),
      ),
    );
  }
}