import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'ward_admin_profile_controller.dart';

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

  static const String kEditIconAsset = "assets/icons/pen.png";
  static const String kUserIconAsset = "assets/icons/user.png";

  void _showToast(BuildContext context, String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Widget _imgIcon(String asset, {double? size, Color? color}) {
    return Image.asset(
      asset,
      width: size ?? 22.w,
      height: size ?? 22.w,
      fit: BoxFit.contain,
      color: color,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_not_supported,
        size: (size ?? 22.w),
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WardAdminProfileController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 28.w),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Ward Admin Profile",
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (controller.isEditing)
            IconButton(
              tooltip: "Save",
              icon: Icon(Icons.check, color: Colors.green, size: 26.w),
              onPressed: () => controller.saveProfile(context),
            )
          else
            IconButton(
              tooltip: "Edit",
              icon: _imgIcon(kEditIconAsset, size: 22.w, color: Colors.blue),
              onPressed: controller.toggleEditMode,
            ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: controller.refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              SizedBox(height: 24.h),

              // Avatar + name + role
              Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60.r,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: controller.profileImageUrl.isNotEmpty
                            ? NetworkImage(controller.profileImageUrl)
                            : null,
                        child: controller.profileImageUrl.isEmpty
                            ? _imgIcon(kUserIconAsset, size: 60.w, color: Colors.grey)
                            : null,
                      ),

                      // camera icon (upload only in edit mode)
                      Positioned(
                        bottom: 4.h,
                        right: 4.w,
                        child: GestureDetector(
                          onTap: () {
                            if (!controller.isEditing) {
                              _showToast(
                                context,
                                "Tap Edit first to change photo",
                                color: Colors.orange,
                              );
                              return;
                            }
                            controller.pickAndUploadPhoto(context);
                          },
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.w),
                            ),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 20.w),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  controller.isEditing
                      ? SizedBox(
                    width: 240.w,
                    child: TextField(
                      controller: controller.nameController,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                      ),
                    ),
                  )
                      : Text(
                    controller.fullName.isEmpty ? "—" : controller.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.security, color: Colors.blue, size: 18.w),
                        SizedBox(width: 6.w),
                        Text(
                          "WARD ADMIN",
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    controller.wardInfo.isEmpty ? "No Ward (can post to all wards)" : controller.wardInfo,
                    style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[700]),
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              _buildSectionHeader("PERSONAL DETAILS"),
              SizedBox(height: 12.h),

              _buildEditableTile(
                icon: Icons.person_outline,
                label: "FULL NAME",
                controller: controller.nameController,
                isEditing: controller.isEditing,
              ),

              _buildEditableTile(
                icon: Icons.phone,
                label: "PHONE NUMBER",
                controller: controller.phoneController,
                isEditing: controller.isEditing,
              ),

              _buildEditableTile(
                icon: Icons.email_outlined,
                label: "EMAIL ADDRESS",
                controller: controller.emailController,
                isEditing: false, // email not editable
              ),

              SizedBox(height: 24.h),

              _buildSectionHeader("SETTINGS & PREFERENCES"),
              SizedBox(height: 12.h),

              _buildSettingsTile(
                icon: Icons.settings,
                title: "App Settings",
                onTap: controller.onAppSettings,
              ),
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                title: "Notification Preferences",
                onTap: () => _showToast(context, "Not implemented", color: Colors.orange),
              ),
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: "Help & Support",
                onTap: () => _showToast(context, "Not implemented", color: Colors.orange),
              ),
              _buildSettingsTile(
                icon: Icons.logout,
                title: "Log Out",
                color: Colors.red,
                onTap: () => controller.onLogout(context),
              ),

              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _tileBase({
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.blue, size: 24.w),
          ),
          SizedBox(width: 16.w),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildEditableTile({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
  }) {
    return _tileBase(
      icon: icon,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          isEditing
              ? TextField(
            controller: controller,
            style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
          )
              : Text(
            controller.text.isEmpty ? "—" : controller.text,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Color? color,
    VoidCallback? onTap,
  }) {
    final c = color ?? Colors.blue;
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: c, size: 24.w),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 28.w),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    );
  }
}