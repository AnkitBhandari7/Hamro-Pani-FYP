import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static final SessionManager instance = SessionManager._();
  SessionManager._();

  final _storage = const FlutterSecureStorage();
  String? _memoryJwt;

  Future<void> persistJwt(String jwt, {required bool remember}) async {
    if (remember) {
      await _storage.write(key: 'jwt', value: jwt);
    } else {
      _memoryJwt = jwt;
      await _storage.delete(key: 'jwt');
    }
  }

  Future<String?> getJwt() async {
    return _memoryJwt ?? await _storage.read(key: 'jwt');
  }

  Future<void> clear() async {
    _memoryJwt = null;
    await _storage.delete(key: 'jwt');
  }
}