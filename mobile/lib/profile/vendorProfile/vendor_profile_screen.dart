import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'vendor_profile_controller.dart';

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
          'Vendor Profile',
          style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (c.isEditing)
            IconButton(
              icon: Icon(Icons.check, color: Colors.green, size: 26.w),
              onPressed: () => c.save(context),
              tooltip: "Save",
            )
          else
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue, size: 24.w),
              onPressed: c.onEditProfile,
              tooltip: "Edit",
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

            // Photo
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60.r,
                  backgroundColor: Colors.blue[50],
                  backgroundImage: c.logoUrl.isNotEmpty ? NetworkImage(c.logoUrl) : null,
                  child: c.logoUrl.isEmpty
                      ? Icon(Icons.local_shipping, size: 60.w, color: Colors.blue)
                      : null,
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: InkWell(
                    onTap: c.photoBusy
                        ? null
                        : () {
                      if (!c.isEditing) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Tap Edit first to change photo")),
                        );
                        return;
                      }
                      c.pickAndUploadPhoto(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.w),
                      ),
                      child: c.photoBusy
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : Icon(Icons.camera_alt, size: 18.w, color: Colors.white),
                    ),
                  ),
                ),
                if (c.logoUrl.isNotEmpty)
                  Positioned(
                    left: 2,
                    bottom: 2,
                    child: InkWell(
                      onTap: c.photoBusy || !c.isEditing ? null : () => c.deletePhoto(context),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.w),
                        ),
                        child: Icon(Icons.delete, size: 18.w, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 16.h),

            // ✅ Company Name (big)
            c.isEditing
                ? TextField(
              controller: c.companyNameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Company Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            )
                : Text(
              c.companyName.isEmpty ? "—" : c.companyName,
              style: GoogleFonts.poppins(fontSize: 22.sp, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 10.h),

            // ✅ Contact Name (person name from users table)
            c.isEditing
                ? TextField(
              controller: c.contactNameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Full Name (Contact Person)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            )
                : Text(
              c.contactName.isEmpty ? "—" : c.contactName,
              style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 10.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Text(
                    'Verified Vendor',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.green[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    '• ${c.location}',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard('DELIVERIES', c.deliveries, Colors.green),
                _statCard('TANKERS', c.tankers, Colors.blue),
              ],
            ),

            SizedBox(height: 32.h),

            _header('Business Details'),
            SizedBox(height: 12.h),

            _editableTile(
              icon: Icons.email,
              label: 'Email',
              controller: TextEditingController(text: c.email),
              value: c.email,
              enabled: false, // Student note: email not editable
            ),

            _editableTile(
              icon: Icons.phone,
              label: 'Phone',
              controller: c.phoneController,
              value: c.phone,
              enabled: c.isEditing,
            ),

            _editableTile(
              icon: Icons.location_on,
              label: 'Address',
              controller: c.addressController,
              value: c.address,
              enabled: c.isEditing,
            ),

            _editableTile(
              icon: Icons.local_shipping,
              label: 'Tankers',
              controller: c.tankerCountController,
              value: c.tankers,
              enabled: c.isEditing,
              keyboardType: TextInputType.number,
            ),

            _detailTile(
              icon: Icons.badge,
              label: 'Vendor ID',
              value: c.vendorId,
            ),

            SizedBox(height: 32.h),

            _header('Menu'),
            SizedBox(height: 12.h),

            _menuTile(icon: Icons.settings, title: 'Payment Settings', onTap: () {}),
            _menuTile(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
            _menuTile(
              icon: Icons.logout,
              title: 'Log Out',
              color: Colors.red,
              onTap: () => c.onLogout(context),
            ),

            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }

  Widget _header(String t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(t, style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600)),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.w700, color: color)),
          SizedBox(height: 4.h),
          Text(label, style: GoogleFonts.poppins(fontSize: 12.sp, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _detailTile({required IconData icon, required String label, required String value}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2.h))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12.r)),
            child: Icon(icon, color: Colors.blue, size: 24.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600])),
                SizedBox(height: 4.h),
                Text(value, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableTile({
    required IconData icon,
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2.h))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12.r)),
            child: Icon(icon, color: Colors.blue, size: 24.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600])),
                SizedBox(height: 6.h),
                enabled
                    ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                  ),
                )
                    : Text(value, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600)),
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
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: (color ?? Colors.blue).withOpacity(0.12),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: color ?? Colors.blue, size: 24.w),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w500, color: color ?? Colors.black87),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 28.w),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.h),
    );
  }
}