// recipe_helper.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
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
            pw.Center(
              child: pw.Text(
                data.storeName,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(
              child: pw.Text(
                data.storeAddress,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),

            _pdfRow("Invoice", data.invoiceNumber),
            _pdfRow("Kasir", data.userName),
            _pdfRow("Tanggal", _formatDate(data.transactionTime)),
            _pdfRow("Jam", _formatTime(data.transactionTime)),
            pw.Divider(thickness: 0.5),

            pw.Text("ITEM", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
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

            if (data.appliedPromotions.isNotEmpty) ...[
              pw.Text("Promosi", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ...data.appliedPromotions.map((p) => pw.Text("• $p", style: const pw.TextStyle(fontSize: 9))),
              pw.Divider(thickness: 0.5),
            ],

            _pdfRow("Total", "Rp ${data.totalAmount.toStringAsFixed(0)}", bold: true),
            _pdfRow("Metode", data.paymentMethodName),
            _pdfRow("Dibayar", "Rp ${data.cashPaid.toStringAsFixed(0)}"),
            _pdfRow("Kembalian", "Rp ${data.change.toStringAsFixed(0)}", bold: true),
            pw.SizedBox(height: 12),

            pw.Center(
              child: pw.Text("Terima kasih telah berbelanja!", style: const pw.TextStyle(fontSize: 9)),
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

  // ── Generate ESC/POS (Bytes) untuk Thermal Printer ────────────────────────
  static Future<List<int>> buildThermalBytes(ReceiptData data) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(data.storeName,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text(data.storeAddress, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // Info
    bytes += generator.text("Invoice : ${data.invoiceNumber}");
    bytes += generator.text("Kasir   : ${data.userName}");
    bytes += generator.text("Waktu   : ${_formatDate(data.transactionTime)} ${_formatTime(data.transactionTime)}");
    bytes += generator.hr();

    // Items
    for (final item in data.cartItems.values) {
      bytes += generator.text(item.product.name, styles: const PosStyles(bold: true));
      bytes += generator.row([
        PosColumn(text: "${item.quantity} x ${item.product.price.toStringAsFixed(0)}", 
          width: 7),
        PosColumn(
            text: "Rp ${item.totalItemPrice.toStringAsFixed(0)}",
            width: 5,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr();

    // Total & Pembayaran
    bytes += generator.row([
      PosColumn(text: "TOTAL", width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
          text: "Rp ${data.totalAmount.toStringAsFixed(0)}",
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.text("Metode  : ${data.paymentMethodName}");
    bytes += generator.text("Dibayar : Rp ${data.cashPaid.toStringAsFixed(0)}");
    bytes += generator.text("Kembali : Rp ${data.change.toStringAsFixed(0)}", styles: const PosStyles(bold: true));
    
    bytes += generator.hr();
    bytes += generator.text("Terima Kasih", styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }
}
/*
saya sudah punya recip_helper.dart untuk menangani value yang di cetak
sesuaikan denagn ini dan buatkan lagi payment_sheet.dart
*/ 