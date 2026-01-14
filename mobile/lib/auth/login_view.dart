import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:fyp/auth/auth_controller.dart';
import 'package:fyp/auth/auth_service.dart';
import 'package:fyp/notifications/fcm_service.dart';
import '../../core/routes/app_navigation.dart';
import '../../core/routes/routes.dart';
import 'signup_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginView extends StatefulWidget {
  static const String route = '/login';
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  int selectedRole = 0;
  final List<String> roles = ["Resident", "Vendor", "Ward Admin"];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter email and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase Authentication
      final user = await _authController.login(
        email: email,
        password: password,
        remember: true,
        context: context,
      );

      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get Firebase ID Token
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _showError("Firebase user not found");
        setState(() => _isLoading = false);
        return;
      }

      final idToken = await firebaseUser.getIdToken(true);
      print("=== Firebase ID Token ===");
      print(idToken);
      print("=== End Token ===");

      // Register/Get user from backend
      final registerResponse = await http.post(
        Uri.parse('http://10.0.2.2:3000/auth/register'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': firebaseUser.displayName ?? email.split('@')[0],
        }),
      );

      print("=== Register Response ===");
      print("Status: ${registerResponse.statusCode}");
      print("Body: ${registerResponse.body}");

      if (registerResponse.statusCode != 200) {
        _showError("Failed to register user");
        setState(() => _isLoading = false);
        return;
      }

      // Get user profile
      final meResponse = await http.get(
        Uri.parse('http://10.0.2.2:3000/auth/me'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      print("=== /auth/me Response ===");
      print("Status: ${meResponse.statusCode}");
      print("Body: ${meResponse.body}");

      if (meResponse.statusCode != 200) {
        _showError("Failed to load user profile");
        setState(() => _isLoading = false);
        return;
      }

      final userData = json.decode(meResponse.body);

      final String userRole = userData['role'] ?? 'Resident';
      final String userName = userData['name'] ?? 'User';
      final String phone = userData['phone'] ?? '';
      final String userEmail = userData['email'] ?? '';
      final String? ward = userData['ward'];

      print("=== User Data ===");
      print("Role: $userRole");
      print("Name: $userName");
      print("Ward: $ward");

      // Validate selected role matches user's actual role
      final String selectedRoleName = roles[selectedRole];

      if (!_isRoleMatch(userRole, selectedRoleName)) {
        await FirebaseAuth.instance.signOut();
        _showError("You are registered as '$userRole'. Please select the correct role tab.");
        setState(() => _isLoading = false);
        return;
      }

      //FCM Setup
      // Save FCM token to backend
      try {
        await FCMService().saveTokenAfterLogin();
        print(" FCM token saved after login");
      } catch (fcmError) {
        print(" FCM token save error (non-fatal): $fcmError");
      }

      // Subscribe to appropriate topics based on role
      await _subscribeToTopics(role: userRole, ward: ward);
      // END FCM Setup

      setState(() => _isLoading = false);

      // Navigate to dashboard
      AppNavigation.pushHomeWithRole(
        context,
        role: userRole,
        userName: userName,
        phone: phone,
        email: userEmail,
        ward: ward,
      );

    } catch (e) {
      print("Login error: $e");
      _showError("Login failed: $e");
      setState(() => _isLoading = false);
    }
  }


  // Subscribe to FCM topics

  Future<void> _subscribeToTopics({required String role, String? ward}) async {
    final fcmService = FCMService();
    final normalizedRole = role.toLowerCase().trim();

    try {
      if (normalizedRole == 'resident') {
        // Residents subscribe to their ward topic
        if (ward != null && ward.isNotEmpty) {
          await fcmService.subscribeToWard(ward);
          print(" Resident subscribed to ward: $ward");
        } else {
          print(" Resident has no ward set, skipping topic subscription");
        }
      } else if (normalizedRole == 'vendor') {
        // Vendors subscribe to all_vendors topic
        await fcmService.subscribeToVendorNotifications();
        print(" Vendor subscribed to all_vendors topic");
      } else if (normalizedRole == 'ward admin' || normalizedRole == 'ward_admin') {
        // Ward Admin doesn't need to subscribe (they send notifications)
        print(" Ward Admin - no subscription needed");
      }
    } catch (e) {
      print(" Topic subscription error (non-fatal): $e");
    }
  }


  bool _isRoleMatch(String actualRole, String selectedRole) {
    final actual = actualRole.toLowerCase().trim();
    final selected = selectedRole.toLowerCase().trim();

    if (actual == 'resident' && selected == 'resident') return true;
    if (actual == 'vendor' && selected == 'vendor') return true;
    if ((actual == 'ward admin' || actual == 'ward_admin') &&
        (selected == 'ward admin' || selected == 'ward_admin')) return true;

    return false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20)],
                  ),
                  child: Image.asset(
                    'assets/images/hamropani_logo.png',
                    height: 60,
                    width: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.water_drop, size: 60, color: Colors.blue);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Text("Hamro Pani", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text("Kathmandu's Smart Water Management", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),

                const SizedBox(height: 40),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Welcome Back", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 20),

                // Role Tabs
                Container(
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    children: roles.asMap().entries.map((entry) {
                      int idx = entry.key;
                      String role = entry.value;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedRole = idx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedRole == idx ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              role,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontWeight: selectedRole == idx ? FontWeight.bold : FontWeight.normal,
                                color: selectedRole == idx ? Colors.blue : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 30),

                // Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "name@example.com",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () {}, child: Text("Forgot?", style: GoogleFonts.poppins(color: Colors.blue))),
                ),

                const SizedBox(height: 20),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("Sign In →", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 30),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Or continue with", style: GoogleFonts.poppins(color: Colors.grey[600])),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                // Google Login
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _authController.googleLogin(remember: true, context: context);
                    },
                    icon: Image.asset('assets/images/google_logo.webp', height: 24),
                    label: Text("Google", style: GoogleFonts.poppins(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: GoogleFonts.poppins()),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, SignUpView.route),
                      child: Text("Sign up now", style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Bottom Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(onPressed: () {}, child: Text("Help", style: GoogleFonts.poppins())),
                    TextButton(onPressed: () {}, child: Text("Privacy", style: GoogleFonts.poppins())),
                    TextButton(onPressed: () {}, child: Text("Terms", style: GoogleFonts.poppins())),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}