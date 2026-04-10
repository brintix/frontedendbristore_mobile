// payment_sheet.dart
import 'dart:io'; 
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
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
  BluetoothInfo? _selectedDevice; 
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
    _initBluetooth();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      // Meminta izin yang dibutuhkan Android modern untuk Bluetooth
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location, // Beberapa tipe printer butuh lokasi untuk scanning
      ].request();

      if (statuses[Permission.bluetoothConnect]!.isDenied) {
        // Jika user menolak, beri tahu mereka
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Izin Bluetooth diperlukan untuk mencetak struk")),
          );
        }
      }
    }
  }

  // --- Logic Bluetooth ---
  Future<void> _initBluetooth() async {
    try {
      final bool isBluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (isBluetoothEnabled) {
        final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
        if (devices.isNotEmpty) {
          setState(() {
            _selectedDevice = devices.first;
          });
        }
      }
    } catch (e) {
      debugPrint("Error Bluetooth Init: $e");
    }
  }

  Future<void> _printToThermal(ReceiptData data) async {
    try {
      // 1. Cek status koneksi Bluetooth
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      await _checkPermissions();
      // 2. Jika belum terhubung, lakukan koneksi menggunakan Mac Address
      if (!isConnected) {
        if (_selectedDevice != null) {
          bool connectResult = await PrintBluetoothThermal.connect(
            macPrinterAddress: _selectedDevice!.macAdress,
          );
          
          if (!connectResult) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Gagal menghubungkan ke printer")),
              );
            }
            return;
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Pilih printer terlebih dahulu di pengaturan")),
            );
          }
          return;
        }
      }

      // 3. Generate data struk dalam bentuk Bytes (ESC/POS)
      // Ini menggunakan fungsi buildThermalBytes yang baru kita buat di ReceiptHelper
      final List<int> bytes = await ReceiptHelper.buildThermalBytes(data);
      
      // 4. Kirim Bytes tersebut ke printer
      // writeBytes adalah cara paling akurat untuk mencetak struk yang rapi
      final bool result = await PrintBluetoothThermal.writeBytes(bytes);

      if (result) {
        debugPrint("Cetak struk berhasil.");
      } else {
        throw "Gagal mengirim data ke printer";
      }
      
    } catch (e) {
      debugPrint("Gagal Cetak: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan printer: $e"), 
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  // --- Logic API & Transaction ---

  Future<void> _initStoreData() async {
    final prefs = await SharedPreferences.getInstance();
    String? localName = prefs.getString('store_name');
    String? localAddress = prefs.getString('store_address');

    if (localName != null && localAddress != null) {
      setState(() {
        _storeName = localName;
        _storeAddress = localAddress;
      });
    } else {
      final storeData = await _storeService.getStoreDetail(widget.storeId);
      if (storeData != null) {
        setState(() {
          _storeName = storeData['name'] ?? "BRI POST";
          _storeAddress = storeData['address'] ?? "Alamat tidak tersedia";
        });
        await prefs.setString('store_name', _storeName);
        await prefs.setString('store_address', _storeAddress);
      }
    }
  }

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
          final Map<String, dynamic> cleanMap = Map<String, dynamic>.from(item);
          loadedMethods.add(PaymentMethodModel.fromJson(cleanMap));
        }

        if (mounted) {
          setState(() {
            _paymentMethods = loadedMethods;
            if (_paymentMethods.isNotEmpty) {
              _selectedMethodId = _paymentMethods[0].id;
            }
            _isMethodsLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMethodsLoading = false;
          _methodsError = "Gagal memproses data pembayaran: $e";
        });
      }
    }
  }

  void _calculateChange(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    double cashPaid = double.tryParse(cleanValue) ?? 0;
    setState(() {
      _change = cashPaid - widget.totalAmount;
    });
  }

  Future<void> _processTransaction() async {
    setState(() => _isLoading = true);
    try {
      final txResponse = await _transactionService.createTransaction(
        cartItems: widget.cartItems,
        couponCode: null,
      );

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

        if (payResponse['success'] == true) {
          if (mounted) _showSuccessDialog(invoice, promos);
        } else {
          throw Exception(payResponse['message'] ?? "Gagal memproses pembayaran");
        }
      } else {
        throw Exception(txResponse['message'] ?? "Gagal membuat data transaksi");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red[700]),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String invoice, List<String> promos) {
    final selectedMethod = _paymentMethods.firstWhere(
      (m) => m.id == _selectedMethodId,
      orElse: () => PaymentMethodModel(id: 0, storeId: 0, name: 'Tunai'),
    );

    final receiptData = ReceiptData(
      invoiceNumber: invoice,
      userName: widget.userName,
      storeName: _storeName,
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
            const Divider(),
            Text("Total Tagihan: Rp ${widget.totalAmount.toStringAsFixed(0)}"),
            Text("Kembalian: Rp ${_change.toStringAsFixed(0)}", 
                 style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          // CETAK THERMAL
          TextButton.icon(
            icon: const Icon(Icons.print, color: Colors.blueGrey),
            label: const Text("Cetak"),
            onPressed: () => _printToThermal(receiptData),
          ),
          // SHARE PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            onPressed: () => ReceiptHelper.sharePdf(receiptData),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
              widget.onTransactionSuccess();
            },
            child: const Text("Selesai", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sesuai dengan style awal Anda
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SizedBox(width: 40, child: Divider(thickness: 4))),
            const SizedBox(height: 10),
            const Text("Pembayaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Tagihan", style: TextStyle(color: Colors.grey)),
                Text("Rp ${widget.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ],
            ),
            const Divider(height: 30),
            const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _buildPaymentMethodSection(),
            const SizedBox(height: 20),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
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
                  Text(_change >= 0 ? "Kembalian" : "Kurang",
                    style: TextStyle(fontWeight: FontWeight.bold, color: _change >= 0 ? Colors.green : Colors.red),
                  ),
                  Text("Rp ${_change.abs().toStringAsFixed(0)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _change >= 0 ? Colors.green : Colors.red),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Selesaikan Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    // Kondisi 1: Sedang memuat data (Loading)
    if (_isMethodsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: LinearProgressIndicator(),
      );
    }

    // Kondisi 2: Terjadi Error (Menggunakan _methodsError)
    if (_methodsError != null) {
      return InkWell(
        onTap: _loadPaymentMethods, // Memungkinkan user klik untuk mencoba lagi
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
                  _methodsError!, // Variabel digunakan di sini
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Kondisi 3: Berhasil memuat data (Default UI)
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
          items: _paymentMethods
              .map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.name),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _selectedMethodId = val),
        ),
      ),
    );
  }
}