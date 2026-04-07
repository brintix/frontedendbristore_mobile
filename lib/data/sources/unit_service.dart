import 'dart:developer';
import 'package:dio/dio.dart';
import '../../data/models/base_unit_model.dart';
import 'auth_service.dart';

class UnitService {
  // Menggunakan instance Dio yang sama dengan AuthService agar Header Token ikut terbawa
  final Dio _dio = AuthService().dio;

  Future<List<UnitModel>> fetchUnits() async {
    try {
      // Sesuaikan endpoint ini dengan backend Anda (contoh: /units atau /base-units)
      final response = await _dio.get('/units'); 

      if (response.statusCode == 200) {
        // Asumsi struktur response API Anda: { "success": true, "data": [...] }
        final List<dynamic> data = response.data['data'];
        
        return data.map((json) => UnitModel.fromJson(json)).toList();
      } else {
        throw Exception("Gagal mengambil data satuan");
      }
    } on DioException catch (e) {
      log("Error UnitService: ${e.response?.data}", name: "UNIT_DEBUG");
      throw Exception(e.response?.data['message'] ?? "Terjadi kesalahan koneksi");
    }
  }
}