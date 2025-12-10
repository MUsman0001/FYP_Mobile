import 'package:dio/dio.dart';
import '../../core/api_client.dart';

class NotificationApi {
  final ApiClient client;
  NotificationApi(this.client);

  Future<Map<String, dynamic>> fetchNotifications({
    int perPage = 20,
    int page = 1,
  }) async {
    final Response res = await client.dio.get(
      '/notifications',
      queryParameters: {'per_page': perPage, 'page': page},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<int> fetchUnreadCount() async {
    final Response res = await client.dio.get('/notifications/unread-count');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return (data['data']?['unread'] ?? data['unread'] ?? 0) as int;
    }
    return 0;
  }

  Future<void> markRead(String notificationId) async {
    await client.dio.post('/notifications/$notificationId/mark-read');
  }

  Future<void> markAllRead() async {
    await client.dio.post('/notifications/mark-all-read');
  }

  Future<void> registerDeviceToken({
    required String deviceToken,
    required String deviceType,
    required String platform,
    required String appVersion,
  }) async {
    await client.dio.post(
      '/notifications/device-tokens',
      data: {
        'device_token': deviceToken,
        'device_type': deviceType,
        'platform': platform,
        'app_version': appVersion,
      },
    );
  }

  Future<void> deleteDeviceToken(String deviceToken) async {
    await client.dio.delete(
      '/notifications/device-tokens',
      data: {'device_token': deviceToken},
    );
  }
}
