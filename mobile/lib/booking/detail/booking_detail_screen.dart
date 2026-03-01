import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'booking_detail_controller.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final int bookingId;

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case "COMPLETED":
        return Colors.green;
      case "CANCELLED":
        return Colors.red;
      case "CONFIRMED":
        return Colors.blue;
      case "PENDING":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingDetailController(bookingId),
      child: Consumer<BookingDetailController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (ctrl.detail == null) {
            return Scaffold(
              appBar: AppBar(title: const Text("Booking Detail")),
              body: Center(child: Text(ctrl.error ?? "Failed to load")),
            );
          }

          final d = ctrl.detail!;
          final statusColor = _statusColor(d.status);

          final start = d.startTime?.toLocal();
          final end = d.endTime?.toLocal();
          final timeRange = (start != null && end != null)
              ? "${DateFormat('MMM dd, h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}"
              : "—";

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              title: Text("Booking #${d.bookingId}", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
              centerTitle: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.vendorName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          "${d.location}${d.wardName.isNotEmpty ? " • ${d.wardName}" : ""}",
                          style: GoogleFonts.poppins(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 10),
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
                            Text(timeRange, style: GoogleFonts.poppins(color: Colors.grey[700])),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text("Tanker: ${d.liters}L", style: GoogleFonts.poppins()),
                        Text("Price: ${d.price ?? '—'}", style: GoogleFonts.poppins()),
                        Text("Booking slots: ${d.bookingSlotsUsed}/${d.bookingSlotsTotal}", style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Tracking", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        if (d.history.isEmpty)
                          Text("No tracking history yet.", style: GoogleFonts.poppins(color: Colors.grey[700]))
                        else
                          ...d.history.map((h) {
                            final dt = DateTime.tryParse(h['changedAt'].toString())?.toLocal();
                            final when = dt != null ? DateFormat('MMM dd, h:mm a').format(dt) : '-';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                "${h['newStatus']} • $when",
                                style: GoogleFonts.poppins(color: Colors.grey[800]),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}