import 'package:flutter/material.dart';
import 'package:fyp/core/routes/routes.dart';

import 'package:fyp/features/resident/dashboard/views/home_wrapper.dart';
import 'package:fyp/features/vendor/profile/views/vendor_profile_screen.dart';
import 'package:fyp/features/resident/bookings/views/find_tankers_screen.dart';
import 'package:fyp/features/ward_admin/profile/views/ward_admin_profile_screen.dart';

import 'package:fyp/auth/login_view.dart';
import 'package:fyp/auth/signup_view.dart';
import 'package:fyp/auth/forgot_password_view.dart';

import 'package:fyp/features/resident/profile/views/profile_screen.dart';
import 'package:fyp/features/resident/profile/views/change_password_view.dart';
import 'package:fyp/features/resident/profile/views/language_preference_view.dart';

import 'package:fyp/features/shared/notifications/views/notifications_screen.dart';
import 'package:fyp/features/ward_admin/schedules/views/new_schedule_screen.dart';
import 'package:fyp/features/resident/bookings/views/create_slot.dart';
import 'package:fyp/features/complaints/report_issue_screen.dart';
import 'package:fyp/features/ward_admin/notices/views/send_notice.dart';

import 'package:fyp/features/shared/maps/views/location_picker_view.dart';
import 'package:fyp/features/vendor/bookings/views/vendor_bookings_screen.dart';

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

        // ward can be Map or String
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

      case AppRoutes.findTankers:
        return MaterialPageRoute(builder: (_) => const FindTankersScreen());

      case AppRoutes.reportIssue:
        return MaterialPageRoute(builder: (_) => const ReportIssueScreen());

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordView());

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

      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case AppRoutes.vendorProfile:
        return MaterialPageRoute(builder: (_) => const VendorProfileScreen());

      case AppRoutes.wardAdminProfile:
        return MaterialPageRoute(
          builder: (_) => const WardAdminProfileScreen(),
        );

      case AppRoutes.sendNotice:
        return MaterialPageRoute(builder: (_) => const SendNoticeScreen());

      case AppRoutes.manageSlots:
        return MaterialPageRoute(builder: (_) => const ManageSlotsScreen());

      case AppRoutes.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordView());

      case AppRoutes.languagePreference:
        return MaterialPageRoute(
          builder: (_) => const LanguagePreferenceView(),
        );

      case AppRoutes.locationPicker:
        return MaterialPageRoute(builder: (_) => const LocationPickerView());


    // vendor bookings screen
      case AppRoutes.vendorBookings:
        return MaterialPageRoute(builder: (_) => const VendorBookingsScreen());


      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
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
        'ward': ward,
      },
    );
  }
}
