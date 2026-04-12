import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'barcode_scanner_page.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/base_unit_model.dart';
import '../../data/sources/product_service.dart';
import '../../core/utils/currency_formatter.dart';
import 'add_category_page.dart';

class AddProductPage extends StatefulWidget {
  final int storeId;
  const AddProductPage({super.key, required this.storeId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _sellPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  Key _categoryDropdownKey = UniqueKey();
  Key _unitDropdownKey = UniqueKey();

  List<CategoryModel> _categories = [];
  List<UnitModel> _units = [];

  int? _selectedCategoryId;
  int? _selectedUnitId;
  String _selectedProductType = 'FINISHED';

  bool _useStock = true;
  bool _showInTransaction = true;
  bool _isLoading = false;

  // Warna tema — sesuai halaman lain
  static const _primary = Color(0xFF00529C);
  static const _accent = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _productService.fetchCategories(widget.storeId),
        _productService.fetchBaseUnits(),
      ]);

      final categoryData = results[0] as List<CategoryModel>;
      final unitData = results[1] as List<UnitModel>;

      setState(() {
        _categories = categoryData;
        _units = unitData;
        if (_categories.isNotEmpty) _selectedCategoryId = _categories.first.id;
        if (_units.isNotEmpty) _selectedUnitId = _units.first.id;
        _categoryDropdownKey = UniqueKey();
        _unitDropdownKey = UniqueKey();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat data: $e",
                style: TextStyle(fontSize: 13.sp)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCategories() async {
    try {
      final categoryData =
          await _productService.fetchCategories(widget.storeId);
      setState(() {
        _categories = categoryData;
        final stillExists =
            _categories.any((c) => c.id == _selectedCategoryId);
        if (!stillExists && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        }
        _categoryDropdownKey = UniqueKey();
      });
    } catch (e) {
      debugPrint("Gagal refresh kategori: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    _sellPriceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    dev.log("--- Menjalankan Validasi Produk ---");
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final rawPrice =
          _sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');

      final newProduct = ProductModel(
        id: 0,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim(),
        price: int.tryParse(rawPrice) ?? 0,
        stock: int.tryParse(_stockController.text) ?? 0,
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        categoryId: _selectedCategoryId,
        baseUnitId: _selectedUnitId,
        productType: _selectedProductType,
        trackStock: _useStock,
        isActive: _showInTransaction,
      );

      dev.log("Payload toJson: ${newProduct.toJson()}", name: "ADD_PRODUCT");
      final success = await _productService.addProduct(newProduct);
      if (success && mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: TextStyle(fontSize: 13.sp)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _accent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Barang',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        elevation: 0,
      ),

      // ← SHIMMER saat data pertama kali dimuat
      body: _isLoading && _categories.isEmpty
          ? _buildShimmerForm()
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // ── Preview Gambar ────────────────────────────
                  _buildLabel("Preview Gambar"),
                  Container(
                    width: double.infinity,
                    height: 180.h,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: _imageUrlController.text.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_search,
                                  size: 50.sp, color: Colors.blueAccent),
                              Text(
                                "Masukkan URL gambar di bawah",
                                style: TextStyle(
                                    color: Colors.blueAccent, fontSize: 12.sp),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(11.r),
                            child: Image.network(
                              _imageUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image,
                                        color: Colors.red, size: 40.sp),
                                    Text("URL Gambar tidak valid",
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12.sp)),
                                  ],
                                ),
                              ),
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                            ),
                          ),
                  ),

                  SizedBox(height: 16.h),

                  // ── URL Gambar ────────────────────────────────
                  _buildLabel("URL Gambar"),
                  TextFormField(
                    controller: _imageUrlController,
                    style: TextStyle(fontSize: 13.sp),
                    decoration:
                        _inputDecoration("https://example.com/image.jpg"),
                    onChanged: (_) => setState(() {}),
                  ),

                  SizedBox(height: 16.h),

                  // ── SKU ───────────────────────────────────────
                  _buildLabel("SKU (Kode Barang)*"),
                  TextFormField(
                    controller: _skuController,
                    style: TextStyle(fontSize: 13.sp),
                    decoration: _inputDecoration("Contoh: BRG-001"),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'SKU wajib diisi'
                        : null,
                  ),

                  SizedBox(height: 16.h),

                  // ── Barcode ───────────────────────────────────
                  _buildLabel("BARCODE"),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          style: TextStyle(fontSize: 13.sp),
                          decoration: _inputDecoration("|||"),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BarcodeScannerPage()),
                          );
                          if (result != null) {
                            _barcodeController.text = result;
                            setState(() {});
                          }
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.shade300),
                            borderRadius: BorderRadius.circular(8.r),
                            color: Colors.blue[50],
                          ),
                          child: Icon(Icons.qr_code_scanner,
                              size: 28.sp, color: _accent),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // ── Nama ──────────────────────────────────────
                  _buildLabel("Nama Barang*"),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(fontSize: 13.sp),
                    decoration: _inputDecoration("Nama Product/Service"),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
                  ),

                  SizedBox(height: 16.h),

                  // ── Tipe Barang ───────────────────────────────
                  _buildLabel("Tipe Barang"),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProductType,
                    decoration: _inputDecoration(""),
                    style: TextStyle(
                        fontSize: 13.sp, color: Colors.black87),
                    items: const [
                      DropdownMenuItem(
                          value: 'FINISHED', child: Text('Default (Jadi)')),
                      DropdownMenuItem(
                          value: 'SERVICE', child: Text('Jasa')),
                      DropdownMenuItem(
                          value: 'RAW', child: Text('Bahan Baku')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedProductType = v);
                    },
                  ),

                  SizedBox(height: 16.h),

                  // ── Checkbox ──────────────────────────────────
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _useStock,
                          activeColor: _accent,
                          onChanged: (v) =>
                              setState(() => _useStock = v!),
                        ),
                        Text("Pakai stok",
                            style: TextStyle(fontSize: 13.sp)),
                        const Spacer(),
                        Checkbox(
                          value: _showInTransaction,
                          activeColor: _accent,
                          onChanged: (v) =>
                              setState(() => _showInTransaction = v!),
                        ),
                        Text("Tampil di Transaksi",
                            style: TextStyle(fontSize: 12.sp)),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // ── Stok & Harga ──────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Stok"),
                            TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 13.sp),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: _inputDecoration("0"),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Harga Jual*"),
                            TextFormField(
                              controller: _sellPriceController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 13.sp),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                CurrencyInputFormatter(),
                              ],
                              decoration: _inputDecoration("Rp 0"),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Harga wajib diisi';
                                }
                                final raw =
                                    v.replaceAll(RegExp(r'[^0-9]'), '');
                                if (raw.isEmpty || int.parse(raw) <= 0) {
                                  return 'Harga harus lebih dari 0';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // ── Kategori ──────────────────────────────────
                  _buildLabel("Kategori*"),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: _categoryDropdownKey,
                          initialValue: _selectedCategoryId,
                          isExpanded: true,
                          style: TextStyle(
                              fontSize: 13.sp, color: Colors.black87),
                          decoration: _inputDecoration("Pilih Kategori"),
                          items: _categories
                              .map((cat) => DropdownMenuItem<int>(
                                    value: cat.id,
                                    child: Text(cat.name),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategoryId = v),
                          validator: (v) =>
                              v == null ? 'Kategori wajib dipilih' : null,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddCategoryPage(storeId: widget.storeId),
                            ),
                          ).then((added) {
                            if (added == true) _refreshCategories();
                          });
                        },
                        icon: Icon(Icons.add_circle_outline,
                            color: _accent, size: 28.sp),
                        tooltip: 'Tambah Kategori',
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // ── Satuan ────────────────────────────────────
                  _buildLabel("Satuan (Base Unit)*"),
                  DropdownButtonFormField<int>(
                    key: _unitDropdownKey,
                    initialValue: _selectedUnitId,
                    style:
                        TextStyle(fontSize: 13.sp, color: Colors.black87),
                    decoration: _inputDecoration("Pilih Satuan"),
                    items: _units
                        .map((unit) => DropdownMenuItem<int>(
                              value: unit.id,
                              child:
                                  Text("${unit.name} (${unit.symbol})"),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUnitId = v),
                    validator: (v) =>
                        v == null ? 'Satuan wajib dipilih' : null,
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),

        bottomNavigationBar: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3),
                      )
                    : Text(
                        'SIMPAN',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp),
                      ),
              ),
            ),
          ),
        ),
    );
  }



  // ← SHIMMER form skeleton
  Widget _buildShimmerForm() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: List.generate(6, (index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label skeleton
              Container(
                  width: 120.w,
                  height: 12.h,
                  color: Colors.white),
              SizedBox(height: 6.h),
              // Field skeleton
              Container(
                width: double.infinity,
                height: index == 0 ? 180.h : 48.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        text,
        style: TextStyle(
          color: _primary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
      contentPadding:
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: Colors.blue.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: Colors.blue.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: _accent, width: 2),
      ),
    );
  }
}