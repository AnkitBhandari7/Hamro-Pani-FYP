import 'package:flutter/material.dart';

// Import your actual dashboard screens
import 'package:fyp/screens/resident_dashboard.dart';        // Resident Dashboard
import 'package:fyp/screens/vendor_dashboard.dart';          // Vendor Dashboard
import 'package:fyp/screens/ward_admin_dashboard.dart';      // Ward Admin Dashboard



class HomeWrapper extends StatelessWidget {
  final String role;
  final String userName;

  const HomeWrapper({
    super.key,
    required this.role,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final String normalizedRole = role.toLowerCase().trim();

    switch (normalizedRole) {
      case 'resident':
        return ResidentDashboardScreen(userName: userName);

      case 'vendor':
        return const VendorDashboardScreen();

      case 'ward admin':
      case 'ward_admin': // In case backend sends with underscore
       return const WardAdminDashboardScreen();

      default:
      // Fallback to Resident if role is unknown or invalid
        return ResidentDashboardScreen(userName: userName);
    }
  }
}