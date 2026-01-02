// lib/views/profile/profile_screen.dart
import 'package:flutter/material.dart';
import '../../core/routes/app_navigation.dart';
import '../../core/routes/routes.dart';
import '../../services/auth_service.dart'; // for logout

class ProfileScreen extends StatelessWidget {
  static const String route = '/profile';
  const ProfileScreen({super.key});

  // Sample user data - replace with real data from Firebase/Auth later
  final String displayName = "TankerTap Admin";
  final String email = "vannextgen@gmail.com";
  final String phone = "8088604017";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF007BFF),
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Edit Profile - Coming Soon!")),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 30, bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF007BFF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.blue[100],
                    child: const Icon(Icons.person, size: 60, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Menu Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(
                  icon: Icons.shield_outlined,
                  title: "Terms & Conditions",
                  onTap: () {
                    // Navigate or show dialog
                  },
                ),
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: "Help & Support",
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: "About",
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: "TankerTap",
                      applicationVersion: "1.0.0",
                      applicationIcon: Image.asset('assets/images/logo.png', height: 50),
                      children: const [
                        Text("Water Tanker Booking App\nMade with ❤️ in Nepal & India"),
                      ],
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: "Change Password",
                  color: Colors.orange[700],
                  onTap: () {
                    // Navigate to Change Password Screen
                    AppNavigation.to(context, '/change-password');
                  },
                ),
                const Divider(height: 30),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: "Logout",
                  color: Colors.red,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text("Logout", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await AuthService().signOut();
                      AppNavigation.offAll(context, AppRoutes.login);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation (Optional - keep consistent with other screens)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF007BFF),
        currentIndex: 2, // Profile tab
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: (index) {
          if (index == 0) AppNavigation.to(context, AppRoutes.home);
          if (index == 1) AppNavigation.to(context, AppRoutes.orders);
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (color ?? Colors.blue[600])!.withOpacity(0.1),
          child: Icon(icon, color: color ?? Colors.blue[700]),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color ?? Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}