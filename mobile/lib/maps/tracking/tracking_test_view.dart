import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'vendor_tracking_view.dart';
import 'resident_tracking_view.dart';

class TrackingTestView extends StatelessWidget {
  const TrackingTestView({super.key});

  @override
  Widget build(BuildContext context) {
    const tripId = "booking_123"; // test key

    return Scaffold(
      appBar: AppBar(title: const Text("Tracking Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverTrackingView(tripId: tripId)),
                  );
                },
                child: const Text("Open Driver Tracking"),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerTrackView(
                        tripId: tripId,
                        destination: LatLng(27.7172, 85.3240), // Kathmandu
                      ),
                    ),
                  );
                },
                child: const Text("Open Customer Tracking"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}