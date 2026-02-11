import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'app/config/app_config.dart';
import 'core/routes/app_navigation.dart';
import 'core/routes/routes.dart';
import 'package:fyp/notifications/fcm_service.dart';

/// Global navigator key to navigate from notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('=== Background Message Received ===');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
  debugPrint('=== End Background Message ===');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background messages
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // FCM init
  try {
    await FCMService().initialize(
      onTap: (data) {
        final screen = data['screen']?.toString();
        if (screen == 'notifications') {
          navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
        } else {
          navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
        }
      },
    );
    debugPrint('FCM Service initialized in main');
  } catch (e) {
    debugPrint('FCM initialization error (non-fatal): $e');
  }

  // Debug health check
  if (kDebugMode) {
    debugPrint('API Base URL => $kApiBaseUrl');
    await _testHealth();
  }

  // Riverpod root
  runApp(const ProviderScope(child: TankerTapApp()));
}

class TankerTapApp extends StatelessWidget {
  const TankerTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Hamro Pani',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            primarySwatch: Colors.blue,

            // IMPORTANT: do not use fontFamily unless you actually bundled fonts
            textTheme: GoogleFonts.poppinsTextTheme(),

            // optional: keep your ScreenUtil sizes consistent
            scaffoldBackgroundColor: Colors.white,
          ),
          initialRoute: AppRoutes.initial,
          onGenerateRoute: AppNavigation.generateRoute,
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text("404 - Page Not Found")),
            ),
          ),
        );
      },
    );
  }
}

// Health check function
Future<void> _testHealth() async {
  try {
    final dio = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    final res = await dio.get('/health');
    debugPrint('Health: ${res.data}');
  } catch (e) {
    debugPrint('Health check failed: $e');
  }
}