import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fyp/l10n/app_localizations.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _ob1 = true, _ob2 = true, _ob3 = true;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _isEmailPasswordUser(User user) {
    return user.providerData.any((p) => p.providerId == 'password');
  }

  Future<void> _changePassword() async {
    final t = AppLocalizations.of(context)!;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack("Not logged in", isError: true);
      return;
    }

    if (!_isEmailPasswordUser(user)) {
      _snack(
        "Password change is only available for Email/Password accounts.",
        isError: true,
      );
      return;
    }

    final current = _current.text;
    final np = _newPass.text;
    final cp = _confirm.text;

    if (current.isEmpty || np.isEmpty || cp.isEmpty) {
      _snack("Fill all fields", isError: true);
      return;
    }
    if (np.length < 6) {
      _snack("New password must be at least 6 characters", isError: true);
      return;
    }
    if (np != cp) {
      _snack("New password and confirm password do not match", isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final email = user.email;
      if (email == null || email.isEmpty) {
        _snack("Email not found for this account", isError: true);
        return;
      }

      // Re-authenticate with current password
      final cred = EmailAuthProvider.credential(
        email: email,
        password: current,
      );
      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(np);

      if (!mounted) return;
      _snack("Password updated successfully!", isError: false);
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? "Failed to change password", isError: true);
    } catch (e) {
      _snack("Failed to change password: $e", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _dec(String hint, bool obscure, VoidCallback toggle) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(t.changePassword, style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _current,
                obscureText: _ob1,
                decoration: _dec(
                  t.currentPassword,
                  _ob1,
                  () => setState(() => _ob1 = !_ob1),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPass,
                obscureText: _ob2,
                decoration: _dec(
                  t.newPassword,
                  _ob2,
                  () => setState(() => _ob2 = !_ob2),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirm,
                obscureText: _ob3,
                decoration: _dec(
                  t.confirmPassword,
                  _ob3,
                  () => setState(() => _ob3 = !_ob3),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          t.updatePassword,
                          style: GoogleFonts.poppins(
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
