import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animations/animations.dart';
import 'package:frontendbristore/presentation/pages/add_product_page.dart';
import '../../data/models/product_model.dart';
import '../../data/sources/product_service.dart';
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

  void _runFilter(String query) {
    List<ProductModel> results = [];
    if (query.isEmpty) {
      results = _allProducts;
    } else {
      results = _allProducts.where((product) {
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

  Future<void> _scanBarcode() async {
    final String? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );
    if (result != null) {
      _searchController.text = result;
      _runFilter(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Daftar Produk',
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                hintText: "Cari Nama, SKU, atau Barcode...",
                hintStyle: TextStyle(fontSize: 13.sp),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner,
                      color: Colors.blueAccent),
                  onPressed: _scanBarcode,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
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
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AddProductPage(storeId: widget.storeId),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                // ← FadeThroughTransition ke AddProductPage
                return FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              },
            ),
          ).then((_) => _fetchInitialData());
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    // ← SHIMMER saat loading
    if (_isLoading) return _buildShimmerList();

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
              SizedBox(height: 12.h),
              Text(
                'Terjadi kesalahan:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 13.sp),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _fetchInitialData,
                child: Text('Coba Lagi', style: TextStyle(fontSize: 13.sp)),
              ),
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
            Icon(Icons.inventory_2_outlined,
                size: 80.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              _searchController.text.isEmpty
                  ? 'Belum ada produk di toko ini.'
                  : 'Produk tidak ditemukan.',
              style: TextStyle(fontSize: 16.sp),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredProducts.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return _buildProductCard(_filteredProducts[index]);
      },
    );
  }

  // ← SHIMMER loading skeleton
  Widget _buildShimmerList() {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: 6, // jumlah skeleton card
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 110.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                // Skeleton gambar
                Container(
                  width: 110.w,
                  height: 110.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(16.r),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                // Skeleton teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 60.w, height: 12.h, color: Colors.white),
                      SizedBox(height: 8.h),
                      Container(
                          width: 140.w, height: 14.h, color: Colors.white),
                      SizedBox(height: 6.h),
                      Container(
                          width: 80.w, height: 10.h, color: Colors.white),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: 70.w, height: 14.h, color: Colors.white),
                          Container(
                              width: 50.w, height: 24.h, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14.w),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
          // Gambar
          ClipRRect(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(16.r)),
            child: SizedBox(
              width: 110.w,
              height: 110.h,
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
                          child: Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: Colors.blueAccent, size: 32.sp),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.blue[50],
                      child: Center(
                        child: Icon(Icons.image_outlined,
                            color: Colors.blueAccent, size: 32.sp),
                      ),
                    ),
            ),
          ),

          // Info Produk
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      product.categoryName ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                  if (product.sku != null && product.sku!.isNotEmpty)
                    Text(
                      'SKU: ${product.sku}',
                      style:
                          TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                    ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp ${product.price}',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: product.stock > 0
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 12.sp,
                              color: product.stock > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${product.stock}',
                              style: TextStyle(
                                color: product.stock > 0
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12.sp,
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