import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:ydm/core/utils/logger.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'ydm_downloads';
  static const String _channelName = 'Downloads';
  static const String _channelDescription = 'Download progress notifications';

  Future<NotificationService> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    LogService.info("NotificationService initialized.");
    return this;
  }

  void _onNotificationTap(NotificationResponse response) {
    LogService.debug("Notification tapped: ${response.payload}");
  }

  Future<void> showDownloadProgress({
    required int id,
    required String title,
    required int progress,
    required int maxProgress,
    String? body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
    );

    await _notifications.show(
      id,
      title,
      body ?? '${(progress / maxProgress * 100).toStringAsFixed(0)}%',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showDownloadComplete({required int id, required String title, String? body}) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _notifications.show(
      id,
      title,
      body ?? 'Download complete',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showDownloadFailed({required int id, required String title, String? body}) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _notifications.show(
      id,
      title,
      body ?? 'Download failed',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
