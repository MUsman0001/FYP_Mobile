import 'package:dio/dio.dart';
import '../../core/api_client.dart';

class AuthApi {
  final ApiClient client;
  AuthApi(this.client);

  Future<(String token, Map<String, dynamic> user)> login({
    required String pNo,
    required String password,
  }) async {
    final Response res = await client.dio.post(
      '/auth/login',
      data: {'p_no': pNo, 'password': password},
    );
    final data = res.data['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    return (token, user);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final Response res = await client.dio.get('/auth/user');
    return (res.data['data']['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await client.dio.post('/auth/logout');
  }
}
