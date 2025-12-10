import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/api_client.dart';
import '../../core/secure_storage.dart';
import 'notification_api.dart';
import 'notification_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Ensure Firebase is initialized when running in background isolate
    await Firebase.initializeApp();
  } catch (_) {
    // ignore
  }
  // You can add background handling if needed
}

class NotificationsService {
  NotificationsService._internal()
    : _client = ApiClient(),
      _storage = SecureStorage(),
      _unreadCount = ValueNotifier<int>(0) {
    _repo = NotificationRepository(
      api: NotificationApi(_client),
      storage: _storage,
    );
  }

  static final NotificationsService I = NotificationsService._internal();

  final ApiClient _client;
  final SecureStorage _storage;
  late final NotificationRepository _repo;

  final ValueNotifier<int> _unreadCount;
  ValueListenable<int> get unreadCount => _unreadCount;

  Future<void> initPushIfPossible() async {
    // Try to init Firebase, but avoid crashing if no config is present
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      // Firebase ready
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // iOS permission
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          return; // no permission
        }
      }

      // Get token and register if logged in
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await registerTokenWithBackend(token);
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        registerTokenWithBackend(newToken);
      });

      // When a message arrives in foreground, refresh unread counter
      FirebaseMessaging.onMessage.listen((_) {
        refreshUnreadCount();
      });
    } catch (_) {}
  }

  Future<void> registerTokenWithBackend(String token) async {
    // Persist locally first
    await _storage.saveDeviceToken(token);

    try {
      final deviceType = kIsWeb
          ? 'web'
          : (Platform.isAndroid
                ? 'android'
                : (Platform.isIOS ? 'ios' : 'other'));
      final platform = deviceType;
      const appVersion = '1.0.0';
      await _repo.registerDeviceToken(
        token: token,
        deviceType: deviceType,
        platform: platform,
        appVersion: appVersion,
      );
    } catch (_) {
      // swallow errors; will retry on next refresh/launch
    }
  }

  Future<void> deregisterDeviceTokenIfAny() async {
    await _repo.deleteDeviceTokenIfAny();
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _repo.unreadCount();
      _unreadCount.value = count;
    } catch (_) {
      // ignore
    }
  }

  Future<PaginatedNotifications> fetchPage({int page = 1, int perPage = 20}) {
    return _repo.fetch(page: page, perPage: perPage);
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
    await refreshUnreadCount();
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    await refreshUnreadCount();
  }
}
