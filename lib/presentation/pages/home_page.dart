import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animations/animations.dart';
// import 'dart:developer'; // Untuk log jika diperlukan
import '../../data/sources/auth_service.dart';
import 'login_page.dart';
import 'product_page.dart';
import 'cashier_page.dart';
import 'transaction_store_page.dart';

class HomePage extends StatelessWidget {
  final int storeId;
  final String userRole;
  final String userRoleName;
  final String userName;

  const HomePage({
    super.key,
    required this.storeId,
    required this.userRole,
    required this.userRoleName,
    required this.userName,
  });

  void _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    
    // Menggunakan MaterialPageRoute standar untuk logout agar lebih ringan
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00529C),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(
              "BRI POS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              userName,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white, size: 22.sp),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 20.w,
              mainAxisSpacing: 20.h,
              children: [
                // Menggunakan builder function agar halaman tidak di-load di awal
                _buildAnimatedMenu(
                  context,
                  icon: Icons.inventory_2,
                  label: "Produk",
                  pageBuilder: () => ProductPage(storeId: storeId),
                ),
                _buildAnimatedMenu(
                  context,
                  icon: Icons.point_of_sale,
                  label: "Kasir",
                  pageBuilder: () => CashierPage(
                    userName: userName,
                    userRole: userRole,
                    userRoleName: userRoleName,
                    storeId: storeId,
                  ),
                ),
                _buildAnimatedMenu(
                  context, 
                  icon: Icons.receipt_long, 
                  label: "Transaksi Toko", 
                  pageBuilder: () => const TransactionStorePage(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMenu(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget Function() pageBuilder, // Perubahan ke builder function
  }) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 450), // Sedikit diperhalus
      transitionType: ContainerTransitionType.fadeThrough,
      openColor: const Color(0xFFF8FAFC),
      closedColor: Colors.white,
      closedElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      // Halaman baru benar-benar dibuat saat fungsi ini dipanggil (saat klik)
      openBuilder: (context, _) => pageBuilder(),
      closedBuilder: (context, openContainer) => InkWell(
        onTap: openContainer,
        borderRadius: BorderRadius.circular(15.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.sp, color: const Color(0xFF00529C)),
            SizedBox(height: 10.h),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}