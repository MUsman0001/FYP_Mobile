import 'package:dio/dio.dart';
import '../../core/api_client.dart';

class AuthApi {
  final ApiClient client;
  AuthApi(this.client);

  /// Login endpoint - handles both MFA and non-MFA cases
  /// Returns (token, user, requiresMfa, userId)
  Future<
    ({String? token, Map<String, dynamic> user, bool requiresMfa, int? userId})
  >
  login({required String pNo, required String password}) async {
    final Response res = await client.dio.post(
      '/auth/login',
      data: {'p_no': pNo, 'password': password},
    );

    final requiresMfa = res.data['requires_mfa'] as bool? ?? false;
    final data = res.data['data'] as Map<String, dynamic>;

    if (requiresMfa) {
      // MFA is required - return user_id but no token yet
      return (
        token: null,
        user: data,
        requiresMfa: true,
        userId: data['user_id'] as int?,
      );
    } else {
      // MFA not required - return token immediately
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;
      return (token: token, user: user, requiresMfa: false, userId: null);
    }
  }

  /// Verify MFA code - called after user enters 6-digit code
  Future<(String token, Map<String, dynamic> user)> verifyMfa({
    required int userId,
    required String code,
  }) async {
    final Response res = await client.dio.post(
      '/auth/mfa/verify',
      data: {'user_id': userId, 'code': code},
    );

    final data = res.data['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    return (token, user);
  }

  /// Resend MFA code to user's email
  Future<void> resendMfaCode({required int userId}) async {
    await client.dio.post('/auth/mfa/resend', data: {'user_id': userId});
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final Response res = await client.dio.get('/auth/user');
    return (res.data['data']['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await client.dio.post('/auth/logout');
  }

  Future<void> requestPasswordReset({required String email}) async {
    await client.dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await client.dio.post(
      '/auth/verify-reset-code',
      data: {'email': email, 'code': code},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await client.dio.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'code': code,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );
  }
}
