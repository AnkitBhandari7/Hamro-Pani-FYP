import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/vendor_profile_controller.dart';
import 'package:fyp/l10n/app_localizations.dart';

import 'package:fyp/core/routes/routes.dart';

class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VendorProfileController(),
      child: const _VendorProfileContent(),
    );
  }
}

class _VendorProfileContent extends StatelessWidget {
  const _VendorProfileContent();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<VendorProfileController>();
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: const Color(0xFF0F172A), size: 22.w),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.vendorProfile,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          if (c.isEditing)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () => c.save(context),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    t.save,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: c.onEditProfile,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
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
            ),
        ],
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  SizedBox(height: 24.h),

                  // Profile card section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
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
                                    width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 52.r,
                                backgroundColor: const Color(0xFFEFF6FF),
                                backgroundImage: c.logoUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(c.logoUrl)
                                    : null,
                                child: c.logoUrl.isEmpty
                                    ? Icon(Icons.local_shipping_rounded,
                                        size: 48.w,
                                        color: const Color(0xFF2563EB))
                                    : null,
                              ),
                            ),
                            // Camera button
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: GestureDetector(
                                onTap: c.photoBusy
                                    ? null
                                    : () {
                                        if (!c.isEditing) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(t
                                                    .tapEditFirstToChangePhoto)),
                                          );
                                          return;
                                        }
                                        c.pickAndUploadPhoto(context);
                                      },
                                child: Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2.5),
                                  ),
                                  child: c.photoBusy
                                      ? SizedBox(
                                          width: 16.w,
                                          height: 16.w,
                                          child:
                                              const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(Icons.camera_alt_rounded,
                                          size: 16.w, color: Colors.white),
                                ),
                              ),
                            ),
                            // Delete button
                            if (c.logoUrl.isNotEmpty && c.isEditing)
                              Positioned(
                                left: 4,
                                bottom: 4,
                                child: GestureDetector(
                                  onTap: c.photoBusy
                                      ? null
                                      : () => c.deletePhoto(context),
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2.5),
                                    ),
                                    child: Icon(Icons.delete_rounded,
                                        size: 16.w, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: 16.h),

                        // Company Name
                        c.isEditing
                            ? TextField(
                                controller: c.companyNameController,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  hintText: t.companyNameHint,
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF2563EB)),
                                  ),
                                ),
                              )
                            : Text(
                                c.companyName.isEmpty
                                    ? "—"
                                    : c.companyName,
                                style: GoogleFonts.poppins(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                                textAlign: TextAlign.center,
                              ),

                        SizedBox(height: 6.h),

                        // Contact Name
                        c.isEditing
                            ? Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 40.w),
                                child: TextField(
                                  controller: c.contactNameController,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14.sp),
                                  decoration: InputDecoration(
                                    hintText: t.fullNameContactPersonHint,
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                c.contactName.isEmpty
                                    ? "—"
                                    : c.contactName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),

                        SizedBox(height: 12.h),

                        // Verified badge + location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                    color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded,
                                      size: 14.w,
                                      color: const Color(0xFF16A34A)),
                                  SizedBox(width: 4.w),
                                  Text(
                                    t.verifiedVendor,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF16A34A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(Icons.location_on_outlined,
                                size: 14.w,
                                color: const Color(0xFF94A3B8)),
                            SizedBox(width: 2.w),
                            Flexible(
                              child: Text(
                                c.location.trim().isEmpty
                                    ? t.noAddress
                                    : c.location,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20.h),

                        // Stat cards
                        Row(
                          children: [
                            Expanded(
                              child: _modernStatCard(
                                value: c.deliveries,
                                label: t.deliveries.toUpperCase(),
                                color: const Color(0xFF16A34A),
                                bgColor: const Color(0xFFF0FDF4),
                                borderColor: const Color(0xFFBBF7D0),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _modernStatCard(
                                value: c.tankers,
                                label: t.tankers.toUpperCase(),
                                color: const Color(0xFF2563EB),
                                bgColor: const Color(0xFFEFF6FF),
                                borderColor: const Color(0xFFBFDBFE),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Business Details section
                  _sectionHeader(t.businessDetails),
                  SizedBox(height: 12.h),

                  _editableTile(
                    icon: Icons.email_rounded,
                    iconColor: const Color(0xFFF97316),
                    label: t.emailLabel,
                    controller: TextEditingController(text: c.email),
                    value: c.email,
                    enabled: false,
                  ),

                  _editableTile(
                    icon: Icons.phone_rounded,
                    iconColor: const Color(0xFF2563EB),
                    label: t.phoneNumber,
                    controller: c.phoneController,
                    value: c.phone,
                    enabled: c.isEditing,
                  ),

                  _editableTile(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF16A34A),
                    label: t.addressLabel,
                    controller: c.addressController,
                    value: c.address,
                    enabled: c.isEditing,
                  ),

                  _editableTile(
                    icon: Icons.local_shipping_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    label: t.tankers,
                    controller: c.tankerCountController,
                    value: c.tankers,
                    enabled: c.isEditing,
                    keyboardType: TextInputType.number,
                  ),

                  _detailTile(
                    icon: Icons.badge_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    label: t.vendorId,
                    value: c.vendorId,
                  ),

                  SizedBox(height: 28.h),

                  // Menu section
                  _sectionHeader(t.menu),
                  SizedBox(height: 12.h),

                  _menuTile(
                    icon: Icons.lock_outline_rounded,
                    title: t.changePassword,
                    iconColor: const Color(0xFF2563EB),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.changePassword),
                  ),
                  _menuTile(
                    icon: Icons.help_outline_rounded,
                    title: t.forgotPasswordTitle,
                    iconColor: const Color(0xFFF59E0B),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  ),
                  _menuTile(
                    icon: Icons.language_rounded,
                    title: t.languagePreference,
                    iconColor: const Color(0xFF16A34A),
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.languagePreference),
                  ),
                  SizedBox(height: 8.h),
                  _menuTile(
                    icon: Icons.logout_rounded,
                    title: t.logOut,
                    iconColor: const Color(0xFFEF4444),
                    titleColor: const Color(0xFFEF4444),
                    showDivider: false,
                    onTap: () => c.onLogout(context),
                  ),

                  SizedBox(height: 60.h),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _modernStatCard({
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    fontSize: 12.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
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

  Widget _editableTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required TextEditingController controller,
    required String value,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    fontSize: 12.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(height: 4.h),
                enabled
                    ? TextField(
                        controller: controller,
                        keyboardType: keyboardType,
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
                                color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(
                                color: Color(0xFF2563EB)),
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
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

  Widget _menuTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    Color? titleColor,
    bool showDivider = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        margin: EdgeInsets.only(bottom: showDivider ? 2.h : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  color: titleColor ?? const Color(0xFF334155),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 22.w, color: const Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}