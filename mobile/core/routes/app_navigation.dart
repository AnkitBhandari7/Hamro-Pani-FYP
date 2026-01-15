import 'package:flutter/material.dart';
import '../../views/auth/login_view.dart';
import '../../views/auth/signup_view.dart';
import '../../views/screens/home_screen.dart';
import '../../views/screens/orders_screen.dart';
import '../../views/screens/profile_screen.dart';
import '../../views/screens/notifications_screen.dart';
import 'routes.dart';

class AppNavigation {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginView());
      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignUpView());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.orders:
        return MaterialPageRoute(builder: (_) => const OrderScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  // Easy navigation without BuildContext
  static Future<T?> to<T extends Object?>(
      BuildContext context,
      String route, {
        Object? arguments,
      }) {
    return Navigator.pushNamed(context, route, arguments: arguments);
  }

  static Future<T?> offAll<T extends Object?>(
      BuildContext context,
      String route, {
        Object? arguments,
      }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      route,
          (route) => false,
      arguments: arguments,
    );
  }

  static void pop(BuildContext context) => Navigator.pop(context);
}