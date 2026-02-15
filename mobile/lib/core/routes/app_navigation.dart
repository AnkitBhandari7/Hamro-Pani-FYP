import 'package:flutter/material.dart';

import 'package:fyp/core/routes/routes.dart';
import 'package:fyp/screens/home_wrapper.dart';
import 'package:fyp/admin/profile/ward_admin_profile_screen.dart';
import 'package:fyp/auth/login_view.dart';
import 'package:fyp/auth/signup_view.dart';

import 'package:fyp/profile/profile_screen.dart';
import 'package:fyp/notifications/notifications_screen.dart';

import 'package:fyp/booking/orders_screen.dart';
import 'package:fyp/booking/new_schedule.dart';
import 'package:fyp/booking/create_slot.dart';

import 'package:fyp/admin/send_notice.dart';

class AppNavigation {
  static String? wardNameFrom(Object? ward) {
    if (ward == null) return null;
    if (ward is String) return ward;
    if (ward is Map) return ward['name']?.toString();
    return ward.toString();
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginView());

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignUpView());

      case AppRoutes.home:
        final args = settings.arguments as Map<String, dynamic>?;

        final String role = (args?['role'] ?? 'RESIDENT').toString();
        final String userName = (args?['userName'] ?? 'User').toString();
        final String phone = (args?['phone'] ?? '').toString();
        final String email = (args?['email'] ?? '').toString();

        //  ward can be Map now
        final Object? ward = args?['ward'];

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

        final Object? wardRaw = args?['ward'];
        final String? wardName = wardNameFrom(wardRaw);

        return MaterialPageRoute(
          builder: (_) => ProfileScreen(
            userName: (args?['userName'] ?? 'User').toString(),
            phone: (args?['phone'] ?? '').toString(),
            email: (args?['email'] ?? '').toString(),
            ward: wardName,
          ),
        );

      case AppRoutes.orders:
        return MaterialPageRoute(builder: (_) => const OrderScreen());

      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());


     case AppRoutes.wardAdminProfile:
       return MaterialPageRoute(builder: (_) => const WardAdminProfileScreen());

      case AppRoutes.sendNotice:
        return MaterialPageRoute(builder: (_) => const SendNoticeScreen());

      case AppRoutes.manageSlots:
        return MaterialPageRoute(builder: (_) => const ManageSlotsScreen());

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

  //  ward is Object? now
  static Future<T?> pushHomeWithRole<T extends Object?>(
      BuildContext context, {
        required String role,
        required String userName,
        required String phone,
        required String email,
        Object? ward,
      }) {
    return offAll(
      context,
      AppRoutes.home,
      arguments: {
        'role': role,
        'userName': userName,
        'phone': phone,
        'email': email,
        'ward': ward, // keep map
      },
    );
  }
}