// product_service.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'auth_service.dart';
import '../models/base_unit_model.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

// --- MODEL UNTUK PRODUK JADI (KASIR) ---
// Model ini diletakkan di sini agar praktis, atau bisa kamu pindah ke folder models.
class FinishedProductModel {
  final int id;
  final String name;
  final String productType;
  final String sku;            
  final String? barcode;  // ← Ganti dari kodeBarang ke barcode
  final int? baseUnitId;
  final String? image;
  final String category;
  final double stock;
  final double price;
  final String baseUnit;
  final bool trackStock;

  FinishedProductModel({
    required this.id,
    required this.name,
    required this.productType,
    required this.sku,
    this.barcode,  // ← Sesuaikan
    this.baseUnitId,
    this.image,
    required this.category,
    required this.stock,
    required this.price,
    required this.baseUnit,
    required this.trackStock,
  });

  factory FinishedProductModel.fromJson(Map<String, dynamic> json) {
    // 1. HARGA: Langsung ambil dari key 'price' (karena sudah bukan array lagi)
    // Gunakan toString() dulu baru double.tryParse agar aman jika nilainya null
    final priceValue = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;

    return FinishedProductModel(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0), 
      productType: json['product_type']?.toString() ?? 'FINISHED',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '-',
      barcode: json['barcode']?.toString(), // barcode sekarang string langsung atau null
      image: json['image']?.toString(),
      category: json['category']?.toString() ?? '-',
      
      // 2. STOK: Tangani nilai null (seperti pada jasa Cuci Reguler)
      stock: double.tryParse(json['stock']?.toString() ?? '0') ?? 0.0,
      
      price: priceValue,

      // 3. UNIT: Di JSON baru tidak ada field 'base_unit', 
      // kita berikan default 'pcs' atau sesuaikan jika API nanti ditambahkan field ini
      baseUnit: json['base_unit']?.toString() ?? 'pcs',
      baseUnitId: json['base_unit_id'] != null 
          ? int.tryParse(json['base_unit_id'].toString()) 
          : null,
          
      trackStock: json['track_stock'] ?? (json['product_type'] == 'FINISHED'),
    );
  }
}

class ProductService {
  // Menggunakan Dio dari AuthService agar interceptor dan token otomatis terpasang
  final Dio _dio = AuthService().dio;

Future<List<ProductModel>> fetchProducts(int storeId) async {
  // 1. Mulai transaksi untuk memantau kecepatan (Tracing)
  final transaction = Sentry.startTransaction(
    'fetchProducts', 
    'http.client',
    description: 'Mengambil produk dari store $storeId',
  );

  try {
    log("Mengambil product untuk store_id: $storeId", name: "PRODUCT_SERVICE");

    final response = await _dio.get(
      "/products",
      queryParameters: {"store_id": storeId},
    );

    if (response.statusCode == 200) {
      List<dynamic> rawProducts = [];
      
      if (response.data is Map<String, dynamic>) {
        rawProducts = response.data["data"] ?? [];
      } else if (response.data is List) {
        rawProducts = response.data;
      }

      final result = await compute(_parseProducts, rawProducts);
      
      // 2. Tandai transaksi sukses
      transaction.status = const SpanStatus.ok();
      return result;
    }
    
    throw Exception("Gagal mengambil product: ${response.statusCode}");
  } catch (e, stackTrace) {
    // 3. Kirim error ke Sentry dashboard (termasuk jika timeout ke India)
    await Sentry.captureException(e, stackTrace: stackTrace);
    
    // 4. Tandai transaksi gagal
    transaction.throwable = e;
    transaction.status = const SpanStatus.internalError();
    
    log("Error fetchProducts: $e", name: "PRODUCT_SERVICE");
    throw Exception("Terjadi kesalahan: $e");
  } finally {
    // 5. Selesaikan transaksi agar data terkirim ke dashboard Sentry
    await transaction.finish();
  }
}

