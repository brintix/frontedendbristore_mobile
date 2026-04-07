import 'base_unit_model.dart';
// product_model.dart
class ProductModel {
  final int id;
  final String name;
  final String? sku;
  final String? barcode;
  final int price; //
  final int stock;
  final int? categoryId;
  final String? categoryName;
  final int? baseUnitId;
  final UnitModel? unit; // Data lengkap satuan (Hasil Join)
  final String? productType; // FINISHED, RAW, etc
  final bool isActive;
  final bool trackStock;
  final String? description;
  final String? imageUrl;
  final double? weight;
  final String? rackLocation;
  final String? priceName;

  ProductModel({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.price,
    required this.stock,
    this.categoryId,
    this.categoryName,
    this.baseUnitId,
    this.unit, // Tambahkan di constructor
    this.productType = 'FINISHED',
    this.isActive = true,
    this.trackStock = true,
    this.description,
    this.imageUrl,
    this.weight,
    this.rackLocation,
    this.priceName = 'REGULAR',
  });

factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Logika ambil gambar dari array images[0].url (Sesuai kode lamamu)
    String? imageUrl;
    final images = json['images'];
    if (images != null && images is List && images.isNotEmpty) {
      imageUrl = images[0]['url']?.toString();
    }

    return ProductModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString() ?? '-',
      price: int.tryParse(
            (json['price'] ?? json['avg_cost'] ?? 0).toString(),
          ) ?? 0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      categoryId: int.tryParse(json['category_id'].toString()),
      categoryName: json['category']?['name']?.toString() ??
          json['category_name']?.toString(),
      baseUnitId: int.tryParse(json['base_unit_id'].toString()),
      // --- TAMBAHAN BARU ---
      // Memeriksa apakah ada object 'unit' (hasil join dari API)
      unit: json['unit'] != null 
          ? UnitModel.fromJson(Map<String, dynamic>.from(json['unit'])) 
          : null,
      // ---------------------
      productType: json['product_type']?.toString() ?? 'FINISHED',
      isActive: json['is_active'] is bool ? json['is_active'] : true,
      trackStock: json['track_stock'] is bool ? json['track_stock'] : true,
      description: json['description']?.toString(),
      imageUrl: imageUrl,
      weight: double.tryParse(json['weight'].toString()) ?? 0.0,
      rackLocation: json['rack_location']?.toString(),
      priceName: json['price_name']?.toString() ?? 'REGULAR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode':barcode,
      'price': price.toString(), // API Prisma Decimal biasanya menerima String
      'price_name': priceName,
      'stock': stock,
      'category_id': categoryId,
      'base_unit_id': baseUnitId,
      'product_type': productType,
      'is_active': isActive,
      'track_stock': trackStock,
      'description': description,
      'weight': weight,
      'rack_location': rackLocation,
      'image_url': imageUrl,
    };
  }
}

// product_model.dart 