import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as pv;

import 'package:fyp/core/localization/locale_controller.dart';
import 'package:fyp/l10n/app_localizations.dart';

class LanguagePreferenceView extends StatefulWidget {
  const LanguagePreferenceView({super.key});

  @override
  State<LanguagePreferenceView> createState() => _LanguagePreferenceViewState();
}

class _LanguagePreferenceViewState extends State<LanguagePreferenceView> {
  static const String _baseUrl = "http://10.0.2.2:3000";

  String _selected = "EN";
  bool _loading = false;
  bool _loadingInitial = true;

  Future<String?> _token() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return null;
    return await u.getIdToken(true);
  }

  Future<void> _loadCurrentLanguage() async {
    setState(() => _loadingInitial = true);
    try {
      final tkn = await _token();
      if (tkn == null) return;

      final res = await http.get(
        Uri.parse("$_baseUrl/profile/me"),
        headers: {'Authorization': 'Bearer $tkn'},
      );

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final user = (data['user'] ?? {}) as Map<String, dynamic>;
      final lang = (user['language'] ?? 'EN').toString().toUpperCase();

      if (!mounted) return;
      setState(() => _selected = (lang == "NP" || lang == "NE") ? "NP" : "EN");
    } catch (_) {

    } finally {
      if (mounted) setState(() => _loadingInitial = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final tkn = await _token();
      if (tkn == null) throw Exception("Not authenticated");

      final res = await http.patch(
        Uri.parse("$_baseUrl/auth/update-profile"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tkn',
        },
        body: jsonEncode({'language': _selected}),
      );

      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }

      if (!mounted) return;

      // apply locale instantly
      final localeCtrl = context.read<LocaleController>();
      if (_selected == "EN") localeCtrl.setEnglish();
      if (_selected == "NP") localeCtrl.setNepali();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.saveLanguage),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _radio(String code, String label) {
    return RadioListTile<String>(
      value: code,
      groupValue: _selected,
      onChanged: (v) => setState(() => _selected = v ?? "EN"),
      title: Text(label, style: GoogleFonts.poppins()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(t.languagePreference, style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loadingInitial
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            _radio("EN", t.english),
            _radio("NP", t.nepali),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    t.saveLanguage,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}