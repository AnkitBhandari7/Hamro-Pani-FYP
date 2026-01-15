import 'dart:convert';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';





class NewScheduleScreen extends StatefulWidget {
  const NewScheduleScreen({super.key});

  @override
  State<NewScheduleScreen> createState() => _NewScheduleScreenState();
}

class _NewScheduleScreenState extends State<NewScheduleScreen> {
  int selectedTab = 0; // 0 = Manual Entry, 1 = Upload File
  bool notifyResidents = true;

  // Manual Entry Fields
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? selectedWard;
  final TextEditingController _affectedAreasController = TextEditingController();

  // Upload File Fields
  File? selectedFile;
  String? fileName;

  final List<String> wards = [
    ...List.generate(32, (i) => "Kathmandu Ward ${i + 1}"),
    ...List.generate(29, (i) => "Lalitpur Ward ${i + 1}"),
    ...List.generate(10, (i) => "Bhaktapur Ward ${i + 1}"),
  ];

  @override
  void dispose() {
    _affectedAreasController.dispose();
    super.dispose();
  }

  //Manual Entry Helpers
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) startTime = picked;
        else endTime = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "mm/dd/yyyy";
    return "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "-- : -- --";
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  // File Upload
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        fileName = result.files.single.name;
      });
    }
  }

  // Publish Manual Schedule
  Future<void> _publishManualSchedule() async {
    if (selectedWard == null ||
        selectedDate == null ||
        startTime == null ||
        endTime == null ||
        _affectedAreasController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final scheduleData = {
      "ward": selectedWard,
      "affectedAreas": _affectedAreasController.text.trim(),
      "supplyDate": selectedDate!.toIso8601String(),
      "startTime": _formatTime(startTime),
      "endTime": _formatTime(endTime),
      "notifyResidents": notifyResidents,
    };

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not authenticated")),
        );
        return;
      }

      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/schedules'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode(scheduleData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Schedule published successfully!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error")),
      );
    }
  }

  // PREVIEW MODAL
  void _showPreview() {
    bool isUploadMode = selectedTab == 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 60.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            SizedBox(height: 16.h),

            // Title Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue, size: 28.w),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "Schedule Preview",
                      style: GoogleFonts.poppins(fontSize: 22.sp, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                "This is how residents will see your schedule",
                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24.h),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FF),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: Colors.blue[200]!, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.water_drop, color: Colors.blue, size: 32.w),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              "Water Supply Schedule",
                              style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      if (isUploadMode) ...[
                        _previewRow("File Uploaded", fileName ?? "No file selected", Icons.description),
                        SizedBox(height: 16.h),
                        _previewRow("Ward", selectedWard ?? "Not selected", Icons.location_on),
                      ] else ...[
                        _previewRow("Ward", selectedWard ?? "Not selected", Icons.location_on),
                        SizedBox(height: 16.h),
                        _previewRow("Affected Areas", _affectedAreasController.text.isEmpty ? "Not specified" : _affectedAreasController.text, Icons.map),
                        SizedBox(height: 16.h),
                        _previewRow("Supply Date", _formatDate(selectedDate), Icons.calendar_today),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(child: _previewRow("Start Time", _formatTime(startTime), Icons.access_time)),
                            SizedBox(width: 16.w),
                            Expanded(child: _previewRow("End Time", _formatTime(endTime), Icons.access_time_filled)),
                          ],
                        ),
                      ],

                      SizedBox(height: 24.h),
                      Divider(color: Colors.grey[400]),
                      SizedBox(height: 16.h),

                      Row(
                        children: [
                          Icon(Icons.notifications_active, color: notifyResidents ? Colors.blue : Colors.grey, size: 28.w),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              notifyResidents ? "Residents will be notified" : "No notifications will be sent",
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                color: notifyResidents ? Colors.blue[700] : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(24.w),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  "Close Preview",
                  style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[700], size: 24.w),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              SizedBox(height: 4.h),
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildToggleButton(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = title == "Manual Entry" ? 0 : 1;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[700], size: 20.w),
            SizedBox(width: 8.w),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTypeButton(String type) {
    return OutlinedButton(
      onPressed: _pickFile,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        side: BorderSide(color: Colors.blue[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
      ),
      child: Text(
        type,
        style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.blue[700]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isUploadMode = selectedTab == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "New Schedule",
          style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() {
                selectedTab = 0;
                selectedWard = null;
                selectedDate = null;
                startTime = null;
                endTime = null;
                _affectedAreasController.clear();
                selectedFile = null;
                fileName = null;
                notifyResidents = true;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildToggleButton("Manual Entry", Icons.edit_outlined, !isUploadMode)),
                  Expanded(child: _buildToggleButton("Upload File", Icons.cloud_upload_outlined, isUploadMode)),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (isUploadMode)
                      GestureDetector(
                        onTap: _pickFile,
                        child: DottedBorder(
                          borderType: BorderType.RRect,
                          radius: Radius.circular(24.r),
                          dashPattern: const [8, 8],
                          color: Colors.grey[400]!,
                          strokeWidth: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 64.w, color: Colors.blue[300]),
                                SizedBox(height: 16.h),
                                Text("Drag and drop or tap to upload", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                                SizedBox(height: 8.h),
                                Text("Select your schedule file to begin", style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[600])),
                                SizedBox(height: 24.h),
                                if (fileName != null)
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                                    child: Text("Selected: $fileName", style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.blue)),
                                  )
                                else
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildFileTypeButton("CSV"),
                                      SizedBox(width: 16.w),
                                      _buildFileTypeButton("PDF"),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (!isUploadMode) ...[
                      _buildManualCard(
                        icon: Icons.location_on,
                        title: "Location Details",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("WARD NUMBER", style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600])),
                            SizedBox(height: 8.h),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showModalBottomSheet<String>(
                                  context: context,
                                  builder: (_) => ListView.builder(
                                    itemCount: wards.length,
                                    itemBuilder: (_, i) => ListTile(
                                      title: Text(wards[i], style: GoogleFonts.poppins()),
                                      onTap: () => Navigator.pop(context, wards[i]),
                                    ),
                                  ),
                                );
                                if (picked != null) setState(() => selectedWard = picked);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16.r)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(selectedWard ?? "Select Ward", style: GoogleFonts.poppins(fontSize: 16.sp)),
                                    const Icon(Icons.keyboard_arrow_down),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text("AFFECTED AREAS", style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600])),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: _affectedAreasController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: "e.g. Galli No. 5, Main Chowk...\nSeparate with commas",
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                                contentPadding: EdgeInsets.all(16.w),
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildManualCard(
                        icon: Icons.access_time,
                        iconColor: Colors.orange,
                        title: "Date & Time",
                        child: Column(
                          children: [
                            Text("SUPPLY DATE", style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600])),
                            SizedBox(height: 8.h),
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16.r)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDate(selectedDate), style: GoogleFonts.poppins(fontSize: 16.sp)),
                                    const Icon(Icons.calendar_today),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Expanded(child: _timeField("START TIME", startTime, true)),
                                SizedBox(width: 16.w),
                                Expanded(child: _timeField("END TIME", endTime, false)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 32.h),

                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: Offset(0, 8.h))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined, color: Colors.blue[600], size: 24.w),
                              SizedBox(width: 12.w),
                              Text("Details", style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          if (selectedWard != null || fileName != null)
                            Text(
                              isUploadMode ? "File: $fileName" : "Ward: $selectedWard",
                              style: GoogleFonts.poppins(fontSize: 14.sp),
                            ),
                          SizedBox(height: 24.h),
                          Row(
                            children: [
                              Icon(Icons.notifications_outlined, color: Colors.purple[400], size: 24.w),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Notify Residents", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                                    Text("Alert affected users", style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: notifyResidents,
                                onChanged: (val) => setState(() => notifyResidents = val),
                                activeColor: Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40.h),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _showPreview,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.visibility, size: 20.w),
                                SizedBox(width: 8.w),
                                Text("Preview", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isUploadMode
                                ? () {
                              if (selectedFile == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please select a file")),
                                );
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("File upload not implemented yet")),
                              );
                            }
                                : _publishManualSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                            ),
                            child: Text(
                              "Publish →",
                              style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeField(String label, TimeOfDay? time, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600])),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _selectTime(context, isStart),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16.r)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatTime(time), style: GoogleFonts.poppins(fontSize: 16.sp)),
                const Icon(Icons.access_time),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualCard({required IconData icon, Color iconColor = Colors.blue, required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: Offset(0, 8.h))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24.w),
              SizedBox(width: 12.w),
              Text(title, style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 20.h),
          child,
        ],
      ),
    );
  }
}