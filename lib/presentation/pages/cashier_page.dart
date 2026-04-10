// cashier_page.dart 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _productsFuture = _productService.fetchFinishedProducts();
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(FinishedProductModel product) {
    // Produk SERVICE: selalu tampilkan dialog input quantity
    if (product.productType == 'SERVICE') {
      _showServiceQuantityDialog(product);
      return;
    }

    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.increment();
      } else {
        _cart[product.id] = CartItemModel(product: product, quantity: 1.0);
      }
    });
  }

  void _removeFromCart(int productId) {
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

  /// Dialog input quantity khusus produk SERVICE
  void _showServiceQuantityDialog(FinishedProductModel product) {
    // Ambil quantity yang sudah ada di cart, atau default ke string kosong
    final existingQty = _cart[product.id]?.quantity;
    final TextEditingController qtyController = TextEditingController(
      text: existingQty != null
          ? (existingQty == existingQty.toInt()
              ? existingQty.toInt().toString()
              : existingQty.toStringAsFixed(2))
          : '',
    );

    // Ambil symbol unit dari _allUnits
    final String unitSymbol = _getUnitSymbol(product);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.design_services, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(fontSize: 16),
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
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 12),
              // Row: tombol minus + TextField + tombol plus
              Row(
                children: [
                  // Tombol -
                  _dialogStepButton(
                    icon: Icons.remove,
                    color: Colors.redAccent,
                    onTap: () {
                      final current =
                          double.tryParse(qtyController.text) ?? 0.0;
                      final next = (current - 1).clamp(0.0, double.infinity);
                      qtyController.text = next == next.toInt()
                          ? next.toInt().toString()
                          : next.toStringAsFixed(2);
                    },
                  ),
                  const SizedBox(width: 8),
                  // TextField quantity
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
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Colors.blueAccent, width: 2),
                        ),
                        suffixText: unitSymbol,
                        suffixStyle: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol +
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
              child:
                  const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final inputQty =
                    double.tryParse(qtyController.text) ?? 0.0;
                if (inputQty <= 0) {
                  // Jika 0 atau kosong, hapus dari cart jika ada
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
              child: const Text('Tambahkan',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Widget tombol step (+/-) di dalam dialog
  Widget _dialogStepButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.08),
        ),
        child: Icon(icon, color: color, size: 22),
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
    if (result != null) {
      _searchByBarcode(result, products);
    }
  }

  void _runFilter(String query) {
    List<FinishedProductModel> results = [];
    if (query.isEmpty) {
      results = _allProducts;
    } else {
      results = _allProducts.where((product) {
        final name = product.name.toLowerCase();
        final sku = product.sku.toLowerCase();
        final barcode = (product.kodeBarang ?? '').toLowerCase();
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

  void _searchByBarcode(String barcode, List<FinishedProductModel> products) {
    try {
      final product = products.firstWhere(
        (p) => p.kodeBarang == barcode,
      );
      _addToCart(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} ditambahkan ke keranjang'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk tidak ditemukan'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _loadUnits() async {
    try {
      final units = await _unitService.fetchUnits();
      setState(() {
        _allUnits = units;
      });
    } catch (e) {
      debugPrint("Gagal memuat unit: $e");
    }
  }

  /// Mengembalikan NAMA unit untuk ditampilkan di card produk
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

  /// Mengembalikan SYMBOL unit — dipakai di dialog SERVICE
  String _getUnitSymbol(FinishedProductModel product) {
    if (product.baseUnitId != null && _allUnits.isNotEmpty) {
      final unit = _allUnits.firstWhere(
        (u) => u.id == product.baseUnitId,
        orElse: () => UnitModel(id: 0, name: '', symbol: ''),
      );
      if (unit.symbol.isNotEmpty) return unit.symbol;
    }
    // Fallback ke baseUnit string produk jika tidak ketemu
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
            const Text(
              'BRI POST - Kasir',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.userName} (${widget.userRole})',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                hintText: "Cari Nama, SKU, atau Barcode...",
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
                  borderRadius: BorderRadius.circular(12),
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Terjadi kesalahan: ${snapshot.error}'));
              }

              if (_allProducts.isEmpty && snapshot.hasData) {
                _allProducts = snapshot.data!;
                if (_searchController.text.isEmpty) {
                  _filteredProducts = _allProducts;
                }
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductItem(_filteredProducts[index]);
                },
              );
            },
          ),

          if (_cart.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => PaymentSheet(
                      totalAmount: _calculateTotal(),
                      cartItems: _cart,
                      userName: widget.userName,
                      storeId: widget.storeId,
                      onTransactionSuccess: () {
                        setState(() {
                          _cart.clear();
                        });
                      },
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
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
                          const Icon(Icons.shopping_basket,
                              color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            "${_cart.length} Jenis Barang",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        "Rp ${_calculateTotal().toStringAsFixed(0)}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductItem(FinishedProductModel product) {
    double quantityInCart = _cart[product.id]?.quantity ?? 0;
    String unitName = _getUnitDisplay(product);
    final bool isService = product.productType == 'SERVICE';

    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                  ),
                  child: product.image != null && product.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(product.image!,
                              fit: BoxFit.cover),
                        )
                      : const Icon(Icons.image,
                          color: Colors.blueAccent, size: 40),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    if (unitName.isNotEmpty)
                      Text(
                        unitName,
                        style: TextStyle(
                          color: Colors.blueAccent.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${product.price}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.stockDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              color: product.stockColor,
                              fontWeight: product.productType == 'SERVICE'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // ── Tombol aksi: SERVICE vs produk biasa ──
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
          // Badge quantity di pojok kanan atas
          if (quantityInCart > 0)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: Colors.orange, shape: BoxShape.circle),
                child: Text(
                  _cart[product.id]!.formattedQuantity,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Tombol untuk produk SERVICE: satu tombol edit/tambah yang buka dialog
  Widget _buildServiceButton(
      FinishedProductModel product, double quantityInCart) {
    final bool inCart = quantityInCart > 0;
    return GestureDetector(
      onTap: () => _showServiceQuantityDialog(product),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: inCart
              ? Colors.orange.withValues(alpha: 0.15)
              : Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
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
              size: 14,
              color: inCart ? Colors.orange : Colors.blueAccent,
            ),
            const SizedBox(width: 4),
            Text(
              inCart ? 'Ubah' : 'Input',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: inCart ? Colors.orange : Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tombol +/- untuk produk biasa (non-SERVICE)
  Widget _buildRegularButtons(
      FinishedProductModel product, double quantityInCart) {
    return Row(
      children: [
        if (quantityInCart > 0)
          InkWell(
            onTap: () => _removeFromCart(product.id),
            child: const Icon(Icons.remove_circle_outline,
                color: Colors.redAccent, size: 28),
          ),
        if (quantityInCart > 0) const SizedBox(width: 8),
        InkWell(
          onTap: () => _addToCart(product),
          child: const Icon(Icons.add_circle,
              color: Colors.blueAccent, size: 28),
        ),
      ],
    );
  }
}

// buat UI/UX cashier_page.dart diatas 
/* seperti ini :
    Device Frame: Simulasi tampilan ponsel (iPhone/Android).
    Modern Dashboard: Desain kartu dengan gradien dan glassmorphism.
    Bottom Navigation: Navigasi antar layar yang mulus.
    Micro-animations: Transisi antar layar menggunakan motion.
*/ 
// jangan rubah logika dan nama function yang sudah ada berikan saya kode lengkapnya