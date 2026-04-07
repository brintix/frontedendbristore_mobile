// payment_sheet.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../data/sources/transaction_service.dart';
import '../../data/sources/store_service.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../core/utils/receipt_helper.dart';

class PaymentSheet extends StatefulWidget {
  final double totalAmount;
  final Map<int, CartItemModel> cartItems;
  final Function onTransactionSuccess;
  final String userName;
  final int storeId;

  const PaymentSheet({
    super.key,
    required this.totalAmount,
    required this.cartItems,
    required this.onTransactionSuccess,
    required this.userName,
    this.storeId = 0,
  });

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  String _storeName = "Memuat..."; 
  String _storeAddress = "Memuat...";
  final TextEditingController _cashController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  final StoreService _storeService = StoreService();


  double _change = 0;
  bool _isLoading = false;
  bool _isMethodsLoading = true;
  String? _methodsError;

  List<PaymentMethodModel> _paymentMethods = [];
  int? _selectedMethodId;

  @override
  void initState() {
    super.initState();
    _initStoreData();
    _loadPaymentMethods();
  }

  Future<void> _initStoreData() async {
    final prefs = await SharedPreferences.getInstance();

    // LANGKAH 1: Coba ambil dari SharedPreferences (Lokal)
    String? localName = prefs.getString('store_name');
    String? localAddress = prefs.getString('store_address');

    if (localName != null && localAddress != null) {
      // Jika ada di lokal, langsung tampilkan agar UI cepat
      setState(() {
        _storeName = localName;
        _storeAddress = localAddress;
      });
    } else {
      // LANGKAH 2: Jika di lokal kosong (misal baru instal/login), panggil API
      // widget.storeId harus di-pass dari halaman Cashier ke PaymentSheet
      final storeData = await _storeService.getStoreDetail(widget.storeId);

      if (storeData != null) {
        setState(() {
          _storeName = storeData['name'] ?? "BRI POST";
          _storeAddress = storeData['address'] ?? "Alamat tidak tersedia";
        });

        // Simpan hasil API ke lokal untuk penggunaan berikutnya
        await prefs.setString('store_name', _storeName);
        await prefs.setString('store_address', _storeAddress);
      }
    }
  }

