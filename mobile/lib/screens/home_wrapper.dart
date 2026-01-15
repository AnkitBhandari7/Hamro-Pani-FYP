import 'package:flutter/material.dart';

import 'package:fyp/screens/resident_dashboard.dart';
import 'package:fyp/admin/vendor_dashboard.dart';
import 'package:fyp/admin/ward_admin_dashboard.dart';



class HomeWrapper extends StatelessWidget {
  final String role;
  final String userName;
  final String phone;
  final String email;
  final String? ward;

  const HomeWrapper({
    super.key,
    required this.role,
    required this.userName,
    required this.phone,
    required this.email,
    this.ward,
  });

  @override
  Widget build(BuildContext context) {

    // DEBUG: Print what  received
    print('=== HomeWrapper.build() ===');
    print('widget.ward: $ward');
    print('role: $role');
    print('userName: $userName');
    print('=== End HomeWrapper ===');



    final String normalizedRole = role.toLowerCase().trim();

    switch (normalizedRole) {
      case 'resident':
        return ResidentDashboardScreen(
          userName: userName,
          phone: phone,
          email: email,
          ward: ward,
        );

      case 'vendor':
        return const VendorDashboardScreen();

      case 'ward admin':
      case 'ward_admin':
        return const WardAdminDashboardScreen();

      default:
        return ResidentDashboardScreen(
          userName: userName,
          phone: phone,
          email: email,
          ward: ward,
        );
    }
  }
}