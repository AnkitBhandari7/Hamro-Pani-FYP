import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/theme/app_theme.dart';
import 'views/auth/login_view.dart';
import 'views/auth/signup_view.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'app/config/app_config.dart';
import 'core/routes/routes.dart';
import 'core/routes/app_navigation.dart';





void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Debug: Print API URL & health check
  if (kDebugMode) {
    debugPrint('API Base URL => $kApiBaseUrl');
    await _testHealth();
  }

  runApp(const TankerTapApp());
}

class TankerTapApp extends StatelessWidget {
  const TankerTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tanker Tap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      // Professional routing system
      initialRoute: AppRoutes.initial,                    // ← Starts at login
      onGenerateRoute: AppNavigation.generateRoute,      // ← All routes here
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text("404 - Page Not Found")),
        ),
      ),
    );
  }
}

// Optional: Health check (keep it, very useful during dev)
Future<void> _testHealth() async {
  try {
    final dio = Dio(BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    final res = await dio.get('/health');
    debugPrint('Health: ${res.data}');
  } catch (e) {
    debugPrint('Health check failed: $e');
  }
}