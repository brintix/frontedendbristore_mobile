// lib/data/models/cart_model.dart
import '../sources/product_service.dart';

class CartItemModel {
  final FinishedProductModel product;
  
  // Menggunakan double agar mendukung input desimal (kg, liter, jam)
  double quantity;

  CartItemModel({required this.product, required this.quantity});

  // Tambahkan fungsi setQuantity
  void updateQuantity(double newQty) {
    quantity = newQty;
  }

  // Getter untuk menghitung total harga per item
  double get totalItemPrice {
    double price = double.tryParse(product.price.toString()) ?? 0.0;
    return price * quantity; 
  }

  // Fungsi untuk menambah jumlah (Default tambah 1, bisa diatur manual)
  void increment({double step = 1.0}) {
    quantity += step;
  }

  // Fungsi untuk mengurangi jumlah
  void decrement({double step = 1.0}) {
    if (quantity - step >= 0) {
      quantity -= step;
    } else {
      quantity = 0;
    }
  }

  // Helper untuk menampilkan kuantitas di UI dengan rapi
  String get formattedQuantity {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    return quantity.toStringAsFixed(2);
  }
}
