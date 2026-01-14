import 'package:flutter/material.dart';
import 'package:fyp/auth/auth_service.dart';
import '../models/auth_user.dart';

class AuthController {
  final AuthService _service;
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  AuthController(this._service);


  // Email / Password

  Future<AuthUser?> login({
    required String email,
    required String password,
    required bool remember,
    required BuildContext context,
  }) async {
    isLoading.value = true;
    try {
      final user = await _service.loginWithEmail(
        email: email.trim(),
        password: password,
        remember: remember,
      );
      _toast(context, 'Logged in successfully');
      return user;
    } on Exception catch (e) {
      _toast(context, 'Login failed: ${e.toString()}');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<AuthUser?> register({
    required String email,
    required String password,
    required String phone,
    String? name,
    required bool remember,
    required BuildContext context,
    required String role,
  }) async {
    isLoading.value = true;
    try {
      final user = await _service.registerWithEmail(
        email: email.trim(),
        password: password,
        phone: phone.trim(),
        name: name?.trim(),
        remember: remember,
        role: role,
      );
      _toast(context, 'Account created successfully');
      return user;
    } on Exception catch (e) {
      _toast(context, 'Signup failed: ${e.toString()}');
      return null;
    } finally {
      isLoading.value = false;
    }
  }


  // Google Sign-In

  Future<AuthUser?> googleLogin({
    required bool remember,
    required BuildContext context,
  }) async {
    isLoading.value = true;
    try {
      final user = await _service.signInWithGoogle(remember: remember);
      if (user != null) {
        _toast(context, 'Logged in with Google');
        return user;
      }
      return null;
    } on Exception catch (e) {
      _toast(context, 'Google login failed: ${e.toString()}');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email, BuildContext context) async {
    if (email.isEmpty) {
      _toast(context, 'Enter your email to reset password');
      return;
    }
    try {
      await _service.sendPasswordReset(email.trim());
      _toast(context, 'Password reset email sent');
    } catch (e) {
      _toast(context, 'Failed to send reset email');
    }
  }

  void dispose() => isLoading.dispose();

  void _toast(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: msg.contains('failed') || msg.contains('Enter')
            ? Colors.red
            : Colors.green,
      ),
    );
  }
}