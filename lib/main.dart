import 'package:flutter/material.dart';
import 'presentation/pages/login_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(                          // ← TAMBAHKAN
      designSize: const Size(390, 844),             // ← referensi ukuran desain
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'BRI POS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
            useMaterial3: true,
          ),
          home: child,                              // ← ganti dari LoginPage()
        );
      },
      child: const LoginPage(),                     // ← pindah ke sini
    );
  }
}
// {"name": "mr Bre", "password": "password123"}
