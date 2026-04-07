// add_product_page.dart
import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
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
  // final _priceNameController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Key untuk paksa rebuild dropdown setelah data API masuk
  Key _categoryDropdownKey = UniqueKey();
  Key _unitDropdownKey = UniqueKey();

  List<CategoryModel> _categories = [];
  List<UnitModel> _units = [];

  int? _selectedCategoryId;
  int? _selectedUnitId;
  String _selectedProductType = 'FINISHED'; // ← Simpan sebagai state

  bool _useStock = true;
  bool _showInTransaction = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch paralel agar lebih cepat
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

        // Paksa dropdown rebuild karena initialValue sudah berubah
        _categoryDropdownKey = UniqueKey();
        _unitDropdownKey = UniqueKey();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dipanggil setelah kembali dari AddCategoryPage
  Future<void> _refreshCategories() async {
    try {
      final categoryData = await _productService.fetchCategories(widget.storeId);
      setState(() {
        _categories = categoryData;
        // Pertahankan pilihan sebelumnya jika masih ada
        final stillExists = _categories.any((c) => c.id == _selectedCategoryId);
        if (!stillExists && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        }
        _categoryDropdownKey = UniqueKey(); // Rebuild dropdown
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
    // _priceNameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    dev.log("--- Menjalankan Validasi Produk ---");
    dev.log("Nama: ${_nameController.text}");
    dev.log("SKU: ${_skuController.text}");
    dev.log("BARCODE: ${_barcodeController.text}");
    dev.log("Harga Jual (Raw): ${_sellPriceController.text}");
    dev.log("Kategori ID: $_selectedCategoryId");
    dev.log("Unit ID: $_selectedUnitId");

    // Validasi form (nama, sku, harga, kategori, satuan)
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Bersihkan format Rupiah → angka murni
      final rawPrice = _sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');

      final newProduct = ProductModel(
        id: 0,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(), // ← FIX: sku dikirim ke model
        price: int.tryParse(rawPrice) ?? 0,
        stock: int.tryParse(_stockController.text) ?? 0,
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        categoryId: _selectedCategoryId,
        baseUnitId: _selectedUnitId,
        productType: _selectedProductType, // ← FIX: kirim tipe yang dipilih
        trackStock: _useStock,
        isActive: _showInTransaction,
      );

      dev.log("Payload toJson: ${newProduct.toJson()}", name: "ADD_PRODUCT");

      final success = await _productService.addProduct(newProduct);

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Barang',
          style: TextStyle(
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading && _categories.isEmpty
          // Tampilkan loading penuh hanya saat data pertama kali dimuat
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Preview Gambar ──────────────────────────────
                  _buildLabel("Preview Gambar"),
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _imageUrlController.text.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_search,
                                  size: 50, color: Colors.grey[400]),
                              const Text(
                                "Masukkan URL gambar di bawah",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.network(
                              _imageUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image,
                                        color: Colors.red, size: 40),
                                    Text("URL Gambar tidak valid",
                                        style: TextStyle(
                                            color: Colors.red, fontSize: 12)),
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

                  const SizedBox(height: 16),

                  // ── URL Gambar ──────────────────────────────────
                  _buildLabel("URL Gambar"),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration:
                        _inputDecoration("https://example.com/image.jpg"),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // ── SKU ─────────────────────────────────────────
                  _buildLabel("SKU (Kode Barang)*"),
                  TextFormField(
                    controller: _skuController,
                    decoration: _inputDecoration("Contoh: BRG-001"),
                    // FIX: trim() agar spasi tidak lolos validasi
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'SKU wajib diisi' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ── Barcode ──────────────────────────────────────
                  _buildLabel("BARCODE"),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: _inputDecoration("|||"),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BarcodeScannerPage(),
                            ),
                          );
                          if (result != null) {
                            _barcodeController.text = result;
                            setState(() {});
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            size: 28,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Nama ─────────────────────────────────────────
                  _buildLabel("Nama Barang*"),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration("Contoh: Cuci Express"),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),

                  const SizedBox(height: 16),

                  // ── Tipe Barang ──────────────────────────────────
                  _buildLabel("Tipe Barang"),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProductType,
                    decoration: _inputDecoration(""),
                    items: const [
                      DropdownMenuItem(value: 'FINISHED', child: Text('Default (Jadi)')),
                      DropdownMenuItem(value: 'SERVICE', child: Text('Jasa')),
                      DropdownMenuItem(value: 'RAW', child: Text('Bahan Baku')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedProductType = v);
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Checkbox Stok & Tampilkan ────────────────────
                  Row(
                    children: [
                      Checkbox(
                        value: _useStock,
                        onChanged: (v) => setState(() => _useStock = v!),
                      ),
                      const Text("Pakai stok"),
                      const Spacer(),
                      Checkbox(
                        value: _showInTransaction,
                        onChanged: (v) =>
                            setState(() => _showInTransaction = v!),
                      ),
                      const Text("Tampilkan di Transaksi"),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Stok & Harga Jual ────────────────────────────
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
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: _inputDecoration("0"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Harga Jual*"),
                            TextFormField(
                              controller: _sellPriceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                CurrencyInputFormatter(),
                              ],
                              decoration: _inputDecoration("Rp 0"),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Harga wajib diisi';
                                }
                                final raw = v.replaceAll(RegExp(r'[^0-9]'), '');
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

                  const SizedBox(height: 16),

                  // ── Kategori ─────────────────────────────────────
                  _buildLabel("Kategori*"),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: _categoryDropdownKey,
                          initialValue: _selectedCategoryId,
                          isExpanded: true,
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
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.green),
                        tooltip: 'Tambah Kategori',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Satuan ───────────────────────────────────────
                  _buildLabel("Satuan (Base Unit)*"),
                  DropdownButtonFormField<int>(
                    key: _unitDropdownKey,
                    initialValue: _selectedUnitId,
                    decoration: _inputDecoration("Pilih Satuan"),
                    items: _units
                        .map((unit) => DropdownMenuItem<int>(
                              value: unit.id,
                              child: Text("${unit.name} (${unit.symbol})"),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUnitId = v),
                    validator: (v) =>
                        v == null ? 'Satuan wajib dipilih' : null,
                  ),

                  const SizedBox(height: 32),

                  // ── Tombol Simpan ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'SIMPAN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
