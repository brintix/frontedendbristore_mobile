// payment_methode.dart
class PaymentMethodModel {
  final int id;
  final int storeId;
  final String name;

  PaymentMethodModel({
    required this.id,
    required this.storeId,
    required this.name,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    // Fungsi pembantu untuk konversi angka yang aman
    int safeInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PaymentMethodModel(
      id: safeInt(json['id']),
      storeId: safeInt(json['store_id']),
      name: json['name']?.toString() ?? 'Metode Tanpa Nama',
    );
  }
}