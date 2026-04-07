import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  late Dio _dio;

  AuthService() {
    // Inisialisasi Dio
    _dio = Dio(
      BaseOptions(
        // baseUrl: "https://apistoresbristore.vercel.app/api",
        baseUrl: "http://10.0.2.2:3000/api",
        // baseUrl: "http://192.168.100.164:2404/api",
        
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Interceptor untuk otomatis menambahkan token ke setiap request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          log("--- MENGIRIM REQUEST [${options.method}] ---", name: "API_LOG");
          log("URL: ${options.uri}", name: "API_LOG");

          // Ambil token yang sudah disimpan setelah login
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');

          // Jika token ada, otomatis pasang ke header Authorization
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            log("TOKEN DIPASANG KE HEADER", name: "API_LOG");
          }

          return handler.next(options);
        },

        onResponse: (response, handler) {
          log("--- TERIMA RESPON [${response.statusCode}] ---", name: "API_LOG");
          log("DATA: ${response.data}", name: "API_LOG");
          return handler.next(response);
        },

        onError: (DioException e, handler) {
          log("--- TERJADI ERROR ---", name: "API_LOG");
          log("PESAN: ${e.message}", name: "API_LOG");

          if (e.response?.statusCode == 401) {
            log("Token tidak valid atau sudah expired", name: "API_LOG");
          }

          return handler.next(e);
        },
      ),
    );
  }

  // Getter agar Dio bisa dipakai oleh service lain seperti ProductService
  Dio get dio => _dio;

  // Function login
  Future<Response?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        "/auth/login",
        data: {
          "email": email,
          "password": password,
        },options: Options(
          headers: {
            "Accept": "application/json", // Wajib agar server tahu ini request API
          },),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final userData = response.data['data']['user'];

        final token = response.data['data']['token'];
        final String name = userData['name'];
        final int roleId = userData['role_id'];
        final int storeId = userData['store_id'];

        // Simpan ke local storage
        await prefs.setString('token', token);
        await prefs.setString('name', name);
        await prefs.setInt('role_id', roleId);
        await prefs.setInt('store_id', storeId);

        log("STORE ID DISIMPAN: $storeId", name: "API_LOG");
      }

      return response;
    } on DioException catch (e) {
      return e.response;
    } catch (e) {
      log("Error Tak Terduga: $e", name: "API_LOG");
      return null;
    }
  }

  /// --- FUNGSI BARU UNTUK MENGAMBIL PAYMENT METHOD ---
  Future<Response?> getPaymentMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Ambil store_id yang disimpan saat login tadi
      final int? storeId = prefs.getInt('store_id');

      if (storeId == null) {
        log("Gagal mengambil Payment Methods: storeId tidak ditemukan di local storage", name: "API_LOG");
        return null;
      }

      // Gunakan storeId yang berhasil diambil
      final response = await _dio.get('/paymentmethode/store/$storeId/list');
      return response;
    } on DioException catch (e) {
      log("Error API Payment: ${e.message}", name: "API_LOG");
      return e.response;
    } catch (e) {
      log("Error Tak Terduga: $e", name: "API_LOG");
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('name');
    await prefs.remove('role_id');
    await prefs.remove('store_id');
    log('Semua data session dihapus', name: 'AUTH_SERVICE');
  }
}
