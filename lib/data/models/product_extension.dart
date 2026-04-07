import 'package:flutter/material.dart';
import '../../data/sources/product_service.dart';

extension ProductDisplayExtension on FinishedProductModel {
  // 1. Logika Teks Stok
  String get stockDisplay {
    if (productType == 'SERVICE' || category.toLowerCase().contains('jasa')) {
      return "Layanan Jasa";
    }
    
    // Konversi string ke double untuk pengecekan angka bulat vs desimal
    double s = double.tryParse(stock.toString()) ?? 0.0;
    
    if (s <= 0) return "Stok Habis";
    
    // Jika angka bulat (misal 10.0), tampilkan "10". Jika desimal (1.5), tampilkan "1.50"
    return s % 1 == 0 ? s.toInt().toString() : s.toStringAsFixed(2);
  }

  // 2. Logika Warna Stok (Opsional tapi sangat membantu)
  Color get stockColor {
    if (productType == 'SERVICE') return Colors.green;
    
    double s = double.tryParse(stock.toString()) ?? 0.0;
    if (s <= 0) return Colors.red;
    if (s < 5) return Colors.orange; // Peringatan stok menipis
    return Colors.grey;
  }
  
  // 3. Cek apakah ini barang timbangan (berdasarkan unit)
  bool get isWeightBased {
    final unit = baseUnit.toLowerCase();
    return unit == 'kg' || unit == 'gram' || unit == 'liter';
  }
}