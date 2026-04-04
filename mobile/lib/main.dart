import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart' as pv;

import 'firebase_options.dart';
import 'app/config/app_config.dart';
import 'core/routes/app_navigation.dart';
import 'core/routes/routes.dart';
import 'package:fyp/features/shared/notifications/services/fcm_service.dart';
import 'core/localization/locale_controller.dart';

import 'package:fyp/l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Create + preload locale BEFORE runApp
  final localeController = LocaleController();
  await localeController.loadFromDevice();

  try {
    await FCMService().initialize(
      onTap: (data) {
        navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
      },
    );
  } catch (e) {
    debugPrint('FCM initialization error (non-fatal): $e');
  }

  if (kDebugMode) {
    debugPrint('API Base URL => $kApiBaseUrl');
    await _testHealth();
  }

  runApp(
    ProviderScope(
      child: pv.MultiProvider(
        providers: [
          pv.ChangeNotifierProvider<LocaleController>.value(
            value: localeController,
          ),
        ],
        child: const TankerTapApp(),
      ),
    ),
  );
}

class TankerTapApp extends StatelessWidget {
  const TankerTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = context.watch<LocaleController>();

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
            textTheme: GoogleFonts.poppinsTextTheme(),
            scaffoldBackgroundColor: Colors.white,
          ),

          // Localization now uses persisted locale
          locale: localeCtrl.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,

          initialRoute: AppRoutes.initial,
          onGenerateRoute: AppNavigation.generateRoute,
        );
      },
    );
  }
}

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