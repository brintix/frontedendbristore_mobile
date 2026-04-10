import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  late Dio _dio;

  AuthService() {
    // Inisialisasi Dio
    _dio = Dio(
      BaseOptions(
        baseUrl: "https://apistoresbristore.vercel.app/api",
        // baseUrl: "http://10.0.2.2:3000/api", /*emulator*/
        // baseUrl: "http://172.15.15.172:3000/api",
        // baseUrl : "http://localhost:3000/api", /*Port Forwarding Chrome*/
        
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
  Future<Response?> login(String name, String password) async {
    try {
      final response = await _dio.post(
        "/auth/login",
        data: {
          "name": name,
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
        final String userRoleName = userData['role_name']?.toString() ?? '';
        final int storeId = int.tryParse(userData['store_id'].toString()) ?? 0;


        // Simpan ke local storage
        await prefs.setString('token', token);
        await prefs.setString('name', name);
        await prefs.setInt('role_id', roleId);
        await prefs.setString('role_name', userRoleName);
        await prefs.setInt('store_id', storeId);

        log("LOGIN SUKSES - Name: $name, Role: $userRoleName (ID : $roleId), Store: $storeId", name: "API_LOG");
        log("DEBUG - rawStoreId type: ${userData['store_id'].runtimeType}, value: ${userData['store_id']}", name: "API_LOG");
        
      }
      return response;
    } on DioException catch (e) {
      return e.response;
    } catch (e) {
      log("Error Tak Terduga: $e", name: "API_LOG");
      return null;
    }
  }

  // 
  Future<Response> selectStore(int storeId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return await _dio.post(
      '/auth/select-store',
      data: {'store_id': storeId},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
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
// ini auth_service.dart