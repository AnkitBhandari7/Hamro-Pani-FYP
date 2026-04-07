import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/ward_admin_profile_controller.dart';
import 'package:fyp/l10n/app_localizations.dart';
import 'package:fyp/core/routes/routes.dart';

class WardAdminProfileScreen extends StatelessWidget {
  const WardAdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WardAdminProfileController(),
      child: const _WardAdminProfileContent(),
    );
  }
}

class _WardAdminProfileContent extends StatelessWidget {
  const _WardAdminProfileContent();

  static const String kUserIconAsset = "assets/icons/user.png";

  void _showToast(BuildContext context, String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _imgIcon(String asset, {double? size, Color? color}) {
    return Image.asset(
      asset,
      width: size ?? 22.w,
      height: size ?? 22.w,
      fit: BoxFit.contain,
      color: color,
      errorBuilder: (c1, e1, s1) => Icon(
        Icons.person_rounded,
        size: (size ?? 22.w),
        color: const Color(0xFF94A3B8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WardAdminProfileController>();
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: const Color(0xFF0F172A), size: 20.w),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.wardAdminProfile,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          if (controller.isEditing)
            GestureDetector(
              onTap: () => controller.saveProfile(context),
              child: Container(
                margin: EdgeInsets.only(right: 12.w),
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded,
                        size: 18.w, color: Colors.white),
                    SizedBox(width: 4.w),
                    Text(
                      t.save,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: controller.toggleEditMode,
              child: Container(
                margin: EdgeInsets.only(right: 12.w),
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded,
                        size: 16.w, color: const Color(0xFF2563EB)),
                    SizedBox(width: 4.w),
                    Text(
                      t.edit,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: controller.refreshProfile,
              color: const Color(0xFF2563EB),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),

                    // ─── Profile Card ───────────────
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22.r),
                        border:
                            Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 3.w,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 54.r,
                                  backgroundColor:
                                      const Color(0xFFF1F5F9),
                                  backgroundImage: controller
                                          .profileImageUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          controller.profileImageUrl)
                                      : null,
                                  child:
                                      controller.profileImageUrl.isEmpty
                                          ? _imgIcon(kUserIconAsset,
                                              size: 54.w,
                                              color: const Color(
                                                  0xFF94A3B8))
                                          : null,
                                ),
                              ),
                              Positioned(
                                bottom: 2.h,
                                right: 2.w,
                                child: GestureDetector(
                                  onTap: () {
                                    if (!controller.isEditing) {
                                      _showToast(
                                        context,
                                        t.tapEditFirstToChangePhoto,
                                        color: const Color(0xFFF97316),
                                      );
                                      return;
                                    }
                                    controller
                                        .pickAndUploadPhoto(context);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: controller.isEditing
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF94A3B8),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white,
                                          width: 2.5.w),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                              alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 16.w),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Name (editable)
                          controller.isEditing
                              ? Container(
                                  width: 240.w,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(12.r),
                                    border: Border.all(
                                        color:
                                            const Color(0xFF2563EB)),
                                  ),
                                  child: TextField(
                                    controller:
                                        controller.nameController,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 8.h),
                                    ),
                                  ),
                                )
                              : Text(
                                  controller.fullName.isEmpty
                                      ? "—"
                                      : controller.fullName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                          SizedBox(height: 10.h),

                          // Role badge
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                  color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_rounded,
                                    color: const Color(0xFF2563EB),
                                    size: 16.w),
                                SizedBox(width: 6.w),
                                Text(
                                  t.wardAdminUpper,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.h),

                          // Ward info
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_city_rounded,
                                  size: 14.w,
                                  color: const Color(0xFF94A3B8)),
                              SizedBox(width: 4.w),
                              Text(
                                controller.wardInfo.isEmpty
                                    ? t.noWardCanPostAll
                                    : controller.wardInfo,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // ─── Personal Details ────────────
                    _sectionHeader(
                        t.personalDetailsUpper, Icons.person_outlined,
                        const Color(0xFF2563EB)),
                    SizedBox(height: 10.h),

                    _buildDetailCard(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF2563EB),
                      label: t.fullName.toUpperCase(),
                      editController: controller.nameController,
                      isEditing: controller.isEditing,
                    ),
                    SizedBox(height: 10.h),
                    _buildDetailCard(
                      icon: Icons.phone_rounded,
                      iconColor: const Color(0xFF16A34A),
                      label: t.phoneNumber.toUpperCase(),
                      editController: controller.phoneController,
                      isEditing: controller.isEditing,
                    ),
                    SizedBox(height: 10.h),
                    _buildDetailCard(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFFF97316),
                      label: t.emailAddressUpper,
                      editController: controller.emailController,
                      isEditing: false,
                    ),

                    SizedBox(height: 28.h),

                    // ─── Menu ────────────────────────
                    _sectionHeader(
                        t.menu, Icons.menu_rounded, const Color(0xFF7C3AED)),
                    SizedBox(height: 10.h),

                    _buildMenuTile(
                      icon: Icons.lock_outline_rounded,
                      title: t.changePassword,
                      iconColor: const Color(0xFF2563EB),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.changePassword),
                    ),
                    SizedBox(height: 10.h),
                    _buildMenuTile(
                      icon: Icons.help_outline_rounded,
                      title: t.forgotPasswordTitle,
                      iconColor: const Color(0xFFF59E0B),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.forgotPassword),
                    ),
                    SizedBox(height: 10.h),
                    _buildMenuTile(
                      icon: Icons.language_rounded,
                      title: t.languagePreference,
                      iconColor: const Color(0xFF7C3AED),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.languagePreference),
                    ),
                    SizedBox(height: 10.h),
                    _buildMenuTile(
                      icon: Icons.logout_rounded,
                      title: t.logOut,
                      iconColor: const Color(0xFFEF4444),
                      isDestructive: true,
                      onTap: () => controller.onLogout(context),
                    ),

                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Section Header ─────────────────────
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

  // ─── Detail Card ────────────────────────
  Widget _buildDetailCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required TextEditingController editController,
    required bool isEditing,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                isEditing
                    ? TextField(
                        controller: editController,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 10.h),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(
                                color: Color(0xFF2563EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(
                                color: Color(0xFF2563EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(
                                color: Color(0xFF2563EB), width: 1.5),
                          ),
                        ),
                      )
                    : Text(
                        editController.text.isEmpty
                            ? "—"
                            : editController.text,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Menu Tile ──────────────────────────
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
}
