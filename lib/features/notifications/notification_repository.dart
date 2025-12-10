import '../../core/secure_storage.dart';
import 'notification_api.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final String type;
  final Map<String, dynamic> data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    required this.type,
    required this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> payload = (json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : <String, dynamic>{};
    return NotificationItem(
      id: (json['id'] ?? json['uuid'] ?? json['notification_id']).toString(),
      title: (json['title'] ?? payload['title'] ?? '').toString(),
      body: (json['body'] ?? payload['body'] ?? '').toString(),
      read:
          (json['read'] ?? json['read_at'] != null || json['is_read'] == true)
              as bool,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      type: (json['type'] ?? payload['type'] ?? '').toString(),
      data: payload,
    );
  }
}

class PaginatedNotifications {
  final List<NotificationItem> items;
  final int currentPage;
  final int lastPage;

  PaginatedNotifications({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });
}

class NotificationRepository {
  final NotificationApi api;
  final SecureStorage storage;

  NotificationRepository({required this.api, required this.storage});

  Future<PaginatedNotifications> fetch({int page = 1, int perPage = 20}) async {
    final json = await api.fetchNotifications(page: page, perPage: perPage);
    // Expect a Laravel-style paginator payload
    final data =
        (json['data'] ?? json['notifications'] ?? json) as Map<String, dynamic>;
    final List list =
        (data['data'] ?? data['items'] ?? data['records'] ?? []) as List;
    final items = list
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final current = (data['current_page'] ?? 1) as int;
    final last = (data['last_page'] ?? current) as int;
    return PaginatedNotifications(
      items: items,
      currentPage: current,
      lastPage: last,
    );
  }

  Future<int> unreadCount() => api.fetchUnreadCount();

  Future<void> markRead(String id) => api.markRead(id);
  Future<void> markAllRead() => api.markAllRead();

  Future<void> registerDeviceToken({
    required String token,
    required String deviceType,
    required String platform,
    required String appVersion,
  }) async {
    await api.registerDeviceToken(
      deviceToken: token,
      deviceType: deviceType,
      platform: platform,
      appVersion: appVersion,
    );
    await storage.saveDeviceToken(token);
  }

  Future<void> deleteDeviceTokenIfAny() async {
    final saved = await storage.readDeviceToken();
    if (saved == null || saved.isEmpty) return;
    try {
      await api.deleteDeviceToken(saved);
    } finally {
      await storage.deleteDeviceToken();
    }
  }
}
