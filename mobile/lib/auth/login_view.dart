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

  static const String _baseUrl = "http://10.0.2.2:3000";

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

  // Ward helper: backend can return ward as String or Map {id,name}
  String? _wardNameFrom(dynamic wardRaw) {
    if (wardRaw == null) return null;
    if (wardRaw is String) return wardRaw;
    if (wardRaw is Map) return wardRaw['name']?.toString();
    return wardRaw.toString();
  }

  String _selectedRoleToBackendRole(String selected) {
    final s = selected.toLowerCase().trim();
    if (s == "resident") return "RESIDENT";
    if (s == "vendor") return "VENDOR";
    if (s == "ward admin") return "WARD_ADMIN";
    return "RESIDENT";
  }

  // Normalize backend role values (handles RESIDENT/VENDOR/WARD_ADMIN and old values)
  String _normalizeBackendRole(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'resident' || r == 'residents') return 'resident';
    if (r == 'vendor' || r == 'vendors') return 'vendor';

    if (r == 'ward_admin' || r == 'ward admin' || r == 'wardadmin') {
      return 'ward admin';
    }

    // handle enums (RESIDENT/VENDOR/WARD_ADMIN)
    if (r == 'resident'.toUpperCase().toLowerCase()) return 'resident';
    if (r == 'vendor'.toUpperCase().toLowerCase()) return 'vendor';
    if (r == 'ward_admin'.toUpperCase().toLowerCase()) return 'ward admin';

    return r; // unknown => leave as-is
  }

  String _normalizeSelectedRole(String selectedRole) {
    final s = selectedRole.toLowerCase().trim();
    if (s == 'ward admin' || s == 'ward_admin') return 'ward admin';
    return s;
  }

  bool _isRoleMatch(String actualRole, String selectedRole) {
    final actual = _normalizeBackendRole(actualRole);
    final selected = _normalizeSelectedRole(selectedRole);
    return actual == selected;
  }

  /// Shared post-login flow for both Email login and Google login
  Future<void> _postFirebaseLogin({required String idToken}) async {
    final selectedRoleName = roles[selectedRole];
    final backendRole = _selectedRoleToBackendRole(selectedRoleName);

    // 1) Get profile first (do NOT overwrite role on login)
    http.Response meResponse = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    // 2) If user is not in backend DB yet, create user ONCE with selected role
    if (meResponse.statusCode == 404) {
      final registerResponse = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'role': backendRole}),
      );

      debugPrint("=== Register Response ===");
      debugPrint("Status: ${registerResponse.statusCode}");
      debugPrint("Body: ${registerResponse.body}");

      if (registerResponse.statusCode != 200) {
        throw Exception("Failed to register user (HTTP ${registerResponse.statusCode})");
      }

      // retry /auth/me after register
      meResponse = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
    }

    debugPrint("=== /auth/me Response ===");
    debugPrint("Status: ${meResponse.statusCode}");
    debugPrint("Body: ${meResponse.body}");

    if (meResponse.statusCode != 200) {
      throw Exception("Failed to load user profile (HTTP ${meResponse.statusCode})");
    }

    final userData = json.decode(meResponse.body) as Map<String, dynamic>;

    final String userRole = (userData['role'] ?? 'RESIDENT').toString();
    final String userName = (userData['name'] ?? 'User').toString();
    final String phone = (userData['phone'] ?? '').toString();
    final String userEmail = (userData['email'] ?? '').toString();

    final Object? wardRaw = userData['ward']; // can be Map {id,name}
    final String? wardName = _wardNameFrom(wardRaw);

    debugPrint("=== User Data ===");
    debugPrint("Role: $userRole");
    debugPrint("Name: $userName");
    debugPrint("Ward(raw): $wardRaw");
    debugPrint("Ward(name): $wardName");

    // 3) Role-based access check
    if (!_isRoleMatch(userRole, selectedRoleName)) {
      await FirebaseAuth.instance.signOut();
      throw Exception("You are registered as '$userRole'. Please select the correct role tab.");
    }

    // 4) FCM setup (non-fatal)
    try {
      await FCMService().saveTokenAfterLogin();
      debugPrint("FCM token saved after login");
    } catch (fcmError) {
      debugPrint("FCM token save error (non-fatal): $fcmError");
    }

    await _subscribeToTopics(role: userRole, wardName: wardName);

    // 5) Navigate
    if (!mounted) return;
    AppNavigation.pushHomeWithRole(
      context,
      role: userRole,
      userName: userName,
      phone: phone,
      email: userEmail,
      ward: wardRaw,
    );
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

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _showError("Firebase user not found");
        setState(() => _isLoading = false);
        return;
      }

      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw Exception("Failed to get Firebase ID token");
      }

      await _postFirebaseLogin(idToken: idToken);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Login error: $e");
      _showError(e.toString().replaceFirst("Exception: ", ""));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = await _authController.googleLogin(
        remember: true,
        context: context,
      );

      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _showError("Firebase user not found");
        setState(() => _isLoading = false);
        return;
      }

      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw Exception("Failed to get Firebase ID token");
      }

      await _postFirebaseLogin(idToken: idToken);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Google login error: $e");
      _showError(e.toString().replaceFirst("Exception: ", ""));
      setState(() => _isLoading = false);
    }
  }


  Future<void> _subscribeToTopics({required String role, String? wardName}) async {
    final fcmService = FCMService();
    final normalizedRole = _normalizeBackendRole(role);

    try {
      if (normalizedRole == 'resident') {
        await fcmService.subscribeToAllResidents();

        if (wardName != null && wardName.trim().isNotEmpty) {
          await fcmService.subscribeToWard(wardName.trim());
        }
      } else if (normalizedRole == 'vendor') {
        await fcmService.subscribeToAllVendors();
      }
    } catch (e) {
      debugPrint("Topic subscription error (non-fatal): $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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

                Text(
                  "Hamro Pani",
                  style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  "Kathmandu's Smart Water Management",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 40),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Welcome Back",
                    style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
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

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Enter Your Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Enter Your Password",
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
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: Text("Forgot?", style: GoogleFonts.poppins(color: Colors.blue)),
                  ),
                ),

                const SizedBox(height: 20),

                // Sign in
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
                        : Text(
                      "Sign In →",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
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

                // Google login button (FIXED)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    icon: Image.asset('assets/images/google_logo.webp', height: 24),
                    label: Text("Google", style: GoogleFonts.poppins(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Signup
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: GoogleFonts.poppins()),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, SignUpView.route),
                      child: Text(
                        "Sign up now",
                        style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}