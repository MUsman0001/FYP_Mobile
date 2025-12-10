import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _tokenKey = 'auth_token';
  static const _deviceTokenKey = 'device_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<void> saveDeviceToken(String token) =>
      _storage.write(key: _deviceTokenKey, value: token);
  Future<String?> readDeviceToken() => _storage.read(key: _deviceTokenKey);
  Future<void> deleteDeviceToken() => _storage.delete(key: _deviceTokenKey);
}
