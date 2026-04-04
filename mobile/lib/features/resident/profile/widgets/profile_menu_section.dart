import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fyp/l10n/app_localizations.dart';

class ProfileMenuSection extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onLanguage;
  final VoidCallback onLogout;

  const ProfileMenuSection({
    super.key,
    required this.onChangePassword,
    required this.onForgotPassword,
    required this.onLanguage,
    required this.onLogout,
  });

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFFECACA)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: iconColor, size: 22.w),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: isDestructive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF334155),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 22.w,
                color: isDestructive
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.w, color: color),
          ),
          SizedBox(width: 10.w),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(t.menu, Icons.menu_rounded, const Color(0xFF7C3AED)),
        SizedBox(height: 12.h),
        _buildMenuTile(
          icon: Icons.lock_outline_rounded,
          iconColor: const Color(0xFF2563EB),
          title: t.changePassword,
          onTap: onChangePassword,
        ),
        _buildMenuTile(
          icon: Icons.help_outline_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: t.forgotPasswordTitle,
          onTap: onForgotPassword,
        ),
        _buildMenuTile(
          icon: Icons.language_rounded,
          iconColor: const Color(0xFF7C3AED),
          title: t.languagePreference,
          onTap: onLanguage,
        ),
        _buildMenuTile(
          icon: Icons.logout_rounded,
          iconColor: const Color(0xFFEF4444),
          title: t.logOut,
          onTap: onLogout,
          isDestructive: true,
        ),
      ],
    );
  }
}
