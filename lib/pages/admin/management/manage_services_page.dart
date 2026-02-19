import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:chupatu_mobile/main.dart';

// ==========================================================
// 1. HALAMAN UTAMA (KELOLA LAYANAN)
// ==========================================================
class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  State<ManageServicesPage> createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> _logActivity(String action, String serviceName) async {
    await FirebaseFirestore.instance.collection('service_logs').add({
      'action': action,
      'serviceName': serviceName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showAddServiceSheet(BuildContext context, AppThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddServiceForm(theme: theme, onSuccess: (name) => _logActivity('add', name)),
    );
  }

  void _deleteService(String docId, String? imageUrl, String serviceName, AppThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text("Hapus Layanan?", style: TextStyle(color: theme.textMain)),
        content: Text("Yakin ingin menghapus '$serviceName'?", style: TextStyle(color: theme.textMain)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('services').doc(docId).delete();
              if (imageUrl != null && imageUrl.isNotEmpty) {
                try { await FirebaseStorage.instance.refFromURL(imageUrl).delete(); } catch (_) {}
              }
              _logActivity('delete', serviceName);
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$serviceName dihapus")));
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background, // Adaptif
            appBar: AppBar(
              title: Text("Kelola Layanan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
              backgroundColor: theme.surface, // Adaptif
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ServiceHistoryScreen()));
                  },
                  icon: Icon(Icons.history_rounded, color: theme.primary),
                  tooltip: "Riwayat Perubahan",
                )
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddServiceSheet(context, theme),
              backgroundColor: theme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text("Tambah Layanan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers_clear_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("Belum ada layanan.", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return _buildServiceCard(
                      docId: docs[index].id,
                      name: data['name'] ?? 'Layanan',
                      price: data['price'] ?? 0,
                      desc: data['description'] ?? '',
                      imageUrl: data['imageUrl'],
                      theme: theme,
                    );
                  },
                );
              },
            ),
          );
        }
    );
  }

  Widget _buildServiceCard({required String docId, required String name, required int price, required String desc, String? imageUrl, required AppThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: theme.surface, // Adaptif
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: theme.background, // Adaptif
              borderRadius: BorderRadius.circular(12),
              image: (imageUrl != null && imageUrl.isNotEmpty)
                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: (imageUrl == null || imageUrl.isEmpty)
                ? Icon(Icons.cleaning_services, color: theme.primary, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)), // Adaptif
                const SizedBox(height: 4),
                Text(currencyFormatter.format(price), style: GoogleFonts.plusJakartaSans(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteService(docId, imageUrl, name, theme),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// 2. BAGIAN FORM TAMBAH LAYANAN (DENGAN TEMA ADAPTIF)
// ==========================================================
class AddServiceForm extends StatefulWidget {
  final Function(String) onSuccess;
  final AppThemeData theme;
  const AddServiceForm({super.key, required this.onSuccess, required this.theme});

  @override
  State<AddServiceForm> createState() => _AddServiceFormState();
}

class _AddServiceFormState extends State<AddServiceForm> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _saveService() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      String imageUrl = "";
      if (_imageFile != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = FirebaseStorage.instance.ref().child('services/$fileName.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('services').add({
        'name': _nameController.text.trim(),
        'price': int.parse(_priceController.text.replaceAll('.', '')),
        'description': _descController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      widget.onSuccess(_nameController.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(color: theme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text("Tambah Layanan", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textMain)),
          const SizedBox(height: 20),

          // UPLOAD FOTO
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
                ),
                child: _imageFile == null
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.grey), Text("Foto", style: TextStyle(fontSize: 10, color: Colors.grey))])
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // TEXTFIELD ADAPTIF
          TextField(controller: _nameController, style: TextStyle(color: theme.textMain), decoration: InputDecoration(labelText: "Nama Layanan", labelStyle: const TextStyle(color: Colors.grey), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)), borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary), borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextField(controller: _priceController, keyboardType: TextInputType.number, style: TextStyle(color: theme.textMain), decoration: InputDecoration(labelText: "Harga (Rp)", labelStyle: const TextStyle(color: Colors.grey), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)), borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary), borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextField(controller: _descController, maxLines: 2, style: TextStyle(color: theme.textMain), decoration: InputDecoration(labelText: "Deskripsi Singkat", labelStyle: const TextStyle(color: Colors.grey), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)), borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primary), borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveService,
              style: ElevatedButton.styleFrom(backgroundColor: theme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// 3. HALAMAN RIWAYAT (HISTORY)
// ==========================================================
class ServiceHistoryScreen extends StatelessWidget {
  const ServiceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
      valueListenable: ThemeConfig.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.background, // Adaptif
          appBar: AppBar(
            title: Text("Riwayat Perubahan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: theme.textMain)),
            backgroundColor: theme.surface, // Adaptif
            elevation: 0,
            iconTheme: IconThemeData(color: theme.textMain),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('service_logs')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_edu_rounded, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("Belum ada riwayat aktivitas", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                    ],
                  ),
                );
              }

              var docs = snapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (c, i) => Divider(color: Colors.grey.withOpacity(0.2)),
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String action = data['action'] ?? 'info';
                  String name = data['serviceName'] ?? '-';

                  String timeStr = "-";
                  if (data['timestamp'] != null) {
                    DateTime d = (data['timestamp'] as Timestamp).toDate();
                    timeStr = DateFormat('dd MMM yyyy, HH:mm').format(d);
                  }

                  bool isAdd = action == 'add';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAdd ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      child: Icon(isAdd ? Icons.add_circle_outline : Icons.delete_outline, color: isAdd ? Colors.green : Colors.red),
                    ),
                    title: Text(isAdd ? "Menambahkan Layanan" : "Menghapus Layanan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain)), // Adaptif
                    subtitle: Text(name, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontWeight: FontWeight.w600)),
                    trailing: Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey)),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}