import 'package:flutter/material.dart';
import 'package:fyp/features/shared/notifications/models/notification_model.dart';
import 'package:fyp/features/shared/notifications/services/notification_service.dart';

class NotificationsController extends ChangeNotifier {
  bool isLoading = true;
  String? error;

  List<AppNotification> _all = [];
  String selectedTab = "All";

  List<AppNotification> get notifications {
    final tab = selectedTab.toUpperCase();

    if (tab == "ALL") return _all;

    if (tab == "UNREAD") {
      return _all.where((n) => n.isUnread).toList();
    }

    if (tab == "ORDERS") {
      return _all.where((n) => n.type.toUpperCase() == "BOOKING").toList();
    }

    if (tab == "SYSTEM") {
      return _all.where((n) => n.type.toUpperCase() != "BOOKING").toList();
    }

    return _all;
  }

  int get unreadCount => _all.where((n) => n.isUnread).length;

  NotificationsController() {
    load();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _all = await NotificationService.getNotifications();
      _all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void changeTab(String tab) {
    selectedTab = tab;
    notifyListeners();
  }

  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 60) return "JUST NOW";
    if (diff.inMinutes < 60) return "${diff.inMinutes} MIN AGO";
    if (diff.inHours < 24) return "${diff.inHours} HRS AGO";
    if (diff.inDays == 1) return "YESTERDAY";
    return "${diff.inDays} DAYS AGO";
  }

  void markAsReadLocal(int id) {
    final idx = _all.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    if (_all[idx].isRead) return;

    _all[idx] = _all[idx].copyWith(isRead: true);
    notifyListeners();
  }

  /// Permanent mark read (DB) + local update
  Future<void> markAsReadPermanent(int id) async {
    markAsReadLocal(id);
    await NotificationService.markAsRead(id);
  }

  /// Permanent mark all read (DB) + local update
  Future<void> markAllReadPermanent() async {
    // local first
    _all = _all.map((n) => n.isRead ? n : n.copyWith(isRead: true)).toList();
    notifyListeners();

    await NotificationService.markAllAsRead();
  }
}
