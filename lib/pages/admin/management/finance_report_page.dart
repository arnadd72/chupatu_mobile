import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:chupatu_mobile/main.dart'; // IMPORT TEMA

class FinanceReportPage extends StatefulWidget {
  const FinanceReportPage({super.key});

  @override
  State<FinanceReportPage> createState() => _FinanceReportPageState();
}

class _FinanceReportPageState extends State<FinanceReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter Waktu
  String _selectedRange = '1M';
  final List<String> _ranges = ['1D', '1W', '1M', '3M', '1Y', 'All'];

  // Sorting Pelanggan
  String _customerSortType = 'Terbanyak';

  // Interaksi Grafik
  double? _touchedValue;
  String? _touchedDate;

  // Warna UI (Chart)
  final Color _stockGreen = const Color(0xFF00C853);
  final Color _stockRed = const Color(0xFFD50000);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() { _touchedValue = null; _touchedDate = null; });
    });
  }

  // --- LOGIKA TANGGAL ---
  DateTime _getStartDate() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    switch (_selectedRange) {
      case '1D': return today;
      case '1W': return today.subtract(const Duration(days: 7));
      case '1M': return today.subtract(const Duration(days: 30));
      case '3M': return today.subtract(const Duration(days: 90));
      case '1Y': return today.subtract(const Duration(days: 365));
      case 'All': return DateTime(2020);
      default: return today.subtract(const Duration(days: 30));
    }
  }

  // --- FITUR SHARE PDF ---
  Future<void> _generatePdf(List<QueryDocumentSnapshot> docs, bool isIncome) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Hitung Total
    int totalAmount = 0;
    for (var doc in docs) {
      if (isIncome) {
        totalAmount += (doc['totalPrice'] as int? ?? 0);
      } else {
        totalAmount += (doc['amount'] as int? ?? 0);
      }
    }

    // Siapkan Data Tabel
    final tableData = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['createdAt'] as Timestamp).toDate();
      final title = isIncome ? (data['serviceName'] ?? '-') : (data['itemName'] ?? '-');
      final subtitle = isIncome ? (data['customerName'] ?? '-') : 'Stok Masuk';
      final value = isIncome ? (data['totalPrice'] ?? 0) : (data['amount'] ?? 0);

      return [
        DateFormat('dd/MM/yyyy HH:mm').format(date),
        title,
        subtitle,
        isIncome ? currencyFormat.format(value) : "$value Pcs"
      ];
    }).toList();

    // Buat Halaman PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header Laporan
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("CHUPATU MOBILE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                      pw.Text("Laporan Keuangan & Stok", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Periode", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(_selectedRange, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    ],
                  )
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Kotak Ringkasan
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  color: PdfColors.grey100
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Tipe Laporan"),
                      pw.Text(isIncome ? "PEMASUKAN (INCOME)" : "PENGELUARAN (STOK MASUK)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: isIncome ? PdfColors.green700 : PdfColors.red700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Total Nilai"),
                      pw.Text(isIncome ? currencyFormat.format(totalAmount) : "$totalAmount Pcs", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tabel Data
            pw.Table.fromTextArray(
              headers: ['Tanggal', 'Item/Layanan', 'Ket/Customer', 'Nilai'],
              data: tableData,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: isIncome ? PdfColors.green600 : PdfColors.red600),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {3: pw.Alignment.centerRight},
              cellPadding: const pw.EdgeInsets.all(6),
            ),
            pw.SizedBox(height: 20),
            pw.Footer(
              leading: pw.Text(DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now()), style: const pw.TextStyle(fontSize: 8)),
              trailing: pw.Text("Generated by System", style: const pw.TextStyle(fontSize: 8)),
            )
          ];
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Laporan_${isIncome ? "Pemasukan" : "Pengeluaran"}_$_selectedRange.pdf'
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
              title: Text("Portfolio Keuangan", style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: theme.textMain, fontSize: 18)),
              backgroundColor: theme.surface, // Adaptif
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textMain),
              bottom: TabBar(
                controller: _tabController,
                labelColor: theme.textMain,
                unselectedLabelColor: Colors.grey,
                indicatorColor: theme.textMain,
                labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                tabs: const [ Tab(text: "Pemasukan"), Tab(text: "Pengeluaran") ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [ _buildIncomeView(theme), _buildExpenseView(theme) ],
            ),
          );
        }
    );
  }

  // =========================================================================
  // VIEW PEMASUKAN
  // =========================================================================
  Widget _buildIncomeView(AppThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings')
          .where('status', isEqualTo: 'Done')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_getStartDate()))
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data?.docs ?? [];

        List<DocumentSnapshot> sortedDocs = List.from(docs);
        sortedDocs.sort((a, b) => (a['createdAt'] as Timestamp).toDate().compareTo((b['createdAt'] as Timestamp).toDate()));

        int totalRevenue = 0;
        List<FlSpot> spots = [];
        for (int i = 0; i < sortedDocs.length; i++) {
          var data = sortedDocs[i].data() as Map<String, dynamic>;
          int price = data['totalPrice'] ?? 0;
          totalRevenue += price;
          spots.add(FlSpot(i.toDouble(), price.toDouble()));
        }

        Map<String, int> serviceCount = {};
        Map<String, Map<String, dynamic>> customerStats = {};
        int maxOrderValue = 0;

        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          int price = data['totalPrice'] ?? 0;
          String service = data['serviceName'] ?? 'Lainnya';
          serviceCount[service] = (serviceCount[service] ?? 0) + 1;
          String customer = data['customerName'] ?? 'Guest';
          if (!customerStats.containsKey(customer)) {
            customerStats[customer] = {'count': 0, 'total': 0};
          }
          customerStats[customer]!['count'] += 1;
          customerStats[customer]!['total'] += price;
          if (price > maxOrderValue) maxOrderValue = price;
        }

        var sortedServices = serviceCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        var sortedCustomers = customerStats.entries.toList();
        if (_customerSortType == 'Terbanyak') {
          sortedCustomers.sort((a, b) => b.value['count'].compareTo(a.value['count']));
        } else {
          sortedCustomers.sort((a, b) => b.value['total'].compareTo(a.value['total']));
        }

        final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        String displayValue = _touchedValue != null ? currencyFormat.format(_touchedValue) : currencyFormat.format(totalRevenue);
        String displayLabel = _touchedDate ?? "Total Pemasukan ($_selectedRange)";

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(displayLabel, displayValue, docs.length, true, theme, () => _generatePdf(docs, true)),
              _buildChart(spots, sortedDocs, true, theme),
              _buildTimeSelector(theme),

              Divider(thickness: 8, color: theme.surface),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Analisa Performa ($_selectedRange)", style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatBox("Banyaknya Order", "${docs.length} Trx", Icons.receipt_long, theme),
                        const SizedBox(width: 12),
                        _buildStatBox("Order Tertinggi", currencyFormat.format(maxOrderValue), Icons.emoji_events, theme),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text("Layanan Terlaris", style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textMain)),
                    const SizedBox(height: 12),
                    if (sortedServices.isEmpty) Text("-", style: TextStyle(color: theme.textMain)) else
                      Column(
                        children: sortedServices.take(5).map((e) {
                          double percentage = (e.value / docs.length);
                          return _buildProgressBar(e.key, "${e.value} Order", percentage, _stockGreen, theme);
                        }).toList(),
                      ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("List Pelanggan (${sortedCustomers.length})", style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textMain)),
                        DropdownButton<String>(
                          value: _customerSortType,
                          style: GoogleFonts.manrope(fontSize: 12, color: theme.textMain, fontWeight: FontWeight.bold),
                          dropdownColor: theme.surface,
                          underline: Container(),
                          icon: Icon(Icons.sort, size: 16, color: theme.textMain),
                          items: ['Terbanyak', 'Termahal'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => _customerSortType = val!),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (sortedCustomers.isEmpty) Text("-", style: TextStyle(color: theme.textMain)) else
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedCustomers.length,
                          separatorBuilder: (c,i) => Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                          itemBuilder: (context, index) {
                            var entry = sortedCustomers[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: index < 3 ? Colors.amber.shade100 : theme.surface,
                                child: Text((index+1).toString(), style: TextStyle(color: index < 3 ? Colors.amber.shade800 : theme.textMain, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(entry.key, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textMain)),
                              subtitle: Text(currencyFormat.format(entry.value['total']), style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey)),
                              trailing: Text("${entry.value['count']}x Order", style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: theme.textMain, fontSize: 12)),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              Divider(thickness: 8, color: theme.surface),
              _buildTransactionList(docs, true, theme),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // VIEW PENGELUARAN
  // =========================================================================
  Widget _buildExpenseView(AppThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('inventory_logs')
          .where('type', isEqualTo: 'in')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_getStartDate()))
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data?.docs ?? [];

        List<DocumentSnapshot> sortedDocs = List.from(docs);
        sortedDocs.sort((a, b) => (a['createdAt'] as Timestamp).toDate().compareTo((b['createdAt'] as Timestamp).toDate()));

        int totalItems = 0;
        List<FlSpot> spots = [];
        Map<String, int> itemCounts = {};

        for (int i = 0; i < sortedDocs.length; i++) {
          var data = sortedDocs[i].data() as Map<String, dynamic>;
          int amount = data['amount'] ?? 0;
          totalItems += amount;
          spots.add(FlSpot(i.toDouble(), amount.toDouble()));
          String name = data['itemName'] ?? 'Item';
          itemCounts[name] = (itemCounts[name] ?? 0) + amount;
        }

        var sortedItems = itemCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        String displayValue = _touchedValue != null ? "${_touchedValue!.toInt()} Pcs" : "$totalItems Pcs";
        String displayLabel = _touchedDate ?? "Total Stok Masuk ($_selectedRange)";

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(displayLabel, displayValue, docs.length, false, theme, () => _generatePdf(docs, false)),
              _buildChart(spots, sortedDocs, false, theme),
              _buildTimeSelector(theme),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Barang Paling Sering Dibeli", style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textMain)),
                    const SizedBox(height: 12),
                    if (sortedItems.isEmpty) Text("-", style: TextStyle(color: theme.textMain)) else
                      Column(
                        children: sortedItems.take(5).map((e) {
                          double percentage = totalItems > 0 ? (e.value / totalItems) : 0;
                          return _buildProgressBar(e.key, "${e.value} Pcs", percentage, _stockRed, theme);
                        }).toList(),
                      ),
                  ],
                ),
              ),

              Divider(thickness: 8, color: theme.surface),
              _buildTransactionList(docs, false, theme),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET PENDUKUNG ---

  Widget _buildProgressBar(String label, String value, double percentage, Color color, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.manrope(fontSize: 13, color: theme.textMain)),
              Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textMain)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: Colors.grey.withOpacity(0.2),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, AppThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String label, String value, int count, bool isIncome, AppThemeData theme, VoidCallback onPrint) {
    Color color = isIncome ? _stockGreen : _stockRed;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.manrope(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(value, style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: theme.textMain)), const SizedBox(height: 4), Row(children: [Icon(isIncome ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: color, size: 20), Text("$count Transaksi", style: GoogleFonts.manrope(color: color, fontWeight: FontWeight.bold, fontSize: 13))])]),
          IconButton(
            onPressed: onPrint,
            icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.share_rounded, size: 20, color: theme.textMain)),
            tooltip: "Download/Share Laporan",
          )
        ],
      ),
    );
  }

  Widget _buildChart(List<FlSpot> spots, List<DocumentSnapshot> sourceData, bool isIncome, AppThemeData theme) {
    Color color = isIncome ? _stockGreen : _stockRed;
    return Container(height: 250, padding: const EdgeInsets.symmetric(horizontal: 10), child: spots.isEmpty ? Center(child: Text("Tidak ada data", style: GoogleFonts.manrope(color: Colors.grey))) : LineChart(LineChartData(gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)), titlesData: FlTitlesData(show: false), borderData: FlBorderData(show: false), lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipItems: (touchedSpots) { return touchedSpots.map((LineBarSpot touchedSpot) { return LineTooltipItem(isIncome ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(touchedSpot.y) : "${touchedSpot.y.toInt()} Pcs", TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)); }).toList(); }), touchCallback: (event, touchResponse) { if (touchResponse != null && touchResponse.lineBarSpots != null && event is! FlPanEndEvent && event is! FlTapUpEvent) { final value = touchResponse.lineBarSpots![0].y; final index = touchResponse.lineBarSpots![0].x.toInt(); if (index >= 0 && index < sourceData.length) { DateTime dt = (sourceData[index]['createdAt'] as Timestamp).toDate(); setState(() { _touchedValue = value; _touchedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt); }); } } else { setState(() { _touchedValue = null; _touchedDate = null; }); } }), lineBarsData: [LineChartBarData(spots: spots, isCurved: true, curveSmoothness: 0.35, color: color, barWidth: 2, isStrokeCapRound: true, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withOpacity(0.2), color.withOpacity(0.0)])))])));
  }

  Widget _buildTimeSelector(AppThemeData theme) {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), child: Row(children: _ranges.map((range) { bool isSelected = _selectedRange == range; return GestureDetector(onTap: () => setState(() => _selectedRange = range), child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isSelected ? theme.primary : theme.surface, borderRadius: BorderRadius.circular(20)), child: Text(range, style: GoogleFonts.manrope(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)))); }).toList()));
  }

  Widget _buildTransactionList(List<QueryDocumentSnapshot> docs, bool isIncome, AppThemeData theme) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    Color color = isIncome ? _stockGreen : _stockRed;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), child: Text("Riwayat Detail ($_selectedRange)", style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain))), ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: docs.length, itemBuilder: (context, index) { var data = docs[index].data() as Map<String, dynamic>; DateTime dt = (data['createdAt'] as Timestamp).toDate(); String title = isIncome ? (data['serviceName'] ?? 'Service') : (data['itemName'] ?? 'Item'); String subtitle = isIncome ? (data['customerName'] ?? 'User') : "Stok Masuk"; String valueStr = isIncome ? currencyFormat.format(data['totalPrice'] ?? 0) : "+${data['amount']} Pcs"; return Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain)), const SizedBox(height: 4), Text("${DateFormat('dd MMM HH:mm').format(dt)} • $subtitle", style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey))])), Text(valueStr, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14, color: color))])); })]);
  }
}