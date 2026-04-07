import 'package:flutter/material.dart';
import '../../data/sources/auth_service.dart';
import 'login_page.dart';
import 'product_page.dart';
import 'cashier_page.dart';

class HomePage extends StatelessWidget {
  final int storeId;
  final String userRole;
  final String userName;

  const HomePage({
    super.key,
    required this.storeId,
    required this.userRole,
    required this.userName,
  });

  void _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
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
            const Text(
              "BRI POST",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              userName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                // Menu Produk
                _buildSimpleMenu(
                  context,
                  icon: Icons.inventory_2, // Ikon Produk (Box/Stok)
                  label: "Produk",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProductPage(storeId: storeId)),
                  ),
                ),
                // Menu Kasir
                _buildSimpleMenu(
                  context,
                  icon: Icons.point_of_sale, // Ikon Kasir (Mesin Kasir)
                  label: "Kasir",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CashierPage(
                        userName: userName,
                        userRole: userRole,
                        storeId: storeId,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleMenu(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF00529C)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}