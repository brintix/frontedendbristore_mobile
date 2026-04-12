import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animations/animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/sources/auth_service.dart';
import 'home_page.dart';

class StorePage extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userRoleName;
  final List<Map<String, dynamic>> availableStores;

  const StorePage({
    super.key,
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
        title: Text(
          '${widget.userName} - ${widget.userRoleName}',
          style: TextStyle(fontSize: 16.sp),
        ),
        backgroundColor: const Color(0xFF00529C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, size: 22.sp),
            onPressed: () => _logout(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
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
            padding: EdgeInsets.all(24.w),
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
            child: Icon(
              Icons.storefront_outlined,
              size: 80.sp,
              color: const Color(0xFF00529C),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Tidak ada toko tersedia',
            style: TextStyle(
              fontSize: 18.sp,
              color: const Color(0xFF00529C),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: 200.w,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00529C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('Kembali', style: TextStyle(fontSize: 14.sp)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: widget.availableStores.length,
      itemBuilder: (context, index) {
        final store = widget.availableStores[index];
        return Card(
          elevation: 8,
          margin: EdgeInsets.only(bottom: 16.h),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: Colors.blue.shade100),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () => _selectStore(store),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  // ← GANTI CircleAvatar ID dengan icon toko
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00529C).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00529C).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,       // ← icon toko
                      size: 30.sp,
                      color: const Color(0xFF00529C),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store['name'] ?? 'Toko Tanpa Nama',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00529C),
                          ),
                        ),
                        if ((store['address'] ?? '').toString().isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 13.sp, color: Colors.grey),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  store['address'],
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if ((store['phone'] ?? '').toString().isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined,
                                  size: 13.sp, color: Colors.blueGrey),
                              SizedBox(width: 4.w),
                              Text(
                                store['phone'],
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: const Color(0xFF00529C),
                    size: 16.sp,
                  ),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    ).then((_) {});

    Response? response;
    try {
      response = await _authService.selectStore(store['id']);
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: TextStyle(fontSize: 13.sp)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) Navigator.of(context).pop();
    if (!mounted || response.statusCode != 200) return;

    final data = response.data['data'];
    final newUserData = data['user'];
    final newToken = data['token'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', newToken);
    await prefs.setInt('store_id', newUserData['store_id']);
    await prefs.setString('name', newUserData['name']);

    log("✅ Store ID: ${newUserData['store_id']} - Token UPDATED", name: "STORE_PAGE");

    if (!mounted) return;

    // ← ANIMASI: FadeThroughTransition ke HomePage
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => HomePage(
          storeId: newUserData['store_id'],
          userRole: newUserData['role_id'].toString(),
          userRoleName: widget.userRoleName,
          userName: newUserData['name'],
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
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