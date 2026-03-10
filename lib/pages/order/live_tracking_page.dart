import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // WAJIB: Buat narik GPS

class LiveTrackingPage extends StatefulWidget {
  final String docId; // <-- WAJIB: Biar tau pesanan mana yang dilacak

  const LiveTrackingPage({super.key, required this.docId});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  // Controller buat ngatur kamera/geser peta
  final Completer<GoogleMapController> _controller = Completer();

  // Titik lokasi default (Sebelum GPS Firebase ketarik)
  LatLng _currentLocation = const LatLng(-6.974001, 107.630348);

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
          'Lacak Kurir Full',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // STREAMBUILDER BACA GPS DARI FIREBASE
      body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').doc(widget.docId).snapshots(),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: goldColor));
            }

            var docData = snapshot.data!.data() as Map<String, dynamic>?;
            GeoPoint? driverGeo = docData?['driverLocation'];

            if (driverGeo != null) {
              _currentLocation = LatLng(driverGeo.latitude, driverGeo.longitude);

              // Otomatis geser kamera setiap Admin pindah
              _controller.future.then((mapController) {
                mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
              });
            }

            return GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _currentLocation,
                zoom: 17.0, // Zoom lebih dekat biar mantap
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('kurir_chupatu'),
                  position: _currentLocation, // Posisi selalu ngikut variabel terbaru
                  infoWindow: const InfoWindow(
                      title: 'Kurir Chupatu',
                      snippet: 'Sedang di jalan...'
                  ),
                )
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
            );
          }
      ),

      // Tombol buat nge-center kamera balik ke kurir kalau user iseng geser petanya
      floatingActionButton: FloatingActionButton(
        backgroundColor: goldColor,
        onPressed: () async {
          final GoogleMapController mapController = await _controller.future;
          mapController.animateCamera(
            CameraUpdate.newLatLng(_currentLocation),
          );
        },
        child: const Icon(Icons.center_focus_strong, color: Colors.white),
      ),
    );
  }
}