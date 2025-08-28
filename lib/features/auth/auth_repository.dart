import '../../core/secure_storage.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi api;
  final SecureStorage storage;

  AuthRepository({required this.api, required this.storage});

  Future<Map<String, dynamic>> login(String pNo, String password) async {
    final (token, user) = await api.login(pNo: pNo, password: password);
    await storage.saveToken(token);
    return user;
  }

  Future<Map<String, dynamic>> getCurrentUser() => api.getCurrentUser();

  Future<void> logout() async {
    try {
      await api.logout();
    } finally {
      await storage.deleteToken();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.readToken();
    return token != null && token.isNotEmpty;
  }
}