  // 2. FUNGSI UNTUK PRODUK JADI (KASIR / FINISHED)
  // Fungsi ini yang akan dipanggil di CashierPage
Future<List<FinishedProductModel>> fetchFinishedProducts(int storeId) async {
  try {
    log("Mengambil produk jadi (finished) untuk Kasir", name: "PRODUCT_SERVICE");

    final response = await _dio.get(
      "/products/finished",
      queryParameters: {"store_id": storeId},
    );

    if (response.statusCode == 200) {
      final dynamic responseBody = response.data;
      List<dynamic> listData = [];

      if (responseBody is Map<String, dynamic>) {
        listData = responseBody['data'] ?? [];
      } else if (responseBody is List) {
        listData = responseBody;
      }

      // --- PERUBAHAN DI SINI ---
      // Gunakan compute agar parsing ribuan produk tidak membuat UI Kasir lag
      final products = await compute(_parseFinishedProducts, listData);
      
      log("Jumlah produk jadi ditemukan: ${products.length}", name: "PRODUCT_SERVICE");
      return products;
    }

    throw Exception("Gagal mengambil produk kasir. Status: ${response.statusCode}");
  } on DioException catch (e) {
    log("Dio Error Finished: ${e.response?.data}", name: "PRODUCT_SERVICE");
    throw Exception(e.response?.data['message'] ?? "Gagal mengambil data kasir");
  } catch (e) {
    log("Unexpected Error Finished: $e", name: "PRODUCT_SERVICE");
    throw Exception("Error fetchFinishedProducts: $e");
  }
}


  // Di dalam class ProductService
  Future<bool> addCategory(String name, int storeId) async {
    try {
      final response = await _dio.post(
        '/categories', // Sesuaikan dengan endpoint API kamu
        data: {
          'name': name,
          'store_id': storeId,
        },
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      throw Exception('Gagal menambah kategori: $e');
    }
  }

  // 3. FUNGSI UNTUK MENAMBAH PRODUK BARU
  Future<bool> addProduct(ProductModel product) async {
    try {
      log("Menambahkan produk: ${product.name} (SKU: ${product.sku})", name: "PRODUCT_SERVICE");
      // Menggunakan .toJson() yang sudah kita sesuaikan dengan spec API
      final response = await _dio.post(
        "/products",
        data: product.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        log("Produk berhasil ditambahkan", name: "PRODUCT_SERVICE");
        return true;
      }

      return false;
    } on DioException catch (e) {
      // Menangkap pesan error spesifik dari backend (misal: SKU sudah ada)
      final errorMessage = e.response?.data['message'] ?? "Gagal menyimpan produk";
      log("Dio Error addProduct: $errorMessage", name: "PRODUCT_SERVICE");
      throw Exception(errorMessage);
    } catch (e) {
      log("Unexpected Error addProduct: $e", name: "PRODUCT_SERVICE");
      throw Exception("Terjadi kesalahan sistem saat menambah produk.");
    }
  }

  Future<List<CategoryModel>> fetchCategories(int storeId) async {
    try {
      final response = await _dio.get("/categories", queryParameters: {"store_id": storeId});
      if (response.statusCode == 200) {
        List<dynamic> data = response.data is Map ? response.data['data'] : response.data;
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Gagal mengambil kategori: $e");
    }
  }

  Future<List<UnitModel>> fetchBaseUnits() async {try {
      // Menggunakan Dio untuk mengambil data dari endpoint /units
      final response = await _dio.get('/units');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is Map 
            ? response.data['data'] 
            : response.data;

        return data.map((json) => UnitModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      // Menangkap error spesifik dari Dio (network, timeout, 404, dll)
      throw Exception("Gagal mengambil satuan: ${e.response?.data['message'] ?? e.message}");
    } catch (e) {
      throw Exception("Terjadi kesalahan: $e");
    }
  }

}
List<ProductModel> _parseProducts(List<dynamic> rawProducts) {
  return rawProducts.map((item) => ProductModel.fromJson(item)).toList();
}
List<FinishedProductModel> _parseFinishedProducts(List<dynamic> rawData) {
  return rawData.map((item) => FinishedProductModel.fromJson(item)).toList();
}