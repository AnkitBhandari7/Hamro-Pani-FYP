import 'package:flutter/material.dart';

import 'package:fyp/core/routes/routes.dart';
import 'package:fyp/screens/home_wrapper.dart';

import 'package:fyp/auth/login_view.dart';
import 'package:fyp/auth/signup_view.dart';

import 'package:fyp/profile/profile_screen.dart';
import 'package:fyp/notifications/notifications_screen.dart';

import 'package:fyp/booking/orders_screen.dart';
import 'package:fyp/booking/new_schedule.dart';

// NEW: import your manage-slots screen
import 'package:fyp/booking/create_slot.dart';

import 'package:fyp/admin/send_notice.dart';

class AppNavigation {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginView());

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignUpView());

      case AppRoutes.home:
        final args = settings.arguments as Map<String, dynamic>?;

        // DEBUG
        print('=== generateRoute: AppRoutes.home ===');
        print('args: $args');
        print('args[ward]: ${args?['ward']}');
        print('=== End generateRoute ===');

        final String role = args?['role'] ?? 'Resident';
        final String userName = args?['userName'] ?? 'User';
        final String phone = args?['phone'] ?? '';
        final String email = args?['email'] ?? '';
        final String? ward = args?['ward'];

        print('=== Extracted ward: $ward ===');

        return MaterialPageRoute(
          builder: (_) => HomeWrapper(
            role: role,
            userName: userName,
            phone: phone,
            email: email,
            ward: ward,
          ),
        );

      case AppRoutes.newSchedule:
        return MaterialPageRoute(builder: (_) => const NewScheduleScreen());

      case AppRoutes.profile:
        final args = settings.arguments as Map<String, dynamic>?;

        print('=== generateRoute: AppRoutes.profile ===');
        print('profile args: $args');
        print('=== End ===');

        return MaterialPageRoute(
          builder: (_) => ProfileScreen(
            userName: args?['userName'] ?? 'User',
            phone: args?['phone'] ?? '',
            email: args?['email'] ?? '',
            ward: args?['ward'],
          ),
        );

      case AppRoutes.orders:
        return MaterialPageRoute(builder: (_) => const OrderScreen());

      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());

      case AppRoutes.sendNotice:
        return MaterialPageRoute(builder: (_) => const SendNoticeScreen());

    // NEW: Vendor Manage Slots screen
      case AppRoutes.manageSlots:
        return MaterialPageRoute(
          builder: (_) => const ManageSlotsScreen(),
        );

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

  static Future<T?> push<T extends Object?>(
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

  // Updated: Now accepts phone and email
  static Future<T?> pushHomeWithRole<T extends Object?>(
      BuildContext context, {
        required String role,
        required String userName,
        required String phone,
        required String email,
        String? ward,
      }) {
    // DEBUG
    print('=== pushHomeWithRole called ===');
    print('role: $role');
    print('userName: $userName');
    print('phone: $phone');
    print('email: $email');
    print('ward: $ward');
    print('=== End pushHomeWithRole ===');

    return offAll(
      context,
      AppRoutes.home,
      arguments: {
        'role': role,
        'userName': userName,
        'phone': phone,
        'email': email,
        'ward': ward,
      },
    );
  }
}