import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import '../../data/sources/data_transaction_service.dart';
import '../widgets/transaction_store_card.dart';

class TransactionStorePage extends StatefulWidget {
  const TransactionStorePage({super.key});

  @override
  State<TransactionStorePage> createState() => _TransactionStorePageState();
}

class _TransactionStorePageState extends State<TransactionStorePage> {
  // Service & Controllers
  final DataTransactionService _transactionService = DataTransactionService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Data States
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = []; // Untuk fitur search lokal
  
  // UI States
  DateTimeRange? _selectedDateRange;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Ambil data pertama kali dari API
  Future<void> _fetchInitialData({String? from, String? to}) async {
    // 1. Set loading di awal
    setState(() {
      _isLoading = true;
      _transactions = []; // Opsional: bersihkan list lama saat filter baru
      _hasReachedMax = false;
    });

    try {
      // 2. Cukup panggil API SATU KALI saja dengan parameter yang ada
      final response = await _transactionService.getTransactions(from: from, to: to);

      if (response != null && response.success) {
        setState(() {
          _transactions = response.data;
          _filteredTransactions = response.data;

          // Logika pagination sederhana
          if (response.data.length < 10) {
            _hasReachedMax = true;
          } else {
            _hasReachedMax = false;
          }
        });

        log("Berhasil memuat ${response.data.length} transaksi");
      } else {
        log("Gagal memuat data atau response kosong");
      }
    } catch (e) {
      log("Error load initial data: $e");
    } finally {
      // 3. Pastikan loading berhenti apa pun yang terjadi (sukses/gagal)
      setState(() => _isLoading = false);
    }
  }

  // Logika Infinite Scroll (Poin 3)
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && !_hasReachedMax) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadMoreData() async {
    setState(() => _isLoadingMore = true);

    // Simulasi atau panggil API pagination jika tersedia
    await Future.delayed(const Duration(seconds: 1));
    
    // Untuk saat ini kita set true agar tidak looping terus karena API dummy/list statis
    setState(() {
      _isLoadingMore = false;
      _hasReachedMax = true; 
    });
  }

  // Filter Search Lokal
  void _onSearch(String query) {
    setState(() {
      _filteredTransactions = _transactions
          .where((item) => item.invoiceNumber.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Colors.blue.shade700)), child: child!);
      },
    );
    if (picked != null) {
        setState(() {
          _selectedDateRange = picked;
          _searchController.clear(); 
        });
        String formattedFrom = DateFormat('yyyy-MM-dd').format(picked.start);
        String formattedTo = DateFormat('yyyy-MM-dd').format(picked.end);
        _fetchInitialData(from: formattedFrom, to: formattedTo);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: Text("Riwayat Transaksi", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          if (_selectedDateRange != null) _buildSelectedDateInfo(),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty 
                    ? _buildEmptyState() // POIN 5: Tampilan jika data kosong
                    : RefreshIndicator(
                        // PERBAIKAN: Menggunakan fungsi anonim untuk mempertahankan filter saat refresh
                        onRefresh: () async {
                          if (_selectedDateRange != null) {
                            // Jika ada filter tanggal, refresh berdasarkan rentang tersebut
                            String from = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
                            String to = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
                            await _fetchInitialData(from: from, to: to);
                          } else {
                            // Jika tidak ada filter, refresh semua data
                            await _fetchInitialData();
                          }
                          
                          // Opsional: Clear pencarian lokal saat refresh manual
                          _searchController.clear();
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          // Menggunakan physics agar Pull-to-Refresh selalu aktif meski data sedikit
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(top: 10.h, bottom: 20.h),
                          itemCount: _filteredTransactions.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _filteredTransactions.length) {
                              // Menampilkan kartu transaksi
                              return TransactionStoreCard(
                                transaction: _filteredTransactions[index]
                              );
                            } else {
                              // Menampilkan loading indikator di bawah saat load more
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 0.6.sh,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text("Belum Ada Transaksi", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            SizedBox(height: 8.h),
            Text("Transaksi toko Anda akan muncul di sini.", style: TextStyle(fontSize: 13.sp, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8.r)),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: "Cari nomor invoice...",
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                  hintStyle: TextStyle(fontSize: 13.sp),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          IconButton(
            onPressed: _pickDateRange,
            icon: Icon(Icons.date_range, color: Colors.blue.shade700),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDateInfo() {
    String start = DateFormat('dd MMM yyyy').format(_selectedDateRange!.start);
    String end = DateFormat('dd MMM yyyy').format(_selectedDateRange!.end);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14.sp, color: Colors.blue.shade700),
          SizedBox(width: 8.w),
          Text("Filter: $start - $end", style: TextStyle(fontSize: 12.sp, color: Colors.blue.shade800)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedDateRange = null;
                _searchController.clear(); // <--- LETAKKAN DI SINI JUGA
              });
              _fetchInitialData();
            },
            child: Icon(Icons.close, size: 14.sp, color: Colors.blue.shade700),
          )
        ],
      ),
    );
  }
}