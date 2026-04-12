import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'barcode_scanner_page.dart';
import '../../data/sources/product_service.dart';
import '../../data/models/cart_model.dart';
import '../widgets/payment_sheet.dart';
import '../../data/sources/unit_service.dart';
import '../../data/models/base_unit_model.dart';
import '../../data/models/product_extension.dart';

class CashierPage extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userRoleName;
  final int storeId;

  const CashierPage({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userRoleName,
    required this.storeId,
  });

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final ProductService _productService = ProductService();
  final UnitService _unitService = UnitService();
  final Map<int, CartItemModel> _cart = {};
  final TextEditingController _searchController = TextEditingController();

  Future<List<FinishedProductModel>>? _productsFuture;
  List<FinishedProductModel> _allProducts = [];
  List<FinishedProductModel> _filteredProducts = [];
  List<UnitModel> _allUnits = [];

  @override
  void initState() {
    super.initState();
    _productsFuture = _productService.fetchFinishedProducts(widget.storeId);
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(FinishedProductModel product) {
    if (product.productType == 'SERVICE') {
      _showServiceQuantityDialog(product);
      return;
    }
    if (!mounted) return;
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.increment();
      } else {
        _cart[product.id] = CartItemModel(product: product, quantity: 1.0);
      }
    });
  }

  void _removeFromCart(int productId) {
    if (!mounted) return;
    setState(() {
      if (_cart.containsKey(productId)) {
        if (_cart[productId]!.quantity > 1) {
          _cart[productId]!.decrement();
        } else {
          _cart.remove(productId);
        }
      }
    });
  }

  void _showServiceQuantityDialog(FinishedProductModel product) {
    final existingQty = _cart[product.id]?.quantity;
    final TextEditingController qtyController = TextEditingController(
      text: existingQty != null
          ? (existingQty == existingQty.toInt()
              ? existingQty.toInt().toString()
              : existingQty.toStringAsFixed(2))
          : '',
    );
    final String unitSymbol = _getUnitSymbol(product);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(Icons.design_services,
                  color: Colors.blueAccent, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  product.name,
                  style: TextStyle(fontSize: 16.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan jumlah${unitSymbol.isNotEmpty ? ' ($unitSymbol)' : ''}:',
                style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _dialogStepButton(
                    icon: Icons.remove,
                    color: Colors.redAccent,
                    onTap: () {
                      final current =
                          double.tryParse(qtyController.text) ?? 0.0;
                      final next =
                          (current - 1).clamp(0.0, double.infinity);
                      qtyController.text = next == next.toInt()
                          ? next.toInt().toString()
                          : next.toStringAsFixed(2);
                    },
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20.sp, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12.h),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(
                              color: Colors.blueAccent, width: 2),
                        ),
                        suffixText: unitSymbol,
                        suffixStyle: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _dialogStepButton(
                    icon: Icons.add,
                    color: Colors.blueAccent,
                    onTap: () {
                      final current =
                          double.tryParse(qtyController.text) ?? 0.0;
                      final next = current + 1;
                      qtyController.text = next == next.toInt()
                          ? next.toInt().toString()
                          : next.toStringAsFixed(2);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal',
                  style:
                      TextStyle(color: Colors.grey, fontSize: 13.sp)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () {
                final inputQty =
                    double.tryParse(qtyController.text) ?? 0.0;
                if (inputQty <= 0) {
                  setState(() => _cart.remove(product.id));
                  Navigator.pop(dialogContext);
                  return;
                }
                setState(() {
                  if (_cart.containsKey(product.id)) {
                    _cart[product.id]!.updateQuantity(inputQty);
                  } else {
                    _cart[product.id] =
                        CartItemModel(product: product, quantity: inputQty);
                  }
                });
                Navigator.pop(dialogContext);
              },
              child: Text('Tambahkan',
                  style:
                      TextStyle(color: Colors.white, fontSize: 13.sp)),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogStepButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8.r),
          color: color.withValues(alpha: 0.08),
        ),
        child: Icon(icon, color: color, size: 22.sp),
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    _cart.forEach((key, item) {
      total += item.totalItemPrice;
    });
    return total;
  }

  Future<void> _scanBarcode(List<FinishedProductModel> products) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      log("Hasil scan barcode: '$result'");
      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data produk belum dimuat, silakan tunggu...',
                style: TextStyle(fontSize: 13.sp)),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      _searchByBarcode(result, products);
    }
  }

  void _searchByBarcode(
      String scannedBarcode, List<FinishedProductModel> products) {
    log("Mencari barcode: '$scannedBarcode'");
    final cleanBarcode = scannedBarcode.trim();

    FinishedProductModel? product;
    try {
      product = products.firstWhere((p) {
        final productBarcode = p.barcode?.trim() ?? '';
        final productSku = p.sku.trim();
        return productBarcode == cleanBarcode || productSku == cleanBarcode;
      });
    } catch (_) {
      product = null;
    }

    if (product != null) {
      _addToCart(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${product.name} ditambahkan ke keranjang',
              style: TextStyle(fontSize: 13.sp)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      log("Barcode tidak ditemukan: '$cleanBarcode'");
      _showBarcodeNotFoundDialog(cleanBarcode, products);
    }
  }

  void _showBarcodeNotFoundDialog(
      String barcode, List<FinishedProductModel> products) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r)),
          title: Text('Barcode Tidak Ditemukan',
              style: TextStyle(fontSize: 16.sp)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Barcode: "$barcode"',
                  style: TextStyle(fontSize: 13.sp)),
              SizedBox(height: 10.h),
              Text('Kemungkinan penyebab:',
                  style: TextStyle(fontSize: 13.sp)),
              SizedBox(height: 5.h),
              Text('• Barcode belum terdaftar di sistem',
                  style: TextStyle(fontSize: 12.sp)),
              Text('• Format barcode tidak sesuai',
                  style: TextStyle(fontSize: 12.sp)),
              Text('• Data produk sedang dimuat',
                  style: TextStyle(fontSize: 12.sp)),
              SizedBox(height: 10.h),
              Text('Ingin input manual?',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13.sp)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal', style: TextStyle(fontSize: 13.sp)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _searchController.text = barcode;
                _runFilter(barcode);
              },
              child:
                  Text('Cari Manual', style: TextStyle(fontSize: 13.sp)),
            ),
          ],
        );
      },
    );
  }

  void _runFilter(String query) {
    List<FinishedProductModel> results = [];
    if (query.isEmpty) {
      results = _allProducts;
    } else {
      results = _allProducts.where((product) {
        final name = product.name.toLowerCase();
        final sku = product.sku.toLowerCase();
        final barcode = (product.barcode ?? '').toLowerCase();
        final input = query.toLowerCase();
        return name.contains(input) ||
            sku.contains(input) ||
            barcode.contains(input);
      }).toList();
    }
    if (!mounted) return;
    setState(() {
      _filteredProducts = results;
    });
  }

  Future<void> _loadUnits() async {
    try {
      final units = await _unitService.fetchUnits();
      setState(() {
        _allUnits = units;
      });
    } catch (e) {
      log("Gagal memuat unit: $e");
    }
  }

  String _getUnitDisplay(FinishedProductModel product) {
    if (product.baseUnitId != null && _allUnits.isNotEmpty) {
      final unit = _allUnits.firstWhere(
        (u) => u.id == product.baseUnitId,
        orElse: () => UnitModel(id: 0, name: '', symbol: ''),
      );
      if (unit.name.isNotEmpty) return unit.name;
    }
    String fallback = product.baseUnit;
    if (fallback.isEmpty) return 'Pcs';
    return fallback[0].toUpperCase() + fallback.substring(1).toLowerCase();
  }

  String _getUnitSymbol(FinishedProductModel product) {
    if (product.baseUnitId != null && _allUnits.isNotEmpty) {
      final unit = _allUnits.firstWhere(
        (u) => u.id == product.baseUnitId,
        orElse: () => UnitModel(id: 0, name: '', symbol: ''),
      );
      if (unit.symbol.isNotEmpty) return unit.symbol;
    }
    return product.baseUnit;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BRI POST - Kasir',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.userName} (${widget.userRole})',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ],
        ),
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
                  onPressed: () => _scanBarcode(_allProducts),
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
      body: Stack(
        children: [
          FutureBuilder<List<FinishedProductModel>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              // ← SHIMMER saat loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerGrid();
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Terjadi kesalahan: ${snapshot.error}',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                );
              }

              if (_allProducts.isEmpty && snapshot.hasData) {
                _allProducts = snapshot.data!;
                if (_searchController.text.isEmpty) {
                  _filteredProducts = _allProducts;
                }
              }

              return GridView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductItem(_filteredProducts[index]);
                },
              );
            },
          ),

          // ── Bottom Cart Bar ──────────────────────────────────
          if (_cart.isNotEmpty)
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: SafeArea(
                minimum: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20.r)),
                      ),
                      builder: (context) => PaymentSheet(
                        totalAmount: _calculateTotal(),
                        cartItems: _cart,
                        userName: widget.userName,
                        storeId: widget.storeId,
                        onTransactionSuccess: () {
                          setState(() => _cart.clear());
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: 14.h, horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_basket,
                                color: Colors.white, size: 20.sp),
                            SizedBox(width: 10.w),
                            Text(
                              "${_cart.length} Jenis Barang",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: Text(
                            "Rp ${_calculateTotal().toStringAsFixed(0)}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 16.sp),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ← SHIMMER grid skeleton
  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton gambar
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12.r)),
                    ),
                  ),
                ),
                // Skeleton teks
                Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: double.infinity,
                          height: 12.h,
                          color: Colors.white),
                      SizedBox(height: 6.h),
                      Container(width: 60.w, height: 10.h, color: Colors.white),
                      SizedBox(height: 6.h),
                      Container(width: 80.w, height: 14.h, color: Colors.white),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: 50.w, height: 10.h, color: Colors.white),
                          Container(
                              width: 28.w, height: 28.h, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductItem(FinishedProductModel product) {
    double quantityInCart = _cart[product.id]?.quantity ?? 0;
    String unitName = _getUnitDisplay(product);
    final bool isService = product.productType == 'SERVICE';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12.r)),
                  ),
                  child: product.image != null && product.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12.r)),
                          child: Image.network(product.image!,
                              fit: BoxFit.cover),
                        )
                      : Icon(Icons.image,
                          color: Colors.blueAccent, size: 40.sp),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                    if (unitName.isNotEmpty)
                      Text(
                        unitName,
                        style: TextStyle(
                          color: Colors.blueAccent.withValues(alpha: 0.8),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    SizedBox(height: 4.h),
                    Text(
                      'Rp ${product.price}',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.stockDisplay,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: product.stockColor,
                              fontWeight: product.productType == 'SERVICE'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        isService
                            ? _buildServiceButton(product, quantityInCart)
                            : _buildRegularButtons(product, quantityInCart),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (quantityInCart > 0)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: const BoxDecoration(
                    color: Colors.orange, shape: BoxShape.circle),
                child: Text(
                  _cart[product.id]!.formattedQuantity,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceButton(
      FinishedProductModel product, double quantityInCart) {
    final bool inCart = quantityInCart > 0;
    return GestureDetector(
      onTap: () => _showServiceQuantityDialog(product),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: inCart
              ? Colors.orange.withValues(alpha: 0.15)
              : Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: inCart ? Colors.orange : Colors.blueAccent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              inCart ? Icons.edit : Icons.add,
              size: 14.sp,
              color: inCart ? Colors.orange : Colors.blueAccent,
            ),
            SizedBox(width: 4.w),
            Text(
              inCart ? 'Ubah' : 'Input',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: inCart ? Colors.orange : Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularButtons(
      FinishedProductModel product, double quantityInCart) {
    return Row(
      children: [
        if (quantityInCart > 0)
          InkWell(
            onTap: () => _removeFromCart(product.id),
            child: Icon(Icons.remove_circle_outline,
                color: Colors.redAccent, size: 28.sp),
          ),
        if (quantityInCart > 0) SizedBox(width: 8.w),
        InkWell(
          onTap: () => _addToCart(product),
          child: Icon(Icons.add_circle,
              color: Colors.blueAccent, size: 28.sp),
        ),
      ],
    );
  }
}