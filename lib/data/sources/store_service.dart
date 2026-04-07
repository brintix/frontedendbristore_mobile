import 'dart:developer';
import 'package:dio/dio.dart';
import 'auth_service.dart'; // Sesuaikan path AuthService Anda

class StoreService {
  // Mengambil instance Dio yang sudah terkonfigurasi dengan BaseURL & Token
  final Dio _dio = AuthService().dio;

  Future<Map<String, dynamic>?> getStoreDetail(int storeId) async {
    try {
      final response = await _dio.get('/stores/$storeId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      log("Error fetching store: $e");
      return null;
    }
  }
}