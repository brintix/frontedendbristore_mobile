import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/sources/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  // Warna tema agar konsisten
  static const _primary = Color(0xFF00529C);
  static const _accent = Colors.blueAccent;

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan alamat email yang valid')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.forgotPassword(email);

      if (mounted) {
        if (response?.statusCode == 200) {
          _showSuccessDialog();
        } else {
          final message = response?.data['message'] ?? 'Gagal mengirim email';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: const Text('Email Terkirim'),
        content: const Text(
            'Silakan periksa kotak masuk email Anda untuk instruksi reset password.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman Login
            },
            child: const Text('Kembali ke Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Lupa Password', 
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _accent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Atur Ulang Password",
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: _primary),
            ),
            SizedBox(height: 8.h),
            Text(
              "Masukkan email yang terdaftar. Kami akan mengirimkan tautan untuk mengatur ulang password Anda.",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 32.h),
            
            // Input Email
            Text(
              "Email",
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: _primary),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "example@mail.com",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            
            const Spacer(),
            
            // Tombol Kirim
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleForgotPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "KIRIM INSTRUKSI",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp
                        ),
                      ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}