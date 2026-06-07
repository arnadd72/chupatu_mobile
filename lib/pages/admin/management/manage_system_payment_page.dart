import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chupatu_mobile/main.dart';

class ManageSystemPaymentPage extends StatefulWidget {
  const ManageSystemPaymentPage({super.key});

  @override
  State<ManageSystemPaymentPage> createState() => _ManageSystemPaymentPageState();
}

class _ManageSystemPaymentPageState extends State<ManageSystemPaymentPage> {
  bool _isLoading = false;
  bool _isFetching = true;

  // --- STATE PENGIRIMAN DINAMIS (BERDASARKAN JARAK) ---
  bool _isDeliveryActive = true;
  final _baseDistanceCtrl = TextEditingController(); // Jarak dasar (misal 3 KM)
  final _baseFeeCtrl = TextEditingController(); // Harga dasar (misal Rp 10.000)
  final _extraFeePerKmCtrl = TextEditingController(); // Tambahan per KM (misal Rp 2.000)
  final _freeDeliveryMinOrderCtrl = TextEditingController();

  // --- STATE PAYMENT GATEWAY (MAYAR) ---
  bool _isMayarActive = true;
  bool _isMayarSandbox = true;
  bool _obscureApiKey = true;
  bool _obscureWebhook = true;
  final _mayarApiKeyCtrl = TextEditingController();
  final _mayarWebhookSecretCtrl = TextEditingController();

  // --- STATE FONNTE (WhatsApp OTP) ---
  bool _obscureFonnteToken = true;
  final _fonnteTokenCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('config')
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        // Load Delivery Data
        _isDeliveryActive = data['isDeliveryActive'] ?? true;
        _baseDistanceCtrl.text = (data['baseDistanceKm'] ?? 0).toString();
        _baseFeeCtrl.text = (data['baseDeliveryFee'] ?? 0).toString();
        _extraFeePerKmCtrl.text = (data['extraFeePerKm'] ?? 0).toString();
        _freeDeliveryMinOrderCtrl.text = (data['freeDeliveryMinOrder'] ?? 0).toString();

        // Load Mayar Data
        _isMayarActive = data['isMayarActive'] ?? true;
        _isMayarSandbox = data['isMayarSandbox'] ?? true;
        _mayarApiKeyCtrl.text = data['mayarApiKey'] ?? '';
        _mayarWebhookSecretCtrl.text = data['mayarWebhookSecret'] ?? '';

