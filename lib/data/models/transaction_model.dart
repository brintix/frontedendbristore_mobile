import 'package:intl/intl.dart';

class TransactionModel {
  final String createdAt;
  final String invoiceNumber;
  final String totalAmount;
  final String status;

  TransactionModel({
    required this.createdAt,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.status,
  });

  // Fungsi untuk konversi JSON ke Object
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      createdAt: json['created_at'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      totalAmount: json['total_amount'] ?? '0',
      status: json['status'] ?? '',
    );
  }

  // Helper untuk memformat total_amount ke Rupiah (Contoh: Rp 33.600)
  String get formattedTotal {
    final number = double.tryParse(totalAmount) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  // Helper untuk warna status
  bool get isPaid => status.toLowerCase() == 'paid';
}

// Model pembungkus untuk response list
class TransactionResponse {
  final bool success;
  final String message;
  final List<TransactionModel> data;

  TransactionResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] is List 
        ? (json['data'] as List).map((i) => TransactionModel.fromJson(i)).toList()
        : [TransactionModel.fromJson(json['data'])],
    );
  }
}