import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:fyp/auth/auth_controller.dart';
import 'package:fyp/auth/auth_service.dart';
import '../../core/routes/app_navigation.dart';
import '../../core/routes/routes.dart';
import 'login_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpView extends StatefulWidget {
  static const String route = '/signup';
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  static const String _baseUrl = "http://10.0.2.2:3000";

  int selectedRole = 0;
  final List<String> roles = ["Resident", "Vendor", "Ward Admin"];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool isValidEmail(String email) {
      return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    }

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid email address")));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please agree to Terms & Conditions")));
      return;
    }

    try {
      //  Create Firebase user from controller
      final user = await _authController.register(
        email: email,
        password: password,
        phone: phone,
        name: name,
        remember: true,
        context: context,
        role: roles[selectedRole],
      );

      if (user == null) return;

      // Get Firebase token
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Signup failed: Firebase user is null")));
        return;
      }

      final idToken = await firebaseUser.getIdToken(true);

      //  call backend /auth/register to create user in DB
      final registerRes = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'role': roles[selectedRole],
        }),
      );

      print("POST /auth/register => ${registerRes.statusCode}");
      print(registerRes.body);

      if (registerRes.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Backend register failed: ${registerRes.statusCode}")),
        );
        return;
      }

      final registerData = jsonDecode(registerRes.body);
      final dbUser = registerData['user'] ?? {};

      //  call /auth/me
      final meRes = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      print("GET /auth/me => ${meRes.statusCode}");
      print(meRes.body);

      Map<String, dynamic> userData;
      if (meRes.statusCode == 200) {
        userData = jsonDecode(meRes.body);
      } else {
        // fallback to register response
        userData = dbUser is Map<String, dynamic> ? dbUser : {};
      }

      final String role = (userData['role'] ?? roles[selectedRole]).toString();
      final String userName = (userData['name'] ?? name).toString();
      final String userPhone = (userData['phone'] ?? phone).toString();
      final String userEmail = (userData['email'] ?? email).toString();
      final String? ward = userData['ward'];

      AppNavigation.pushHomeWithRole(
        context,
        role: role,
        userName: userName,
        phone: userPhone,
        email: userEmail,
        ward: ward,
      );
    } catch (e) {
      print('Signup failed: $e');
      // Errors handled by AuthController usually
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Register", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20)],
                ),
                child: Image.asset(
                  'assets/images/hamropani_logo.png',
                  height: 80,
                  width: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text("Hamro Pani", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            Center(
              child: Text("Kathmandu's Smart Water Management", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
            ),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Create Account", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold)),
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

            Text("Full Name", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Ram Bahadur",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            const SizedBox(height: 20),

            Text("Email Address", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "example@email.com",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            const SizedBox(height: 20),

            Text("Mobile Number", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "+977 98XXXXXXXX",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            const SizedBox(height: 20),

            Text("Password", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: "Enter your password",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text("Confirm Password", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: "Enter your password again",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                  activeColor: Colors.blue,
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: "I agree to the ",
                      style: GoogleFonts.poppins(color: Colors.black87),
                      children: [
                        TextSpan(text: "Terms & Conditions", style: GoogleFonts.poppins(color: Colors.blue, decoration: TextDecoration.underline)),
                        TextSpan(text: " and ", style: GoogleFonts.poppins(color: Colors.black87)),
                        TextSpan(text: "Privacy Policy", style: GoogleFonts.poppins(color: Colors.blue, decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _agreeToTerms ? _handleSignUp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text("Sign Up", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, LoginView.route),
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: GoogleFonts.poppins(color: Colors.black87),
                    children: [
                      TextSpan(text: "Log In", style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}