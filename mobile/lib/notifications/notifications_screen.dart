import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fyp/models/notification_model.dart';
import 'package:fyp/notifications/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  static const String route = '/notifications';
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool loading = true;
  String? error;
  List<AppNotification> notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await NotificationService.getNotifications();
      if (!mounted) return;
      setState(() {
        notifications = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

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
              // Student note: "mark all read" API is not implemented yet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Mark all read (not implemented)")),
              );
            },
            child: const Text("Mark all read", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text("No notifications yet",
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const Text("We'll notify you when something new arrives",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final n = notifications[index];

            // Adjust these fields based on your AppNotification model.
            final title = n.title;
            final message = n.message;
            final createdAt = n.createdAt;

            final formattedTime =
            DateFormat('MMM dd, hh:mm a').format(createdAt.toLocal());

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.withOpacity(0.15),
                  child: const Icon(Icons.notifications, color: Colors.blue),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(message, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(formattedTime,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}