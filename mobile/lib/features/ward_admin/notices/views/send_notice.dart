import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fyp/services/api_service.dart';
import 'package:fyp/l10n/app_localizations.dart';

class SendNoticeScreen extends StatefulWidget {
  const SendNoticeScreen({super.key});

  @override
  State<SendNoticeScreen> createState() => _SendNoticeScreenState();
}

class _SendNoticeScreenState extends State<SendNoticeScreen> {
  int selectedNoticeType = 0; // 0: General, 1: Emergency, 2: Maintenance

  bool isHighPriority = false;
  bool isPushNotification = true;
  bool isSending = false;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  // Global notice not ward-specific.
  static const String _globalWard = "ALL";

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      selectedNoticeType = 0;
      isHighPriority = false;
      isPushNotification = true;
      titleController.clear();
      messageController.clear();
    });
  }

  String _noticeTypeValue() {
    switch (selectedNoticeType) {
      case 1:
        return "emergency";
      case 2:
        return "maintenance";
      default:
        return "general";
    }
  }

  String _noticeTypeLabel(AppLocalizations l10n) {
    switch (selectedNoticeType) {
      case 1:
        return l10n.noticeTypeEmergency;
      case 2:
        return l10n.noticeTypeMaintenance;
      default:
        return l10n.noticeTypeGeneral;
    }
  }

  bool _validate(AppLocalizations l10n) {
    if (titleController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      _toast(l10n.noticeValidationRequired, isError: true);
      return false;
    }
    return true;
  }

  Future<void> _sendNotice(AppLocalizations l10n) async {
    if (!_validate(l10n)) return;

    setState(() => isSending = true);
    try {
      final res = await ApiService.post('/notifications', {
        "ward": _globalWard,
        "title": titleController.text.trim(),
        "message": messageController.text.trim(),

        // Always send to everyone
        "recipient": "both",

        // optional metadata
        "type": _noticeTypeValue(),
        "highPriority": isHighPriority,
        "push": isPushNotification,
      });

      if (res.statusCode == 201 || res.statusCode == 200) {
        _toast(l10n.noticeSentToEveryone);
        if (mounted) Navigator.pop(context);
      } else {
        String msg = res.body;
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map && decoded["error"] != null) {
            msg = decoded["error"].toString();
          }
        } catch (_) {}
        _toast(l10n.noticeFailedToSend(msg), isError: true);
      }
    } catch (e) {
      _toast(l10n.noticeErrorSending(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  void _previewNotice(AppLocalizations l10n) {
    if (!_validate(l10n)) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 12.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.preview,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),
              _previewRow(l10n.type, _noticeTypeLabel(l10n)),
              _previewRow(l10n.audience, l10n.noticeAudienceEveryone),
              _previewRow(
                l10n.highPriority,
                isHighPriority ? l10n.yes : l10n.no,
              ),
              _previewRow(
                l10n.pushNotification,
                isPushNotification ? l10n.yes : l10n.no,
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.noticeTitleLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                titleController.text.trim(),
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.message,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                messageController.text.trim(),
                style: GoogleFonts.poppins(fontSize: 14.sp),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                    Navigator.pop(context);
                    await _sendNotice(l10n);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Text(
                    isSending ? l10n.sending : l10n.confirmAndSend,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 140.w,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.sendNotice,
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _reset,
            tooltip: l10n.reset,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.noticeTypeHeader,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: [
                  _buildTypeChip(
                    l10n.noticeTypeGeneral,
                    Icons.info_outline,
                    0,
                    Colors.blue,
                  ),
                  _buildTypeChip(
                    l10n.noticeTypeEmergency,
                    Icons.warning_amber,
                    1,
                    Colors.red,
                  ),
                  _buildTypeChip(
                    l10n.noticeTypeMaintenance,
                    Icons.build,
                    2,
                    Colors.orange,
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          color: Colors.blue[600],
                          size: 24.w,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          l10n.noticeContent,
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      l10n.noticeTitleHeader,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: l10n.noticeTitleHint,
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 14.sp,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      l10n.messageHeader,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: messageController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: l10n.noticeMessageHint,
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 14.sp,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              _switchCard(
                icon: Icons.priority_high,
                iconColor: Colors.orange,
                title: l10n.highPriority,
                subtitle: l10n.noticeHighPrioritySubtitle,
                value: isHighPriority,
                onChanged: (val) => setState(() => isHighPriority = val),
              ),
              SizedBox(height: 16.h),
              _switchCard(
                icon: Icons.notifications_active,
                iconColor: Colors.purple,
                title: l10n.pushNotification,
                subtitle: l10n.noticePushNotificationSubtitle,
                value: isPushNotification,
                onChanged: (val) => setState(() => isPushNotification = val),
              ),
              SizedBox(height: 40.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSending ? null : () => _previewNotice(l10n),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30.r)),
                        ),
                      ),
                      child: Text(
                        l10n.preview,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSending ? null : () => _sendNotice(l10n),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30.r)),
                        ),
                      ),
                      child: Text(
                        isSending ? l10n.sending : l10n.sendArrow,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24.w),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon, int index, Color color) {
    final isSelected = selectedNoticeType == index;
    return GestureDetector(
      onTap: () => setState(() => selectedNoticeType = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 20.w,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: isSelected ? color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}