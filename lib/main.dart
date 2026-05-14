import 'package:flutter/material.dart';
import 'presentation/pages/login_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

/*
Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://c3ad01bfa811b2839f8056de7e8ea55d@o4511215214264320.ingest.us.sentry.io/4511215216033792';  
      options.sendDefaultPii = true;
      options.enableLogs = true;
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child: const MyApp())),
  );
  await Sentry.captureException(StateError('This is a sample exception.'));
}
*/
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
