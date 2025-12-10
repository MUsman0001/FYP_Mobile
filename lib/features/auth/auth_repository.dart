import '../../core/secure_storage.dart';
import 'auth_api.dart';
import '../notifications/notifications_service.dart';

class AuthRepository {
  final AuthApi api;
  final SecureStorage storage;

  AuthRepository({required this.api, required this.storage});

  /// Login - returns (user, requiresMfa, userId)
  /// If MFA is required, userId will be set and token will be null
  /// If MFA is not required, token will be saved automatically
  Future<({Map<String, dynamic> user, bool requiresMfa, int? userId})> login(
    String pNo,
    String password,
  ) async {
    final result = await api.login(pNo: pNo, password: password);

    if (!result.requiresMfa && result.token != null) {
      // MFA not required - save token immediately
      await storage.saveToken(result.token!);
      // Register device token in background (best-effort)
      // Initialize push and send token to backend
      await NotificationsService.I.initPushIfPossible();
    }

    return (
      user: result.user,
      requiresMfa: result.requiresMfa,
      userId: result.userId,
    );
  }

  /// Verify MFA code and save token
  Future<Map<String, dynamic>> verifyMfa({
    required int userId,
    required String code,
  }) async {
    final (token, user) = await api.verifyMfa(userId: userId, code: code);
    // Save token after MFA verification
    await storage.saveToken(token);
    // Register device token post-auth
    await NotificationsService.I.initPushIfPossible();
    return user;
  }

  /// Resend MFA code
  Future<void> resendMfaCode({required int userId}) async {
    await api.resendMfaCode(userId: userId);
  }

  Future<Map<String, dynamic>> getCurrentUser() => api.getCurrentUser();

  Future<void> logout() async {
    try {
      // Try to deregister device token first (best-effort)
      await NotificationsService.I.deregisterDeviceTokenIfAny();
      await api.logout();
    } finally {
      await storage.deleteToken();
      await storage.deleteDeviceToken();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> requestPasswordReset(String email) =>
      api.requestPasswordReset(email: email);

  Future<void> verifyResetCode(String email, String code) =>
      api.verifyResetCode(email: email, code: code);

  Future<void> resetPassword(String email, String code, String newPassword) =>
      api.resetPassword(email: email, code: code, newPassword: newPassword);
}
