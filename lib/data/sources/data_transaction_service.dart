import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart'; // Import AuthService untuk akses instance Dio-nya
import '../models/transaction_model.dart';

class DataTransactionService {
  final AuthService _authService = AuthService();

  /// Fungsi untuk mengambil daftar transaksi berdasarkan store_id
  Future<TransactionResponse?> getTransactions({String? from, String? to}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? storeId = prefs.getInt('store_id');

      if (storeId == null) {
        log("Gagal mengambil Transaksi: storeId tidak ditemukan", name: "API_LOG");
        return null;
      }

      // Memanggil API menggunakan instance dio dari AuthService
      final response = await _authService.dio.get(
        '/transactions',
          queryParameters: {
            'from': from, // Kirim saja, Dio biasanya akan mengabaikan jika nilainya null
            'to': to,
        }..removeWhere((k, v) => v == null),
      );

      if (response.statusCode == 200) {
        // Map data menggunakan model yang sudah kita buat
        return TransactionResponse.fromJson(response.data);
      } else {
        log("Gagal memuat transaksi: ${response.statusCode}", name: "API_LOG");
        return null;
      }
    } on DioException catch (e) {
    // Log detail error untuk mempermudah debugging
      log("Error API Transaction (${e.response?.statusCode}): ${e.message}", name: "API_LOG");
      return null;

    } catch (e) {
      log("Error Tak Terduga (Transaction): $e", name: "API_LOG");
      return null;
    }
    
  }
}