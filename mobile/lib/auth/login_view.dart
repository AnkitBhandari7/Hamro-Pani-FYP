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
import 'package:fyp/core/routes/routes.dart';
import 'package:fyp/features/shared/notifications/services/fcm_service.dart';
import 'package:fyp/l10n/app_localizations.dart';

import 'signup_view.dart';

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

  static const String _baseUrl = "https://hamro-pani-fyp-backend.onrender.com";

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  String? _wardNameFrom(dynamic wardRaw) {
    if (wardRaw == null) return null;
    if (wardRaw is String) return wardRaw;
    if (wardRaw is Map) return wardRaw['name']?.toString();
    return wardRaw.toString();
  }

  String _normalizeBackendRole(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'resident' || r == 'residents') return 'resident';
    if (r == 'vendor' || r == 'vendors') return 'vendor';
    if (r == 'ward_admin' || r == 'ward admin' || r == 'wardadmin') {
      return 'ward admin';
    }
    return r;
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

  String _roleLabel(AppLocalizations t, String roleKey) {
    final k = roleKey.toLowerCase().trim();
    if (k == 'resident') return t.roleResident;
    if (k == 'vendor') return t.roleVendor;
    if (k == 'ward admin' || k == 'ward_admin') return t.roleWardAdmin;
    return roleKey;
  }

  Future<void> _subscribeToTopics({
    required String role,
    String? wardName,
  }) async {
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
    } catch (_) {}
  }

  Future<void> _postFirebaseLogin({required String idToken}) async {
    final selectedRoleName = roles[selectedRole];

    final meResponse = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (meResponse.statusCode == 404) {
      await FirebaseAuth.instance.signOut();
      throw Exception("Account not found for this tab role. Please sign up first.");
    }

    if (meResponse.statusCode != 200) {
      throw Exception("Failed to load user profile (HTTP ${meResponse.statusCode})");
    }

    final userData = json.decode(meResponse.body) as Map<String, dynamic>;

    final String userRole = (userData['role'] ?? 'RESIDENT').toString();
    final String userName = (userData['name'] ?? 'User').toString();
    final String phone = (userData['phone'] ?? '').toString();
    final String userEmail = (userData['email'] ?? '').toString();

    final Object? wardRaw = userData['ward'];
    final String? wardName = _wardNameFrom(wardRaw);

    if (!_isRoleMatch(userRole, selectedRoleName)) {
      await FirebaseAuth.instance.signOut();
      throw Exception("You are registered as '$userRole'. Please select the correct role tab.");
    }

    try {
      await FCMService().saveTokenAfterLogin();
    } catch (_) {}

    await _subscribeToTopics(role: userRole, wardName: wardName);

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
    final t = AppLocalizations.of(context)!;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(t.enterEmailAndPassword);
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
        _showError(t.firebaseUserNotFound);
        setState(() => _isLoading = false);
        return;
      }

      final String? idToken = await firebaseUser.getIdToken(true);
      if (idToken == null || idToken.trim().isEmpty) {
        throw Exception(t.failedToGetIdToken);
      }

      await _postFirebaseLogin(idToken: idToken);

      setState(() => _isLoading = false);
    } catch (e) {
      _showError(e.toString().replaceFirst("Exception: ", ""));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    final t = AppLocalizations.of(context)!;

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

      await _postFirebaseLogin(idToken: idToken);

      setState(() => _isLoading = false);
    } catch (e) {
      _showError(e.toString().replaceFirst("Exception: ", ""));
      setState(() => _isLoading = false);
    }
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
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 40.h),
                    
                    // Logo Container
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
                        height: 64.w,
                        width: 64.w,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.water_drop_rounded,
                            size: 64.w,
                            color: const Color(0xFF2563EB),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 24.h),
                    
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
                        t.welcomeBack,
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
                    SizedBox(height: 32.h),
                    
                    // Inputs
                    _buildTextField(
                      controller: _emailController,
                      hint: t.emailHint,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
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
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.forgotPassword);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                        ),
                        child: Text(
                          t.forgotPasswordShort,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          disabledBackgroundColor: const Color(0xFF93C5FD),
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    t.signInArrow.replaceAll("->", "").trim(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(Icons.arrow_forward_rounded, size: 20.w),
                                ],
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
                        onPressed: _isLoading ? null : _handleGoogleLogin,
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
                    
                    // Sign Up Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t.noAccount,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, SignUpView.route),
                          child: Text(
                            t.signUpNow,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: const Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),
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
}