import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animations/animations.dart';
import '../../data/sources/auth_service.dart';
import 'store_page.dart';
import 'home_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        _nameController.text,
        _passwordController.text,
      );
      log("DEBUG: Respon diterima: ${response?.statusCode}");

      if (response != null && response.statusCode == 200) {
        final dataMap = response.data['data'];
        final userData = dataMap['user'];
        final stores = dataMap['stores'] ?? [];

        final String userName = userData['name']?.toString() ?? '';
        final String roleName = userData['role_name']?.toString() ?? '';
        final int roleId = int.tryParse(userData['role_id']?.toString() ?? '0') ?? 0;
        final int storeId = int.tryParse(userData['store_id']?.toString() ?? '0') ?? 0;

        log("User: $userName, Role: $roleName (ID: $roleId), Store: $storeId", name: "LOGIN_PAGE");

        if (mounted) {
          // ← ANIMASI TRANSISI dengan animations package
          final Widget nextPage = (roleName.toUpperCase() == 'OWNERS' ||
                  roleName.toUpperCase() == 'SUPER USERS')
              ? StorePage(
                  userName: userName,
                  userRole: roleId.toString(),
                  userRoleName: roleName,
                  availableStores: List<Map<String, dynamic>>.from(stores),
                )
              : HomePage(
                  storeId: storeId,
                  userRole: roleId.toString(),
                  userRoleName: roleName,
                  userName: userName,
                );

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) => nextPage,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // ← FadeThroughTransition dari package animations
                return FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              },
            ),
          );
        }
      } else {
        _showError("User name atau Password salah!");
      }
    } catch (e) {
      _showError("Terjadi kesalahan jaringan: $e");
      log("LOGIN ERROR: $e", name: "LOGIN_PAGE");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 13.sp)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──────────────────────────────────────
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance,
                      size: 64.sp,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'BRI POST',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00529C),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Manajemen Penjualan Cerdas',
                    style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                  ),
                  SizedBox(height: 48.h),

                  // ── Username ──────────────────────────────────
                  TextField(
                    controller: _nameController,
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'user name',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: Colors.blue.shade100),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Password ──────────────────────────────────
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20.sp,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: Colors.blue.shade100),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      );
                      },
                      child: Text(
                        'Lupa Password?',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── Login Button ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00529C),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.blue.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'MASUK',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  Text(
                    'Versi 1.0.2',
                    style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}