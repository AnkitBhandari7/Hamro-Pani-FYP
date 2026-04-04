import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:fyp/auth/auth_controller.dart';
import 'package:fyp/auth/auth_service.dart';
import 'package:fyp/core/localization/locale_controller.dart';
import 'package:fyp/core/routes/app_navigation.dart';
import 'package:fyp/l10n/app_localizations.dart';

import 'login_view.dart';

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
  bool _isLoading = false;

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
    _authController.dispose();
    super.dispose();
  }

  String _roleLabel(AppLocalizations t, String roleKey) {
    final k = roleKey.toLowerCase().trim();
    if (k == 'resident') return t.roleResident;
    if (k == 'vendor') return t.roleVendor;
    if (k == 'ward admin' || k == 'ward_admin') return t.roleWardAdmin;
    return roleKey;
  }

  String _selectedRoleToBackendRole(String selected) {
    final s = selected.toLowerCase().trim();
    if (s == "resident") return "RESIDENT";
    if (s == "vendor") return "VENDOR";
    if (s == "ward admin") return "WARD_ADMIN";
    return "RESIDENT";
  }

  String? wardNameFrom(dynamic wardRaw) {
    if (wardRaw == null) return null;
    if (wardRaw is String) return wardRaw;
    if (wardRaw is Map) return wardRaw['name']?.toString();
    return wardRaw.toString();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Widget _languageButton(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localeCtrl = Provider.of<LocaleController>(context, listen: false);
    final currentCode = Localizations.localeOf(context).languageCode;

    return GestureDetector(
      onTap: () async {
        if (currentCode == 'ne') {
          await localeCtrl.setEnglish();
        } else {
          await localeCtrl.setNepali();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 16.w, color: const Color(0xFF64748B)),
            SizedBox(width: 6.w),
            Text(
              currentCode == 'ne' ? t.langEnglishShort : t.langNepaliShort,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final t = AppLocalizations.of(context)!;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showError(t.fillAllFields);
      return;
    }

    if (!_isValidEmail(email)) {
      _showError(t.invalidEmailAddress);
      return;
    }

    if (password != confirmPassword) {
      _showError(t.passwordsDoNotMatchMsg);
      return;
    }

    if (!_agreeToTerms) {
      _showError(t.agreeToTermsRequired);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authController.register(
        email: email,
        password: password,
        phone: phone,
        name: name,
        remember: true,
        context: context,
        role: roles[selectedRole],
      );

      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (!mounted) return;
        _showError(t.signupFailedFirebaseNull);
        setState(() => _isLoading = false);
        return;
      }

      final String? idToken = await firebaseUser.getIdToken(true);
      if (idToken == null || idToken.trim().isEmpty) {
        if (!mounted) return;
        _showError(t.signupFailedTokenNull);
        setState(() => _isLoading = false);
        return;
      }

      final selectedRoleName = roles[selectedRole];
      final backendRole = _selectedRoleToBackendRole(selectedRoleName);

      final registerRes = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'password': password,
          'role': backendRole,
        }),
      );

      if (registerRes.statusCode != 200) {
        if (!mounted) return;
        _showError(t.backendRegisterFailed(registerRes.statusCode));
        setState(() => _isLoading = false);
        return;
      }

      final registerData = jsonDecode(registerRes.body) as Map<String, dynamic>;
      final dbUser = (registerData['user'] is Map<String, dynamic>)
          ? (registerData['user'] as Map<String, dynamic>)
          : <String, dynamic>{};

      final meRes = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      Map<String, dynamic> userData;
      if (meRes.statusCode == 200) {
        userData = jsonDecode(meRes.body) as Map<String, dynamic>;
      } else {
        userData = dbUser;
      }

      final String role = (userData['role'] ?? backendRole).toString();
      final String userName = (userData['name'] ?? name).toString();
      final String userPhone = (userData['phone'] ?? phone).toString();
      final String userEmail = (userData['email'] ?? email).toString();

      final dynamic wardRaw = userData['ward'];
      final String? wardName = wardNameFrom(wardRaw);

      if (!mounted) return;
      setState(() => _isLoading = false);

      AppNavigation.pushHomeWithRole(
        context,
        role: role,
        userName: userName,
        phone: userPhone,
        email: userEmail,
        ward: wardRaw ?? wardName,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(t.signupFailedWithError(e.toString()));
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        fontSize: 15.sp,
        color: const Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: const Color(0xFF94A3B8),
        ),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20.w),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: const Color(0xFF94A3B8),
                  size: 20.w,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: const Color(0xFF0F172A), size: 20.w),
          onPressed: () => Navigator.pop(context),
          tooltip: t.back,
        ),
        title: Text(
          t.signupTitle,
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/hamropani_logo.png',
                        height: 56.w,
                        width: 56.w,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.water_drop_rounded,
                          size: 56.w,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    
                    Text(
                      t.appName,
                      style: GoogleFonts.poppins(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      t.appTagline,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40.h),
                    
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t.createAccount,
                        style: GoogleFonts.poppins(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Role Tabs
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: Row(
                        children: roles.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final roleKey = entry.value;
                          final isSelected = selectedRole == idx;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedRole = idx),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30.r),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  _roleLabel(t, roleKey),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 30.h),

                    // Inputs
                    _buildTextField(
                      controller: _nameController,
                      hint: t.fullNameHint,
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.name,
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildTextField(
                      controller: _emailController,
                      hint: t.emailHint,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildTextField(
                      controller: _phoneController,
                      hint: t.phoneHint,
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildTextField(
                      controller: _passwordController,
                      hint: t.passwordHint,
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscure: _obscurePassword,
                      onToggleObscure: () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: t.confirmPasswordHint,
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscure: _obscureConfirmPassword,
                      onToggleObscure: () => setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      }),
                    ),
                    SizedBox(height: 24.h),

                    Row(
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                          activeColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showTermsDialog,
                            child: Text(
                              t.agreeToTermsText,
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                color: const Color(0xFF2563EB),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),

                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: _agreeToTerms && !_isLoading ? _handleSignUp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          disabledBackgroundColor: const Color(0xFF94A3B8),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24.w,
                                width: 24.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                t.signupButton,
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Or Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            t.orContinueWith,
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    
                    // Google Button
                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignUp,
                        icon: Image.asset(
                          'assets/images/google_logo.webp',
                          height: 22.w,
                        ),
                        label: Text(
                          t.google,
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    SizedBox(height: 48.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t.haveAccount,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, LoginView.route),
                          child: Text(
                            t.loginNow,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: const Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 48.h),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16.h,
              right: 20.w,
              child: _languageButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignUp() async {
    final t = AppLocalizations.of(context)!;

    if (!_agreeToTerms) {
      _showError(t.agreeToTermsRequired);
      return;
    }

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
        _showError(t.firebaseUserNotFound);
        setState(() => _isLoading = false);
        return;
      }

      final String? idToken = await firebaseUser.getIdToken(true);
      if (idToken == null || idToken.trim().isEmpty) {
        throw Exception(t.failedToGetIdToken);
      }

      final selectedRoleName = roles[selectedRole];
      final backendRole = _selectedRoleToBackendRole(selectedRoleName);

      http.Response meResponse = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (meResponse.statusCode == 200) {
        await FirebaseAuth.instance.signOut();
        throw Exception("You already have an account. Please login from the Login screen.");
      }

      final registerRes = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': backendRole}),
      );

      if (registerRes.statusCode != 200) {
        throw Exception("Failed to register. Target Role: $backendRole");
      }

      meResponse = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      
      final userData = jsonDecode(meResponse.body) as Map<String, dynamic>;
      final String role = (userData['role'] ?? backendRole).toString();
      final String userName = (userData['name'] ?? firebaseUser.displayName ?? 'User').toString();
      final String userPhone = (userData['phone'] ?? '').toString();
      final String userEmail = (userData['email'] ?? firebaseUser.email ?? '').toString();

      final dynamic wardRaw = userData['ward'];
      final String? wardName = wardNameFrom(wardRaw);

      if (!mounted) return;
      setState(() => _isLoading = false);

      AppNavigation.pushHomeWithRole(
        context,
        role: role,
        userName: userName,
        phone: userPhone,
        email: userEmail,
        ward: wardRaw ?? wardName,
      );
    } catch (e) {
      _showError(e.toString().replaceFirst("Exception: ", ""));
      setState(() => _isLoading = false);
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          "Terms & Conditions",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, 
            color: const Color(0xFF0F172A),
            fontSize: 20.sp
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            "Welcome to Hamro Pani!\n\n"
            "By registering for an account, you agree to the following terms:\n\n"
            "1. You will provide accurate and truthful information during registration.\n"
            "2. You will not misuse the app to spam or falsely report vendors or administrators.\n"
            "3. Hamro Pani is a facilitation platform. It is not directly responsible for monetary disputes between residents and vendors.\n"
            "4. Your privacy is important to us. Your data will only be used to facilitate water delivery services in your specific ward, and anonymized for analytics.\n\n"
            "Please use the application responsibly.",
            style: GoogleFonts.poppins(
              fontSize: 14.sp, 
              color: const Color(0xFF475569), 
              height: 1.6
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Close", 
              style: GoogleFonts.poppins(
                color: const Color(0xFF2563EB), 
                fontWeight: FontWeight.w600,
                fontSize: 15.sp
              )
            ),
          ),
        ],
      ),
    );
  }
}