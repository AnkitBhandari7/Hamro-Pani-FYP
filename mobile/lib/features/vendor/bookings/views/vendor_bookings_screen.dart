import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:fyp/l10n/app_localizations.dart';
import '../controllers/vendor_bookings_controller.dart';

class VendorBookingsScreen extends StatelessWidget {
  static const route = '/vendor/bookings';
  const VendorBookingsScreen({super.key});

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case "COMPLETED":
        return Colors.green;
      case "CANCELLED":
        return Colors.red;
      case "DELIVERED":
        return Colors.purple;
      case "CONFIRMED":
        return Colors.blue;
      case "PENDING":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(AppLocalizations t, String s) {
    switch (s.toUpperCase()) {
      case "COMPLETED":
        return t.bookingStatusCompleted;
      case "CANCELLED":
        return t.bookingStatusCancelled;
      case "DELIVERED":
        return t.bookingStatusDelivered;
      case "CONFIRMED":
        return t.bookingStatusConfirmed;
      case "PENDING":
        return t.bookingStatusPending;
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    const statuses = ["CONFIRMED", "DELIVERED", "COMPLETED", "CANCELLED"];

    String statusTabLabel(String s) {
      switch (s) {
        case "CONFIRMED":
          return t.vendorTabToDeliver;
        case "DELIVERED":
          return t.vendorTabDelivered;
        case "COMPLETED":
          return t.vendorTabCompleted;
        case "CANCELLED":
          return t.vendorTabCancelled;
        default:
          return s;
      }
    }

    return ChangeNotifierProvider(
      create: (_) => VendorBookingsController(),
      child: Consumer<VendorBookingsController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.black),
              title: Text(
                t.vendorBookingsTitle,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: ctrl.isLoading ? null : () => ctrl.load(),
                  icon: const Icon(Icons.refresh),
                  tooltip: t.refresh,
                ),
              ],
            ),
            body: Column(
              children: [
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statuses.map((s) {
                      final isSelected = ctrl.selectedStatus == s;
                      return ChoiceChip(
                        label: Text(statusTabLabel(s)),
                        selected: isSelected,
                        onSelected: (_) => ctrl.setStatus(s),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (ctrl.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (ctrl.error != null && ctrl.items.isEmpty) {
                        return Center(
                          child: Text(
                            ctrl.error!,
                            style: GoogleFonts.poppins(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (ctrl.items.isEmpty) {
                        return Center(
                          child: Text(
                            t.noBookingsFound,
                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: ctrl.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final b = ctrl.items[i];
                          final c = _statusColor(b.status);
                          final statusText = _statusLabel(t, b.status);

                          final timeText =
                          (b.startTime != null && b.endTime != null)
                              ? "${DateFormat('MMM dd, h:mm a', localeTag).format(b.startTime!)} - ${DateFormat('h:mm a', localeTag).format(b.endTime!)}"
                              : "—";

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      t.bookingNumberTitle(b.bookingId),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: c,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${t.residentLabel}: ${b.residentName}",
                                  style: GoogleFonts.poppins(),
                                ),
                                if (b.residentPhone.trim().isNotEmpty)
                                  Text(
                                    "${t.phoneLabel}: ${b.residentPhone}",
                                    style: GoogleFonts.poppins(),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  "${t.locationLabel}: ${b.location}${b.wardName.trim().isNotEmpty ? " • ${b.wardName}" : ""}",
                                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "${t.timeLabel}: $timeText",
                                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 6),
                                Text(t.tankerLabel(b.liters), style: GoogleFonts.poppins()),
                                Text(
                                  t.priceLabel(b.price?.toString() ?? '—'),
                                  style: GoogleFonts.poppins(),
                                ),
                                if (b.canMarkDelivered) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: ctrl.isUpdating
                                          ? null
                                          : () async {
                                        try {
                                          await ctrl.markDelivered(b.bookingId);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(t.markedAsDelivered),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("${t.actionFailed}: $e"),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      child: ctrl.isUpdating
                                          ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                          : Text(t.markDelivered),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
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