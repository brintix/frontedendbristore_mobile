import 'package:flutter/material.dart';
import 'package:frontendbristore/presentation/pages/add_product_page.dart';
import '../../data/models/product_model.dart';
import '../../data/sources/product_service.dart';
// Pastikan path import ini sesuai dengan project Anda
import 'barcode_scanner_page.dart'; 

class ProductPage extends StatefulWidget {
  final int storeId;

  const ProductPage({
    super.key,
    required this.storeId,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ProductService _productService = ProductService();
  
  // Variable untuk filter & search
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // Logika pengambilan data tetap sama, namun disimpan ke list lokal
  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final products = await _productService.fetchProducts(widget.storeId);
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Fungsi Filter sesuai permintaan (Name, SKU, Kode Barang)
void _runFilter(String query) {
  List<ProductModel> results = [];
  if (query.isEmpty) {
    results = _allProducts;
  } else {
    results = _allProducts.where((product) {
      // Tambahkan ?? '' untuk menangani nilai null
      final name = product.name.toLowerCase();
      final sku = (product.sku ?? '').toLowerCase();
      final barcode = (product.barcode ?? '').toLowerCase();
      final input = query.toLowerCase();

      return name.contains(input) || 
             sku.contains(input) || 
             barcode.contains(input);
    }).toList();
  }

  setState(() {
    _filteredProducts = results;
  });
}

  // Fungsi Scan Barcode
Future<void> _scanBarcode() async {
  debugPrint("Memulai Scan Barcode...");
  
  // Contoh jika Anda menggunakan package barcode scanner:
  final String? result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
  );

  if (result != null) {
    _searchController.text = result; // Masukkan hasil scan ke kolom pencarian
    _runFilter(result);              // Jalankan filter secara otomatis
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Daftar Produk',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        // Menambahkan Search Bar di bawah Title AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                hintText: "Cari Nama, SKU, atau Barcode...",
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                  onPressed: _scanBarcode,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductPage(storeId: widget.storeId),
            ),
          ).then((_) => _fetchInitialData()); // Refresh data setelah tambah produk
          debugPrint("Navigasi ke Tambah Produk");
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Terjadi kesalahan:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchInitialData,
                child: const Text("Coba Lagi"),
              )
            ],
          ),
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]!),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty 
                ? 'Belum ada produk di toko ini.' 
                : 'Produk tidak ditemukan.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildProductCard(_filteredProducts[index]);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gambar (Logika tetap sama)
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: SizedBox(
              width: 110,
              height: 110,
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.blue[50],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.blue[50],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.blueAccent,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.blue[50],
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.blueAccent,
                          size: 32,
                        ),
                      ),
                    ),
            ),
          ),

          // Info Produk
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.categoryName ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  
                  // Menampilkan SKU atau Kode Barang sebagai info tambahan jika perlu
                  if (product.sku != null && product.sku!.isNotEmpty)
                    Text(
                      'SKU: ${product.sku}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp ${product.price}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.stock > 0
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 12,
                              color: product.stock > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product.stock}',
                              style: TextStyle(
                                color: product.stock > 0
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*

The method 'toLowerCase' can't be unconditionally invoked because the receiver can be 'null'.
Try making the call conditional (using '?.') or adding a null check to the target ('!').
The property 'isNotEmpty' can't be unconditionally accessed because the receiver can be 'null'.
Try making the access conditional (using '?.') or adding a null check to the target ('!').

ada error seperti diatas 
maaf saya sala yang benar barcode bukan kodeBarang

*/ 