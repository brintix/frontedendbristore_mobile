// product_model.dart
import 'base_unit_model.dart';
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
    // 1. Penyesuaian Logika Gambar (Sekarang menggunakan key 'image' langsung)
    String? imageUrl;
    if (json['image'] != null) {
      imageUrl = json['image'].toString();
    }

    return ProductModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString() ?? '-',
      price: int.tryParse(json['price'].toString()) ?? 0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      
      // 2. Penyesuaian Kategori (Sekarang 'category' adalah String, bukan Object)
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      categoryName: json['category']?.toString(), 
      
      baseUnitId: int.tryParse(json['base_unit_id'].toString()),
      
      // Tetap pertahankan null safety untuk unit jika sewaktu-waktu ada include unit
      unit: json['unit'] != null 
          ? UnitModel.fromJson(Map<String, dynamic>.from(json['unit'])) 
          : null,
          
      productType: json['product_type']?.toString() ?? 'FINISHED',
      isActive: json['is_active'] is bool ? json['is_active'] : true,
      trackStock: json['track_stock'] is bool ? json['track_stock'] : true,
      description: json['description']?.toString(),
      imageUrl: imageUrl, // Hasil ekstraksi dari key 'image'
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

/*
saya ada perubahan pada respons api : https://apistoresbristore.vercel.app/api/products
apa yang perlu di sesuaikan pada kode diatas
{
    "success": true,
    "data": [
        {
            "id": 2,
            "name": "Cuci reguler",
            "sku": "RKK-01",
            "barcode": "6945082409140",
            "stock": "0",
            "category": "JASA",
            "image": null,
            "price": "6000",
            "price_name": "REGULAR"
        },
        {
            "id": 1,
            "name": "Le minerale 600 ml",
            "sku": "LEM-001",
            "barcode": null,
            "stock": "21",
            "category": "MAKANAN RINGAN (FINISHED)",
            "image": null,
            "price": "4000",
            "price_name": "REGULAR"
        }
    ],
    "meta": {
        "page": 1,
        "limit": 20,
        "total": 2,
        "totalPages": 1
    }
}
*/