  // STAY: Nama function tidak diubah, diperkuat logic parsingnya
  Future<void> _loadPaymentMethods() async {
    if (!mounted) return;
    setState(() {
      _isMethodsLoading = true;
      _methodsError = null;
    });

    try {
      final dynamic responseData = await _transactionService.fetchPaymentMethods();

      if (responseData is List) {
        final List<PaymentMethodModel> loadedMethods = [];

        for (var item in responseData) {
          try {
            // Menggunakan Map.from untuk memastikan tipe data cocok dengan model
            final Map<String, dynamic> cleanMap = Map<String, dynamic>.from(item);
            loadedMethods.add(PaymentMethodModel.fromJson(cleanMap));
          } catch (e) {
            debugPrint("Gagal parsing item: $item, error: $e");
          }
        }

        if (mounted) {
          setState(() {
            _paymentMethods = loadedMethods;
            // Otomatis pilih metode pertama jika tersedia
            if (_paymentMethods.isNotEmpty) {
              _selectedMethodId = _paymentMethods[0].id;
            }
            _isMethodsLoading = false;
          });
        }
      } else {
        throw Exception("Format API salah: Data bukan berupa List");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMethodsLoading = false;
          _methodsError = "Gagal memproses data pembayaran: $e";
        });
      }
      debugPrint("Error Detail Load Methods: $e");
    }
  }

  void _calculateChange(String value) {
    // Menghilangkan karakter non-numeric kecuali titik untuk double parsing
    String cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    double cashPaid = double.tryParse(cleanValue) ?? 0;
    setState(() {
      _change = cashPaid - widget.totalAmount;
    });
  }

  // STAY: Nama function tidak diubah
  Future<void> _processTransaction() async {
    setState(() => _isLoading = true);

    try {
      final txResponse = await _transactionService.createTransaction(
        cartItems: widget.cartItems,
        couponCode: null,
      );

      debugPrint("📦 TX Response: $txResponse");

      if (txResponse['success'] == true) {
        final txData = txResponse['data'];
        final int transactionId = txData['id'];
        final String invoice = txData['invoice_number'];
        final List<String> promos = txData['applied_promotions'] != null
            ? List<String>.from(txData['applied_promotions'])
            : [];

        final payResponse = await _transactionService.processPayment(
          transactionId: transactionId,
          paymentMethodId: _selectedMethodId ?? 1,
          amount: widget.totalAmount,
          referenceNumber: invoice,
        );

        debugPrint("💳 Pay Response: $payResponse");

        if (payResponse['success'] == true) {
          debugPrint("✅ Transaksi & Pembayaran Berhasil");
          if (mounted) {
            _showSuccessDialog(invoice, promos);
          }
        } else {
          throw Exception(payResponse['message'] ?? "Gagal memproses pembayaran");
        }
      } else {
        throw Exception(txResponse['message'] ?? "Gagal membuat data transaksi");
      }
    } catch (e) {
      debugPrint("🔥 Error Proses Transaksi: $e");
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi Kesalahan: $errorMsg"),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // STAY: Nama function tidak diubah
  void _showSuccessDialog(String invoice, List<String> promos) {
    final selectedMethod = _paymentMethods.firstWhere(
      (m) => m.id == _selectedMethodId,
      orElse: () => PaymentMethodModel(id: 0, storeId: 0, name: 'Tunai'),
    );

    final receiptData = ReceiptData(
      invoiceNumber: invoice,
      userName: widget.userName,
      storeName: _storeName,       // Variabel yang kita buat di level State
      storeAddress: _storeAddress,
      cartItems: widget.cartItems,
      totalAmount: widget.totalAmount,
      cashPaid: double.tryParse(_cashController.text) ?? widget.totalAmount,
      change: _change,
      paymentMethodName: selectedMethod.name,
      transactionTime: DateTime.now(),
      appliedPromotions: promos,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Berhasil"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Invoice : $invoice", style: const TextStyle(fontSize: 13)),
            Text("Kasir   : ${widget.userName}", style: const TextStyle(fontSize: 13)),
            const Divider(),
            Text("Total   : Rp ${widget.totalAmount.toStringAsFixed(0)}"),
            Text("Bayar   : Rp ${(double.tryParse(_cashController.text) ?? widget.totalAmount).toStringAsFixed(0)}"),
            Text("Kembali : Rp ${_change.toStringAsFixed(0)}", 
                 style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            if (promos.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text("Promosi:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ...promos.map((p) => Text("• $p", style: const TextStyle(fontSize: 12))),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            label: const Text("PDF", style: TextStyle(color: Colors.redAccent)),
            onPressed: () => ReceiptHelper.sharePdf(receiptData),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Tutup bottom sheet
              widget.onTransactionSuccess();
            },
            child: const Text("Selesai", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    if (_isMethodsLoading) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_methodsError != null || _paymentMethods.isEmpty) {
      return InkWell(
        onTap: _loadPaymentMethods,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.refresh, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _methodsError ?? "Metode tidak ditemukan. Tap untuk muat ulang.",
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMethodId,
          isExpanded: true,
          items: _paymentMethods.map((method) {
            return DropdownMenuItem<int>(
              value: method.id,
              child: Text(method.name, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedMethodId = val),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(
                width: 40,
                child: Divider(thickness: 4),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Pembayaran",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Tagihan", style: TextStyle(color: Colors.grey)),
                Text(
                  "Rp ${widget.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ],
            ),
            const Divider(height: 30),
            const Text(
              "Metode Pembayaran",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodSection(),
            const SizedBox(height: 20),
            TextField(
              controller: _cashController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Uang Diterima",
                prefixText: "Rp ",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _calculateChange,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _change >= 0 ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _change >= 0 ? "Kembalian" : "Kurang",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _change >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    "Rp ${_change.abs().toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _change >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_change >= 0 &&
                        _cashController.text.isNotEmpty &&
                        !_isLoading &&
                        !_isMethodsLoading &&
                        _selectedMethodId != null)
                    ? () => _processTransaction()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Selesaikan Transaksi",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}