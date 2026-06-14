import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoicePdfHelper {
  static Future<Uint8List> _generateInvoiceBytes(String docId, Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Persiapan Data
    String dateStr = "-";
    if (data['createdAt'] != null) {
      dateStr = DateFormat('dd MMMM yyyy').format((data['createdAt'] as Timestamp).toDate());
    }

    String customerName = data['customerName'] ?? 'Pelanggan';
    String serviceName = data['serviceName'] ?? 'Layanan Chupatu';
    String shoeDetail = data['shoeDetail'] ?? '-';
    String paymentMethod = data['paymentMethod'] ?? 'COD';

    // Alamat
    String mainAddress = data['mainAddress'] ?? '';
    String detailAddress = data['detailAddress'] ?? '';
    String address = "$mainAddress\n$detailAddress";
    if (address.trim().isEmpty) address = data['address'] ?? '-';

    // Harga
    int basePrice = data['basePrice'] ?? 0;
    int deliveryFee = data['deliveryFee'] ?? 0;
    int discount = data['discount'] ?? 0;
    int totalPrice = data['totalPrice'] ?? 0;

    // Desain Halaman PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // --- WATERMARK LUNAS (Di Belakang) ---
              pw.Positioned(
                top: 250, left: 50,
                child: pw.Transform.rotate(
                  angle: 0.6, // Kemiringan
                  child: pw.Text(
                    "LUNAS",
                    style: pw.TextStyle(
                      color: const PdfColor(0.3, 0.68, 0.31, 0.15), // Format: (Red, Green, Blue, Alpha/Opacity)
                      fontSize: 120,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // --- KONTEN INVOICE (Di Depan) ---
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 1. HEADER (Logo & Tulisan Invoice)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("chupatu", style: pw.TextStyle(color: PdfColors.green600, fontSize: 32, fontWeight: pw.FontWeight.bold)),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text("INVOICE", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                            pw.Text("INV/${docId.toUpperCase()}", style: pw.TextStyle(color: PdfColors.green600, fontWeight: pw.FontWeight.bold)),
                          ]
                      )
                    ],
                  ),
                  pw.SizedBox(height: 30),

                  // 2. DATA PENJUAL & PEMBELI
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                            child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text("DITERBITKAN ATAS NAMA", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                  pw.SizedBox(height: 5),
                                  pw.Row(children: [pw.SizedBox(width: 60, child: pw.Text("Penjual", style: const pw.TextStyle(fontSize: 10))), pw.Text(": Chupatu Official", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))]),
                                ]
                            )
                        ),
                        pw.Expanded(
                            child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text("UNTUK", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                  pw.SizedBox(height: 5),
                                  pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.SizedBox(width: 80, child: pw.Text("Pembeli", style: const pw.TextStyle(fontSize: 10))), pw.Expanded(child: pw.Text(": $customerName", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)))]),
                                  pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.SizedBox(width: 80, child: pw.Text("Tanggal Pembelian", style: const pw.TextStyle(fontSize: 10))), pw.Expanded(child: pw.Text(": $dateStr", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)))]),
                                  pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.SizedBox(width: 80, child: pw.Text("Alamat", style: const pw.TextStyle(fontSize: 10))), pw.Expanded(child: pw.Text(": $address", style: const pw.TextStyle(fontSize: 10)))]),
                                ]
                            )
                        ),
                      ]
                  ),
                  pw.SizedBox(height: 30),

                  // 3. TABEL PRODUK
                  pw.TableHelper.fromTextArray(
                    headers: ['INFO PRODUK', 'JUMLAH', 'HARGA SATUAN', 'TOTAL HARGA'],
                    headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    headerDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 2))),
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    cellPadding: const pw.EdgeInsets.symmetric(vertical: 8),
                    data: [
                      [
                        "$serviceName\n$shoeDetail",
                        "1",
                        currency.format(basePrice),
                        currency.format(basePrice)
                      ],
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // 4. RINCIAN HARGA (Kanan Bawah)
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Container(
                            width: 250,
                            child: pw.Column(
                                children: [
                                  _buildPriceRowPdf("SUBTOTAL HARGA LAYANAN", basePrice, currency, isBold: true),
                                  if (discount > 0) _buildPriceRowPdf("Diskon", -discount, currency),
                                  _buildPriceRowPdf("Biaya Antar Jemput", deliveryFee, currency),
                                  pw.Divider(),
                                  _buildPriceRowPdf("TOTAL TAGIHAN", totalPrice, currency, isBold: true),
                                ]
                            )
                        )
                      ]
                  ),
                  pw.SizedBox(height: 40),

                  // 5. FOOTER (Metode Bayar)
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 10),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Layanan Sepatu Bersih & Terpercaya\nTerima kasih telah menggunakan Chupatu.", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("Metode Pembayaran:", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                              pw.Text(paymentMethod, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            ]
                        )
                      ]
                  )
                ],
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static Future<void> downloadInvoice(String docId, Map<String, dynamic> data) async {
    final bytes = await _generateInvoiceBytes(docId, data);
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'Invoice_Chupatu_${docId.substring(0,6)}.pdf'
    );
  }

  static Future<void> shareInvoice(String docId, Map<String, dynamic> data) async {
    final bytes = await _generateInvoiceBytes(docId, data);
    await Printing.sharePdf(
        bytes: bytes,
        filename: 'Invoice_Chupatu_${docId.substring(0,6)}.pdf'
    );
  }

  static pw.Widget _buildPriceRowPdf(String label, int amount, NumberFormat currency, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(currency.format(amount), style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}