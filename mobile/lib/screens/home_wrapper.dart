import 'package:flutter/material.dart';

import 'package:fyp/screens/resident_dashboard.dart';
import 'package:fyp/admin/vendor_dashboard.dart';
import 'package:fyp/admin/ward_admin_dashboard.dart';

class HomeWrapper extends StatelessWidget {
  final String role;
  final String userName;
  final String phone;
  final String email;

  // ERD: ward can be String OR Map {id, name}
  final Object? ward;

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
    final normalizedRole = role.toLowerCase().trim();

    if (normalizedRole == 'vendor') return const VendorDashboardScreen();
    if (normalizedRole == 'ward admin' || normalizedRole == 'ward_admin' || normalizedRole == 'wardadmin') {
      return const WardAdminDashboardScreen();
    }

    // default resident
    return ResidentDashboardScreen(
      userName: userName,
      phone: phone,
      email: email,
      ward: ward, // pass raw
    );
  }
}