        // Load Fonnte Data
        _fonnteTokenCtrl.text = data['fonnteToken'] ?? '';
      }
    } catch (e) {
      debugPrint("Gagal meload konfigurasi: $e");
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('system_settings').doc('config').set({
        // Simpan Data Pengiriman Dinamis
        'isDeliveryActive': _isDeliveryActive,
        'baseDistanceKm': int.tryParse(_baseDistanceCtrl.text) ?? 0,
        'baseDeliveryFee': int.tryParse(_baseFeeCtrl.text) ?? 0,
        'extraFeePerKm': int.tryParse(_extraFeePerKmCtrl.text) ?? 0,
        'freeDeliveryMinOrder': int.tryParse(_freeDeliveryMinOrderCtrl.text) ?? 0,

        // Simpan Data Mayar
        'isMayarActive': _isMayarActive,
        'isMayarSandbox': _isMayarSandbox,
        'mayarApiKey': _mayarApiKeyCtrl.text.trim(),
        'mayarWebhookSecret': _mayarWebhookSecretCtrl.text.trim(),

        // Simpan Data Fonnte
        'fonnteToken': _fonnteTokenCtrl.text.trim(),

        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Konfigurasi Sistem Berhasil Diperbarui!"),
              backgroundColor: Colors.green,
            )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal menyimpan: $e"))
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _baseDistanceCtrl.dispose();
    _baseFeeCtrl.dispose();
    _extraFeePerKmCtrl.dispose();
    _freeDeliveryMinOrderCtrl.dispose();
    _mayarApiKeyCtrl.dispose();
    _mayarWebhookSecretCtrl.dispose();
    _fonnteTokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
        valueListenable: ThemeConfig.currentTheme,
        builder: (context, theme, child) {
          return Scaffold(
            backgroundColor: theme.background,
            appBar: AppBar(
              title: Text(
                "Sistem & Pembayaran",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, color: theme.textMain
                ),
              ),
              backgroundColor: theme.surface,
              elevation: 1,
              iconTheme: IconThemeData(color: theme.textMain),
            ),
            body: _isFetching
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Konfigurasi Utama",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textMain
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Atur skema biaya operasional dan gerbang pembayaran (Payment Gateway) aplikasi.",
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // =======================================================
                  // PENGATURAN ANTAR JEMPUT (DINAMIS BERDASARKAN JARAK)
                  // =======================================================
                  _buildSectionCard(
                    theme: theme,
                    title: "Biaya Antar Jemput (Dinamis)",
                    icon: Icons.map_rounded,
                    color: Colors.blue,
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("Aktifkan Antar-Jemput", style: TextStyle(color: theme.textMain)),
                          subtitle: const Text("Pelanggan bisa request pickup", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          activeColor: Colors.blue,
                          value: _isDeliveryActive,
                          onChanged: (val) => setState(() => _isDeliveryActive = val),
                        ),
                        const Divider(),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _baseDistanceCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: theme.textMain),
                                decoration: _inputDecoration(
                                    theme, "Jarak Dasar (KM)",
                                    helperText: "Contoh: 3 KM"
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _baseFeeCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: theme.textMain),
                                decoration: _inputDecoration(
                                    theme, "Tarif Dasar (Rp)",
                                    helperText: "Contoh: 10000"
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _extraFeePerKmCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: theme.textMain),
                          decoration: _inputDecoration(
                              theme, "Biaya Tambahan per KM (Rp)",
                              helperText: "Dikenakan jika jarak melebihi Jarak Dasar. Contoh: 2000"
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _freeDeliveryMinOrderCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: theme.textMain),
                          decoration: _inputDecoration(
                              theme,
                              "Min. Belanja untuk Free Ongkir (Rp)",
                              helperText: "Isi 0 jika tidak ada promo gratis ongkir."
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // =======================================================
                  // PENGATURAN MAYAR.ID
                  // =======================================================
                  _buildSectionCard(
                    theme: theme,
                    title: "Payment Gateway (Mayar.id)",
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.teal,
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("Aktifkan Pembayaran Otomatis", style: TextStyle(color: theme.textMain)),
                          subtitle: const Text("Gunakan Mayar untuk Qris/Virtual Account", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          activeColor: Colors.teal,
                          value: _isMayarActive,
                          onChanged: (val) => setState(() => _isMayarActive = val),
                        ),
                        if (_isMayarActive) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text("Mode Sandbox (Testing)", style: TextStyle(color: theme.textMain)),
                            subtitle: const Text("Matikan ini saat rilis ke publik", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            activeColor: Colors.orange,
                            value: _isMayarSandbox,
                            onChanged: (val) => setState(() => _isMayarSandbox = val),
                          ),
                          const Divider(),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _mayarApiKeyCtrl,
                            obscureText: _obscureApiKey,
                            style: TextStyle(color: theme.textMain, fontFamily: 'monospace'),
                            decoration: _inputDecoration(
                                theme,
                                "Mayar API Key",
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureApiKey ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                  onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                                )
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _mayarWebhookSecretCtrl,
                            obscureText: _obscureWebhook,
                            style: TextStyle(color: theme.textMain, fontFamily: 'monospace'),
                            decoration: _inputDecoration(
                                theme,
                                "Mayar Webhook Secret",
                                helperText: "Dibutuhkan untuk memverifikasi pembayaran lunas.",
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureWebhook ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                  onPressed: () => setState(() => _obscureWebhook = !_obscureWebhook),
                                )
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // =======================================================
                  // PENGATURAN FONNTE (WhatsApp OTP)
                  // =======================================================
                  _buildSectionCard(
                    theme: theme,
                    title: "WhatsApp OTP (Fonnte.com)",
                    icon: Icons.chat_rounded,
                    color: Colors.green,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Token API Fonnte digunakan untuk mengirim kode OTP ke WhatsApp pelanggan. Dapatkan token di fonnte.com/dashboard.",
                          style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _fonnteTokenCtrl,
                          obscureText: _obscureFonnteToken,
                          style: TextStyle(color: theme.textMain, fontFamily: 'monospace'),
                          decoration: _inputDecoration(
                            theme,
                            "Fonnte API Token",
                            helperText: "Token dari dashboard Fonnte.com Anda.",
                            suffixIcon: IconButton(
                              icon: Icon(_obscureFonnteToken ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setState(() => _obscureFonnteToken = !_obscureFonnteToken),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, color: Colors.white),
                      label: Text(
                        _isLoading ? "Menyimpan..." : "SIMPAN KONFIGURASI",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildSectionCard({
    required AppThemeData theme, required String title, required IconData icon, required Color color, required Widget child
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textMain)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          child
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(AppThemeData theme, String label, {String? helperText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      helperText: helperText,
      helperStyle: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}