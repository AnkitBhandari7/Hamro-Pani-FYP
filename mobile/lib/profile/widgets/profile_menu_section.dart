import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fyp/l10n/app_localizations.dart';

class ProfileMenuSection extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onLanguage;
  final VoidCallback onLogout;

  const ProfileMenuSection({
    super.key,
    required this.onChangePassword,
    required this.onLanguage,
    required this.onLogout,
  });

  Widget _tile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menu,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _tile(
                icon: Icons.lock_outline,
                iconBg: Colors.blue.withOpacity(0.12),
                iconColor: Colors.blue,
                title: t.changePassword,
                onTap: onChangePassword,
              ),
              const Divider(height: 1),
              _tile(
                icon: Icons.language,
                iconBg: Colors.blue.withOpacity(0.12),
                iconColor: Colors.blue,
                title: t.languagePreference,
                onTap: onLanguage,
              ),
              const Divider(height: 1),
              _tile(
                icon: Icons.logout,
                iconBg: Colors.red.withOpacity(0.12),
                iconColor: Colors.red,
                title: t.logOut,
                onTap: onLogout,
                textColor: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }
}