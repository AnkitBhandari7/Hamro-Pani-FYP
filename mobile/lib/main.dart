import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';

import 'firebase_options.dart';
import 'app/config/app_config.dart';
import 'core/routes/routes.dart';
import 'core/routes/app_navigation.dart';
import 'package:fyp/notifications/fcm_service.dart';

///  Global navigator key to navigate from notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


//  Background message handler

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  //  Initialize FCM Service with onTap callback
  try {
    await FCMService().initialize(
      onTap: (data) {
        debugPrint("Tapped notification data: $data");

        final screen = data['screen']?.toString();

        //  routing based on screen
        if (screen == 'notifications') {
          navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
        } else if (screen == 'schedule') {


          navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
        } else {
          // default fallback
          navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
        }
      },
    );

    debugPrint(' FCM Service initialized in main');
  } catch (e) {
    debugPrint('️ FCM initialization error (non-fatal): $e');
  }

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
            primarySwatch: Colors.blue,
            fontFamily: 'Poppins',
            useMaterial3: true,
            textTheme: TextTheme(
              bodyMedium: TextStyle(fontSize: 14.sp),
            ),
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
    final dio = Dio(BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    final res = await dio.get('/health');
    debugPrint(' Health: ${res.data}');
  } catch (e) {
    debugPrint(' Health check failed: $e');
  }
}