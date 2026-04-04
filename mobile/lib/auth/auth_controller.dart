import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fyp/auth/auth_service.dart';
import 'package:fyp/core/models/auth_user.dart';
import 'package:fyp/core/localization/locale_controller.dart';
import 'package:fyp/l10n/app_localizations.dart';
import 'package:fyp/services/api_service.dart';

class AuthController {
  final AuthService _service;
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  AuthController(this._service);

  Future<void> _syncLocaleFromBackend(BuildContext context) async {
    try {
      final res = await ApiService.get('/profile/me');
      if (res.statusCode != 200) return;

      final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
      if (decoded is! Map) return;

      final m = Map<String, dynamic>.from(decoded);

      final dynamic raw = m['language'] ??
          m['lang'] ??
          m['preferredLanguage'] ??
          m['locale'] ??
          (m['user'] is Map ? (m['user'] as Map)['language'] : null);

      final code = raw?.toString();

      await Provider.of<LocaleController>(context, listen: false)
          .setFromBackendCode(code);
    } catch (_) {
      // non-fatal
    }
  }

  // Email / Password
  Future<AuthUser?> login({
    required String email,
    required String password,
    required bool remember,
    required BuildContext context,
  }) async {
    final t = AppLocalizations.of(context)!;

    isLoading.value = true;
    try {
      final user = await _service.loginWithEmail(
        email: email.trim(),
        password: password,
        remember: remember,
      );

      if (user != null) {
        await _syncLocaleFromBackend(context);
      }

      _toast(context, t.loginSuccess, isError: false);
      return user;
    } on Exception catch (e) {
      _toast(context, t.loginFailedWithError(e.toString()), isError: true);
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
    final t = AppLocalizations.of(context)!;

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

      if (user != null) {
        await _syncLocaleFromBackend(context);
      }

      _toast(context, t.accountCreatedSuccess, isError: false);
      return user;
    } on Exception catch (e) {
      _toast(context, t.signupFailedWithError(e.toString()), isError: true);
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
    final t = AppLocalizations.of(context)!;

    isLoading.value = true;
    try {
      final user = await _service.signInWithGoogle(remember: remember);

      if (user != null) {
        await _syncLocaleFromBackend(context);
        _toast(context, t.googleLoginSuccess, isError: false);
        return user;
      }

      // user cancelled selection
      _toast(context, t.loginCancelled, isError: true);
      return null;
    } on Exception catch (e) {
      _toast(context, t.googleLoginFailedWithError(e.toString()), isError: true);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email, BuildContext context) async {
    final t = AppLocalizations.of(context)!;

    if (email.isEmpty) {
      _toast(context, t.enterEmailToReset, isError: true);
      return;
    }

    try {
      await _service.sendPasswordReset(email.trim());
      _toast(context, t.passwordResetEmailSent, isError: false);
    } catch (e) {
      _toast(context, t.failedToSendResetEmail, isError: true);
    }
  }

  void dispose() => isLoading.dispose();

  void _toast(BuildContext ctx, String msg, {required bool isError}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}