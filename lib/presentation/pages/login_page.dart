// login_page.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import '../../data/sources/auth_service.dart';
import 'store_page.dart';
import 'home_page.dart';

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
  bool _obscurePassword = true; // UX: State untuk toggle password

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
        // 🔥 Extract data aman
        final String userName = userData['name']?.toString() ?? '';
        final String roleName = userData['role_name']?.toString() ?? '';
        final int roleId = int.tryParse(userData['role_id']?.toString() ?? '0') ?? 0;
        final int storeId = int.tryParse(userData['store_id']?.toString() ?? '0') ?? 0;
      log("User: $userName, Role: $roleName (ID: $roleId), Store: $storeId, Stores: ${stores.length}", name: "LOGIN_PAGE");

      if (mounted) {
        // 🔥 SPECIAL ROLES → StorePage
        if (roleName.toUpperCase() == 'OWNERS' || roleName.toUpperCase() == 'SUPER USERS') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StorePage(
                userName: userName,
                userRole: roleId.toString(),
                userRoleName: roleName,
                availableStores: List<Map<String, dynamic>>.from(stores),
              ),
            ),
          );
        } else {
          // 🔥 Role biasa → HomePage langsung
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                storeId: storeId,
                userRole: roleId.toString(),
                userRoleName: roleName,
                userName: userName,
              ),
            ),
          );
        }
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
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating, // UX: Lebih modern melayang
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    // final theme = Theme.of(context);
    // final primaryColor = theme.colorScheme.primary;
    
    return Scaffold(
      // UX: Background dengan gradasi lembut
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
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: const Icon(Icons.account_balance, size: 64, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'BRI POST',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00529C), // Warna khas BRI
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'Manajemen Penjualan Cerdas',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 48),

                  // Input Fields
                  TextField(
                    controller: _nameController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'user name',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.blue.shade100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      // UX: Toggle visibilitas password
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.blue.shade100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Lupa Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00529C),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.blue.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'MASUK',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Versi 1.0.2',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
// 