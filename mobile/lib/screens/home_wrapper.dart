import 'package:flutter/material.dart';

<<<<<<< HEAD
// Import your actual dashboard screens
import 'package:fyp/screens/resident_dashboard.dart';        // Resident Dashboard
import 'package:fyp/screens/vendor_dashboard.dart';          // Vendor Dashboard
import 'package:fyp/screens/ward_admin_dashboard.dart';      // Ward Admin Dashboard
=======
import 'package:fyp/screens/resident_dashboard.dart';
import 'package:fyp/admin/vendor_dashboard.dart';
import 'package:fyp/admin/ward_admin_dashboard.dart';
>>>>>>> main



class HomeWrapper extends StatelessWidget {
  final String role;
  final String userName;
<<<<<<< HEAD
=======
  final String phone;
  final String email;
  final String? ward;
>>>>>>> main

  const HomeWrapper({
    super.key,
    required this.role,
    required this.userName,
<<<<<<< HEAD
=======
    required this.phone,
    required this.email,
    this.ward,
>>>>>>> main
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
=======

    // DEBUG: Print what  received
    print('=== HomeWrapper.build() ===');
    print('widget.ward: $ward');
    print('role: $role');
    print('userName: $userName');
    print('=== End HomeWrapper ===');



>>>>>>> main
    final String normalizedRole = role.toLowerCase().trim();

    switch (normalizedRole) {
      case 'resident':
<<<<<<< HEAD
        return ResidentDashboardScreen(userName: userName);
=======
        return ResidentDashboardScreen(
          userName: userName,
          phone: phone,
          email: email,
          ward: ward,
        );
>>>>>>> main

      case 'vendor':
        return const VendorDashboardScreen();

      case 'ward admin':
<<<<<<< HEAD
      case 'ward_admin': // In case backend sends with underscore
       return const WardAdminDashboardScreen();

      default:
      // Fallback to Resident if role is unknown or invalid
        return ResidentDashboardScreen(userName: userName);
=======
      case 'ward_admin':
        return const WardAdminDashboardScreen();

      default:
        return ResidentDashboardScreen(
          userName: userName,
          phone: phone,
          email: email,
          ward: ward,
        );
>>>>>>> main
    }
  }
}