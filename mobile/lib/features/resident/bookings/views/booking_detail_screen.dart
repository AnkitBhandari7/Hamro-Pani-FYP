import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:fyp/l10n/app_localizations.dart';
import '../controllers/booking_detail_controller.dart';
import '../services/booking_service.dart';
import '../../../shared/maps/tracking/vendor_tracking_view.dart';

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
      case "DELIVERED":
        return Colors.purple;
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
      case "CONFIRMED":
        return t.bookingStatusConfirmed;
      case "DELIVERED":
        return t.bookingStatusDelivered;
      case "PENDING":
        return t.bookingStatusPending;
      default:
        return s;
    }
  }

  Future<Map<String, dynamic>?> _showConfirmDeliverySheet(
      BuildContext context,
      AppLocalizations t,
      ) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ConfirmDeliverySheet(t: t),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return ChangeNotifierProvider(
      create: (_) => BookingDetailController(bookingId),
      child: Consumer<BookingDetailController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (ctrl.detail == null) {
            return Scaffold(
              appBar: AppBar(title: Text(t.bookingDetailTitle)),
              body: Center(child: Text(ctrl.error ?? t.failedToLoad)),
            );
          }

          final d = ctrl.detail!;
          final statusColor = _statusColor(d.status);
          final statusText = _statusLabel(t, d.status);

          final start = d.startTime?.toLocal();
          final end = d.endTime?.toLocal();
          final timeRange = (start != null && end != null)
              ? "${DateFormat('MMM dd, h:mm a', localeTag).format(start)} - ${DateFormat('h:mm a', localeTag).format(end)}"
              : "—";

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              title: Text(
                t.bookingNumberTitle(d.bookingId),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              centerTitle: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.vendorName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${d.location}${d.wardName.isNotEmpty ? " • ${d.wardName}" : ""}",
                          style: GoogleFonts.poppins(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusText,
                                style: GoogleFonts.poppins(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeRange,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(t.tankerLabel(d.liters), style: GoogleFonts.poppins()),
                        Text(t.priceLabel(d.price?.toString() ?? '—'),
                            style: GoogleFonts.poppins()),
                        if (d.payment != null) ...[
                          Text(
                            (d.payment!['status']?.toString().toUpperCase() == 'COMPLETED')
                                ? (d.payment!['method']?.toString().toUpperCase() == 'ESEWA'
                                    ? 'Paid via eSewa'
                                    : 'Paid')
                                : 'Unpaid (Cash on Delivery)',
                            style: GoogleFonts.poppins(
                              color: (d.payment!['status']?.toString().toUpperCase() == 'COMPLETED')
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Unpaid (Cash on Delivery)',
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        Text(
                          t.bookingSlotsLabel(d.bookingSlotsUsed, d.bookingSlotsTotal),
                          style: GoogleFonts.poppins(),
                        ),

                        // ✅ Delivery confirmation UI
                        if (d.canConfirmDelivery) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: ctrl.isSubmittingConfirm
                                  ? null
                                  : () async {
                                try {
                                  final result =
                                  await _showConfirmDeliverySheet(context, t);
                                  if (result == null) return;

                                  final rating = (result['rating'] as int?) ?? 5;
                                  final comment = (result['comment'] as String?)?.trim();

                                  await ctrl.confirmDeliveryAndRate(
                                    rating: rating,
                                    comment: comment,
                                  );

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.thankYouForRating)),
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
                              child: ctrl.isSubmittingConfirm
                                  ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(t.confirmDeliveryAndRate),
                            ),
                          ),
                        ] else if (d.myRating != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            t.yourRatingLabel(d.myRating!.rating),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          if ((d.myRating!.comment ?? '').trim().isNotEmpty)
                            Text(
                              d.myRating!.comment!,
                              style: GoogleFonts.poppins(color: Colors.grey[700]),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t.trackingTitle,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                            ),
                            if (["PENDING", "CONFIRMED", "DELIVERED"].contains(d.status.toUpperCase()))
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResidentTrackingScreen(bookingId: d.bookingId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.my_location_rounded, size: 18),
                                label: const Text('Live Track'),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  foregroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (d.history.isEmpty)
                          Text(
                            t.noTrackingHistoryYet,
                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                          )
                        else
                          ...d.history.map((h) {
                            final dt = DateTime.tryParse(h['changedAt'].toString())
                                ?.toLocal();
                            final when = dt != null
                                ? DateFormat('MMM dd, h:mm a', localeTag).format(dt)
                                : '-';

                            final newStatusRaw = (h['newStatus'] ?? '').toString();
                            final newStatusText = _statusLabel(t, newStatusRaw);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                t.statusWithWhen(newStatusText, when),
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

class _ConfirmDeliverySheet extends StatefulWidget {
  const _ConfirmDeliverySheet({required this.t});
  final AppLocalizations t;

  @override
  State<_ConfirmDeliverySheet> createState() => _ConfirmDeliverySheetState();
}

class _ConfirmDeliverySheetState extends State<_ConfirmDeliverySheet> {
  int rating = 5;
  final commentCtrl = TextEditingController();

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    Widget star(int i) {
      final filled = i <= rating;
      return IconButton(
        onPressed: () => setState(() => rating = i),
        icon: Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: filled ? Colors.amber : Colors.grey,
          size: 32,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.confirmDeliveryTitle,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            t.rateVendorPrompt,
            style: GoogleFonts.poppins(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [star(1), star(2), star(3), star(4), star(5)],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: t.optionalCommentHint,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'rating': rating,
                  'comment': commentCtrl.text.trim(),
                });
              },
              child: Text(t.submit),
            ),
          ),
        ],
      ),
    );
  }
}