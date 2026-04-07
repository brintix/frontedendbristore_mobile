// recipe_helper.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/cart_model.dart';

class ReceiptData {
  final String invoiceNumber;
  final String userName;
  final String storeName;    // Tambahan: Nama Toko dinamis
  final String storeAddress; // Tambahan: Alamat Toko dinamis
  final Map<int, CartItemModel> cartItems;
  final double totalAmount;
  final double cashPaid;
  final double change;
  final String paymentMethodName;
  final DateTime transactionTime;
  final List<String> appliedPromotions;

  ReceiptData({
    required this.invoiceNumber,
    required this.userName,
    required this.storeName,    // Wajib diisi saat inisialisasi
    required this.storeAddress, // Wajib diisi saat inisialisasi
    required this.cartItems,
    required this.totalAmount,
    required this.cashPaid,
    required this.change,
    required this.paymentMethodName,
    required this.transactionTime,
    this.appliedPromotions = const [],
  });
}

class ReceiptHelper {
  // Helper internal untuk format waktu agar seragam di PDF & Thermal
  static String _formatDate(DateTime dt) =>
      "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";

  static String _formatTime(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  // ── Generate PDF ──────────────────────────────────────────────────────────
  static Future<void> sharePdf(ReceiptData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header Dinamis
            pw.Center(
              child: pw.Text(
                data.storeName, // Menggunakan data dari parameter
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                data.storeAddress, // Menggunakan data dari parameter
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),

            // Info Transaksi
            _pdfRow("Invoice", data.invoiceNumber),
            _pdfRow("Kasir", data.userName),
            _pdfRow("Tanggal", _formatDate(data.transactionTime)),
            _pdfRow("Jam", _formatTime(data.transactionTime)),
            pw.Divider(thickness: 0.5),

            // Item Pembelian
            pw.Text("ITEM",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 4),
            ...data.cartItems.values.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          "${item.product.name} x${item.quantity}",
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Text(
                        "Rp ${item.totalItemPrice.toStringAsFixed(0)}",
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                )),
            pw.Divider(thickness: 0.5),

            // Promosi
            if (data.appliedPromotions.isNotEmpty) ...[
              pw.Text("Promosi",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ...data.appliedPromotions.map(
                (p) => pw.Text("• $p", style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Divider(thickness: 0.5),
            ],

            // Total
            _pdfRow("Total", "Rp ${data.totalAmount.toStringAsFixed(0)}", bold: true),
            _pdfRow("Metode", data.paymentMethodName),
            _pdfRow("Dibayar", "Rp ${data.cashPaid.toStringAsFixed(0)}"),
            _pdfRow("Kembalian", "Rp ${data.change.toStringAsFixed(0)}", bold: true),
            pw.SizedBox(height: 12),

            // Footer
            pw.Center(
              child: pw.Text(
                "Terima kasih telah berbelanja!",
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: "INV-${data.invoiceNumber}.pdf",
    );
  }

  static pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ── Generate ESC/POS untuk Thermal Printer ────────────────────────────────
  static List<Map<String, dynamic>> buildThermalCommands(ReceiptData data) {
    final List<Map<String, dynamic>> commands = [];

    void addText(String text, {bool bold = false, bool center = false}) {
      commands.add({
        'type': 'text',
        'content': text,
        'bold': bold,
        'align': center ? 'center' : 'left',
      });
    }

    void addLine() => addText('--------------------------------');

    // Menggunakan Nama & Alamat Toko dinamis
    addText(data.storeName, bold: true, center: true);
    addText(data.storeAddress, center: true);
    addLine();
    addText("Invoice : ${data.invoiceNumber}");
    addText("Kasir   : ${data.userName}");
    addText("Tanggal : ${_formatDate(data.transactionTime)}");
    addText("Jam     : ${_formatTime(data.transactionTime)}");
    addLine();

    for (final item in data.cartItems.values) {
      addText("${item.product.name} x${item.quantity}");
      addText("  Rp ${item.totalItemPrice.toStringAsFixed(0)}");
    }
    addLine();

    if (data.appliedPromotions.isNotEmpty) {
      addText("Promosi:", bold: true);
      for (final promo in data.appliedPromotions) {
        addText("- $promo");
      }
      addLine();
    }
    addText("Total    : Rp ${data.totalAmount.toStringAsFixed(0)}", bold: true);
    addText("Metode   : ${data.paymentMethodName}");
    addText("Dibayar  : Rp ${data.cashPaid.toStringAsFixed(0)}");
    addText("Kembalian: Rp ${data.change.toStringAsFixed(0)}", bold: true);
    addLine();
    addText("Terima kasih telah berbelanja!", center: true);

    return commands;
  }
}