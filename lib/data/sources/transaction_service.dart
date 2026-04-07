// transaction_service.dart

import 'dart:developer'; 
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../models/cart_model.dart';
import 'auth_service.dart';

class TransactionService {
  final Dio _dio = AuthService().dio;

  // STAY: Nama function tidak diubah
  Future<Map<String, dynamic>> createTransaction({
    required Map<int, CartItemModel> cartItems,
    String? couponCode,
  }) async {
    try {
      // PERBAIKAN: Menggunakan double.parse karena quantity sekarang bisa desimal (1.0, 1.5, dst)
      List<Map<String, dynamic>> itemsJson = cartItems.values.map((item) {
        return {
          // product_id tetap int karena ID tidak mungkin desimal
          "product_id": int.tryParse(item.product.id.toString()) ?? 0,
          // quantity diubah ke double agar mendukung Format desimal
          "quantity": double.tryParse(item.quantity.toString()) ?? 0.0,
        };
      }).toList();

      final data = {
        "couponCode": couponCode, 
        "items": itemsJson,
      };

      log("DATA DIKIRIM KE API: $data", name: "TX_DEBUG");

      final response = await _dio.post('/transactions', data: data);
      return response.data;

    } on DioException catch (e) {
      log("STATUS: ${e.response?.statusCode}", name: "TX_DEBUG");
      log("DETAIL SERVER: ${e.response?.data}", name: "TX_DEBUG");

      String errorMessage = "Gagal membuat transaksi";
      
      if (e.response?.data != null && e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? 
                       e.response?.data['error'] ?? 
                       "Error ${e.response?.statusCode}: Input tidak valid";
      }

      throw Exception(errorMessage);
    } catch (e) {
      log("UNEXPECTED ERROR: $e", name: "TX_DEBUG");
      throw Exception("Terjadi kesalahan sistem: $e");
    }
  }

  // STAY: Nama function tidak diubah
  Future<Map<String, dynamic>> processPayment({
    required int transactionId,
    required int paymentMethodId,
    required num amount,
    required String referenceNumber,
  }) async {
    try {
      final data = {
        "store_payment_method_id": paymentMethodId,
        // Gunakan .round() atau .toInt() untuk nominal uang karena biasanya mata uang adalah bulat
        "amount": amount.round(),
        "reference_number": referenceNumber,
      };

      log("PAYMENT DATA DIKIRIM: $data", name: "TX_DEBUG");
      final response = await _dio.post(
        '/transactions/$transactionId/payments',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      log("PAYMENT ERROR BODY: ${e.response?.data}", name: "TX_DEBUG");
      String errorMessage =
          e.response?.data['message'] ?? "Gagal mencatat pembayaran";
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Terjadi kesalahan sistem pembayaran: $e");
    }
  }

  // STAY: Nama function tidak diubah
  Future<List<dynamic>> fetchPaymentMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? storeId = prefs.getInt('store_id');

      if (storeId == null) {
        throw Exception("ID Toko tidak ditemukan. Silakan login ulang.");
      }

      final Response response = await _dio.get('/paymentmethode/store/$storeId/list');

      final responseData = response.data;
      if (responseData is Map && responseData['success'] == true) {
        final data = responseData['data'];
        if (data is List) return data;
        throw Exception("Format data metode pembayaran tidak valid");
      } else {
        final msg = responseData is Map
            ? responseData['message'] ?? "Gagal mengambil metode pembayaran"
            : "Respons tidak dikenali dari server";
        throw Exception(msg);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception("Koneksi timeout. Coba lagi beberapa saat.");
      }
      if (e.response?.statusCode == 401) {
        throw Exception("Sesi login habis. Silakan login ulang.");
      }
      throw Exception(
          e.response?.data?['message'] ?? "Error koneksi payment method");
    }
  }
}