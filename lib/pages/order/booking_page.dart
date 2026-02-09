import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk ambil data input
  final _shoeController = TextEditingController();
  final _noteController = TextEditingController();

  String? selectedService;
  DateTime selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> services = [
    'Deep Clean',
    'Unyellowing',
    'Repair',
    'Reglue',
  ];

  // Fungsi memunculkan kalender
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Fungsi Simpan ke Firebase
  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;

        await FirebaseFirestore.instance.collection('bookings').add({
          'userId': user?.uid,
          'userEmail': user?.email,
          'shoeModel': _shoeController.text.trim(),
          'service': selectedService,
          'notes': _noteController.text.trim(),
          'bookingDate': selectedDate,
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking Berhasil Terkirim!')),
          );
          Navigator.pop(context); // Kembali ke Dashboard
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Cuci Sepatu')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              "Detail Sepatu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Input Merk Sepatu
            TextFormField(
              controller: _shoeController,
              decoration: const InputDecoration(
                labelText: 'Merk & Model Sepatu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.abc),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Isi merk sepatu kamu' : null,
            ),
            const SizedBox(height: 15),

            // Dropdown Layanan
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Pilih Layanan',
                border: OutlineInputBorder(),
              ),
              items: services
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => selectedService = val),
              validator: (value) => value == null ? 'Pilih layanan dulu' : null,
            ),
            const SizedBox(height: 15),

            // Widget Pilih Tanggal
            const Text(
              "Tanggal Penjemputan",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    ),
                    const Icon(Icons.calendar_month, color: Colors.blue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Input Catatan
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan Kendala (Opsional)',
                hintText: 'Contoh: Ada noda tinta di bagian sol',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Tombol Submit
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _submitBooking,
                    child: const Text(
                      'Konfirmasi Booking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
