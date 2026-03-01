import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'complaint_detail_controller.dart';

class ComplaintDetailScreen extends StatelessWidget {
  const ComplaintDetailScreen({super.key, required this.complaintId});
  final int complaintId;

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case "RESOLVED":
        return Colors.green;
      case "IN_REVIEW":
        return Colors.blue;
      case "REJECTED":
        return Colors.red;
      case "OPEN":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ComplaintDetailController(complaintId),
      child: Consumer<ComplaintDetailController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (ctrl.detail == null) {
            return Scaffold(
              appBar: AppBar(title: const Text("Complaint Detail")),
              body: Center(child: Text(ctrl.error ?? "Failed to load")),
            );
          }

          final d = ctrl.detail!;
          final statusColor = _statusColor(d.status);

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              centerTitle: true,
              title: Text(
                "Complaint #${d.id}",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              d.status,
                              style: GoogleFonts.poppins(color: statusColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM dd, h:mm a').format(d.createdAt.toLocal()),
                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text("Booking #${d.bookingId}", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text(d.message, style: GoogleFonts.poppins(color: Colors.grey[800])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (d.photoUrls.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Photos", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: d.photoUrls.map((url) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(url, width: 110, height: 110, fit: BoxFit.cover),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}