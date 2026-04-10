import 'package:dio/dio.dart'; 
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/sources/auth_service.dart';
import 'home_page.dart'; 

class StorePage extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userRoleName;
  final List<Map<String, dynamic>> availableStores;

  const StorePage({
    super.key, // 🔥 Super parameter
    required this.userName,
    required this.userRole,
    required this.userRoleName,
    required this.availableStores,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    log("StorePage - User: ${widget.userName}, Role: ${widget.userRoleName}, Stores: ${widget.availableStores.length}", name: "STORE_PAGE");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName} - ${widget.userRoleName}'),
        backgroundColor: const Color(0xFF00529C), // 🔥 BIRU BRI
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(),
          ),
        ],
      ),
      body: Container(
        // 🔥 Background gradient BIRU seperti login
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: widget.availableStores.isEmpty
            ? _buildEmptyState()
            : _buildStoreList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00529C).withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 80,
              color: Color(0xFF00529C),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tidak ada toko tersedia',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF00529C),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00529C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.availableStores.length,
      itemBuilder: (context, index) {
        final store = widget.availableStores[index];
        return Card(
          elevation: 8, // 🔥 Naikkan shadow
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white, // 🔥 White card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.blue.shade100), // 🔥 Blue border
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _selectStore(store),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar BIRU
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF00529C), // 🔥 BIRU BRI
                    child: Text(
                      '${store['id'] ?? index + 1}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store['name'] ?? 'Toko Tanpa Nama',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00529C), // 🔥 BIRU teks
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          store['address'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '📞 ${store['phone'] ?? 'Tidak ada'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Color(0xFF00529C)), // 🔥 BIRU arrow
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectStore(Map<String, dynamic> store) async {
    if (!mounted) return;

    // 🔥 1. Show dialog SEBELUM async
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    ).then((_) {}); // Ignore result

    Response? response;
    try {
      // 🔥 2. API call
      response = await _authService.selectStore(store['id']);
    } catch (e) {
      // 🔥 3. Tutup dialog di catch (SEBELUM mounted check)
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // 🔥 4. Tutup dialog SETELAH await selesai
    if (mounted) Navigator.of(context).pop();

    // 🔥 5. Check mounted SETELAH semua async selesai
    if (!mounted || response.statusCode != 200) return;

    final data = response.data['data'];
    final newUserData = data['user'];
    final newToken = data['token'];

    // 🔥 6. Simpan data (async kedua)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', newToken);
    await prefs.setInt('store_id', newUserData['store_id']);
    await prefs.setString('name', newUserData['name']);

    log("✅ Store ID: ${newUserData['store_id']} - Token UPDATED", name: "STORE_PAGE");

    // 🔥 7. FINAL mounted check SEBELUM navigate
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          storeId: newUserData['store_id'],
          userRole: newUserData['role_id'].toString(),
          userRoleName: widget.userRoleName,
          userName: newUserData['name'],
        ),
      ),
    );
  }


  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }
}