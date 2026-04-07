// product_service.dart
import 'dart:developer';
import 'package:dio/dio.dart';
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
  final String? kodeBarang;
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
    this.kodeBarang,
    this.baseUnitId,
    this.image,
    required this.category,
    required this.stock,
    required this.price,
    required this.baseUnit,
    required this.trackStock,
  });

  factory FinishedProductModel.fromJson(Map<String, dynamic> json) {
  // Ambil price dari prices[0].price
  final prices = json['prices'] as List?;
  final price = prices != null && prices.isNotEmpty
      ? prices[0]['price']?.toString() ?? '0'
      : '0';
    return FinishedProductModel(
      // Jika id datang sebagai String, kita parse ke int. Jika null, beri 0.
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0), 
      productType: json['product_type']?.toString() ?? 'FINISHED',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '-',
      kodeBarang: json['barcode']?.toString() ?? '-',
      image: json['image']?.toString(), // Image boleh null
      category: json['category']?.toString() ?? '-',
      stock: double.tryParse(json['stock']?.toString() ?? '0') ?? 0.0,
      price: double.tryParse(price) ?? 0.0,
      baseUnit: json['base_unit']?.toString() ?? 'pcs',
      baseUnitId: int.tryParse(json['base_unit_id'].toString()),
      trackStock: json['track_stock'] ?? true,
    );
  }
}

class ProductService {
  // Menggunakan Dio dari AuthService agar interceptor dan token otomatis terpasang
  final Dio _dio = AuthService().dio;

  // 1. FUNGSI UNTUK PRODUK RAW (Berdasarkan storeId)
  Future<List<ProductModel>> fetchProducts(int storeId) async {
    try {
      log("Mengambil product untuk store_id: $storeId", name: "PRODUCT_SERVICE");

      final response = await _dio.get(
        "/products",
        queryParameters: {"store_id": storeId},
      );

      if (response.statusCode == 200) {
        List<dynamic> rawProducts = [];
        
        // Cek apakah response berupa Map { "data": [...] } atau langsung List [...]
        if (response.data is Map<String, dynamic>) {
          rawProducts = response.data["data"] ?? [];
        } else if (response.data is List) {
          rawProducts = response.data;
        }

        return rawProducts.map((item) => ProductModel.fromJson(item)).toList();
      }
      throw Exception("Gagal mengambil product: ${response.statusCode}");
    } catch (e) {
      log("Error fetchProducts: $e", name: "PRODUCT_SERVICE");
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  // 2. FUNGSI UNTUK PRODUK JADI (KASIR / FINISHED)
  // Fungsi ini yang akan dipanggil di CashierPage
  Future<List<FinishedProductModel>> fetchFinishedProducts() async {
      try {
        log("Mengambil produk jadi (finished) untuk Kasir", name: "PRODUCT_SERVICE");

        // Mengarah ke endpoint /products/finished
        final response = await _dio.get("/products/finished");

        log("Response Status Finished: ${response.statusCode}", name: "PRODUCT_SERVICE");

        if (response.statusCode == 200) {
          // PERBAIKAN KRUSIAL:
          // Error "String is not subtype of int" biasanya terjadi jika 
          // kita menganggap response.data adalah List, padahal itu Map.
          final dynamic responseBody = response.data;
          List<dynamic> listData = [];

          if (responseBody is Map<String, dynamic>) {
            // Ambil array di dalam key 'data'
            listData = responseBody['data'] ?? [];
          } else if (responseBody is List) {
            listData = responseBody;
          }

          // Mapping data ke FinishedProductModel menggunakan factory yang aman
          final products = listData.map((item) {
            return FinishedProductModel.fromJson(item);
          }).toList();

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

// coba lenkapi disini dan ada pertanyaan disini saya tidak mendefinisikan sku tetapi bisa saya input ?