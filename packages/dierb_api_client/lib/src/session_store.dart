import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DierbSessionStore {
  DierbSessionStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _access = 'dierb_access_token';
  static const _refresh = 'dierb_refresh_token';
  Future<String?> get accessToken => _storage.read(key: _access);
  Future<String?> get refreshToken => _storage.read(key: _refresh);
  Future<bool> get hasSession async => (await refreshToken)?.isNotEmpty == true;
  Future<void> save(String access, String refresh) async {
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }
  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }
}
