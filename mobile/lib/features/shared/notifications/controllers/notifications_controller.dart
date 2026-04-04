import 'package:flutter/material.dart';
import 'package:fyp/features/shared/notifications/models/notification_model.dart';
import 'package:fyp/features/shared/notifications/services/notification_service.dart';
import 'package:fyp/l10n/app_localizations.dart';

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

    if (tab == "REPORTS") {
      return _all.where((n) => n.type.toUpperCase() == "COMPLAINT").toList();
    }

    if (tab == "SYSTEM") {
      return _all.where((n) => n.type.toUpperCase() != "BOOKING" && n.type.toUpperCase() != "COMPLAINT").toList();
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

  /// ✅ Localized time ago using l10n
  String timeAgoLocalized(BuildContext context, DateTime dt) {
    final t = AppLocalizations.of(context);
    if (t == null) return _timeAgoEnglish(dt);

    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 60) return t.justNow;
    if (diff.inMinutes < 60) return t.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return t.hoursAgo(diff.inHours);
    if (diff.inDays == 1) return t.yesterday;
    return t.daysAgo(diff.inDays);
  }

  // fallback
  String _timeAgoEnglish(DateTime dt) {
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
    _all = _all.map((n) => n.isRead ? n : n.copyWith(isRead: true)).toList();
    notifyListeners();

    await NotificationService.markAllAsRead();
  }
}