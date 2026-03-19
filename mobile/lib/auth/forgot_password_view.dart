import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fyp/auth/auth_controller.dart';
import 'package:fyp/auth/auth_service.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  bool _loading = false;

  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();

    setState(() => _loading = true);
    try {
      await _authController.forgotPassword(email, context);

      // After sending reset email, go back to Login screen
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Forgot Password", style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Reset your password",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your email and we will send a reset link to your email.",
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "name@example.com",
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Send Reset Link",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}