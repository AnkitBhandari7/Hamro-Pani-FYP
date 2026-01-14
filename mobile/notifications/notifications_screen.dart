// lib/views/notifications/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this package for time formatting

class NotificationScreen extends StatelessWidget {
  static const String route = '/notifications';
  const NotificationScreen({super.key});

  // Sample notifications – replace with real data later
  final List<Map<String, dynamic>> notifications = const [
    {
      "title": "Booking Confirmed!",
      "message": "Your 5000L tanker booking for tomorrow 10:00 AM has been confirmed.",
      "time": "2025-11-17T14:30:00",
      "type": "success",
      "read": false,
    },
    {
      "title": "Tanker On The Way",
      "message": "Driver Ram Bahadur is on the way with 6000L tanker (Reg: Ba 2-1234).",
      "time": "2025-11-17T12:15:00",
      "type": "info",
      "read": false,
    },
    {
      "title": "Payment Received",
      "message": "Rs 780 has been added to your wallet.",
      "time": "2025-11-16T18:45:00",
      "type": "payment",
      "read": true,
    },
    {
      "title": "New Offer!",
      "message": "Book 3 times this week & get 10% off on next order!",
      "time": "2025-11-15T09:00:00",
      "type": "offer",
      "read": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF007BFF),
        title: const Text("Notifications", style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All notifications marked as read")),
              );
            },
            child: const Text("Mark all read", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text("No notifications yet", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            Text("We'll notify you when something new arrives", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final noti = notifications[index];
          final time = DateTime.parse(noti["time"]);
          final formattedTime = DateFormat('MMM dd, hh:mm a').format(time);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: noti["read"] ? 1 : 4,
            color: noti["read"] ? Colors.white : Colors.blue[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: _getTypeColor(noti["type"]).withOpacity(0.2),
                child: Icon(
                  _getTypeIcon(noti["type"]),
                  color: _getTypeColor(noti["type"]),
                  size: 28,
                ),
              ),
              title: Text(
                noti["title"],
                style: TextStyle(
                  fontWeight: noti["read"] ? FontWeight.normal : FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(noti["message"], style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    formattedTime,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: noti["read"]
                  ? null
                  : Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              onTap: () {
                // Mark as read on tap
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${noti["title"]} tapped")),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case "success":
        return Colors.green;
      case "info":
        return Colors.blue;
      case "payment":
        return Colors.purple;
      case "offer":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case "success":
        return Icons.check_circle;
      case "info":
        return Icons.local_shipping;
      case "payment":
        return Icons.account_balance_wallet;
      case "offer":
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }
}