import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static final SessionManager instance = SessionManager._();
  SessionManager._();

  final _storage = const FlutterSecureStorage();

  // You can store other session data here if needed, e.g., user role, ward, etc.

  Future<void> clear() async {
    await _storage.deleteAll(); // clears all stored session data
  }
}
