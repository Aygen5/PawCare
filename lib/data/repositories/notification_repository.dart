import 'dart:async';

import '../../domain/repositories/notification_repository_interface.dart';
import '../local/hive_boxes.dart';
import '../models/models.dart';

class NotificationRepository implements NotificationRepositoryInterface {
  final _notificationStreamController =
      StreamController<List<NotificationItem>>.broadcast();

  /// Okunmamış ve en yeni bildirimler üstte olacak şekilde tüm bildirimleri asenkron getirir.
  @override
  Future<List<NotificationItem>> getNotifications() async {
    final list = HiveBoxes.notifications.values.toList();
    list.sort((a, b) {
      if (a.isRead != b.isRead) {
        return a.isRead ? 1 : -1;
      }
      return b.timestamp.compareTo(a.timestamp);
    });
    return list;
  }

  /// Okunmamış bildirim sayısını asenkron döner.
  @override
  Future<int> getUnreadCount() async {
    return HiveBoxes.notifications.values.where((n) => !n.isRead).length;
  }

  /// Bildirim akışını gerçek zamanlı yayınlar.
  @override
  Stream<List<NotificationItem>> watchNotifications() {
    _notifyStream();
    return _notificationStreamController.stream;
  }

  Future<void> _notifyStream() async {
    final list = await getNotifications();
    if (!_notificationStreamController.isClosed) {
      _notificationStreamController.add(list);
    }
  }

  /// Yeni bir bildirim ekler.
  @override
  Future<void> addNotification(covariant NotificationItem notification) async {
    await HiveBoxes.notifications.put(notification.id, notification);
    await _notifyStream();
  }

  /// Belirtilen bildirimi okundu olarak işaretler.
  @override
  Future<void> markAsRead(String id) async {
    final notif = HiveBoxes.notifications.get(id);
    if (notif != null && !notif.isRead) {
      final updated = notif.copyWith(isRead: true);
      await HiveBoxes.notifications.put(id, updated);
      await _notifyStream();
    }
  }

  /// Tüm bildirimleri okundu olarak işaretler.
  @override
  Future<void> markAllAsRead() async {
    for (final notif in HiveBoxes.notifications.values) {
      if (!notif.isRead) {
        final updated = notif.copyWith(isRead: true);
        await HiveBoxes.notifications.put(notif.id, updated);
      }
    }
    await _notifyStream();
  }

  /// Tüm bildirimleri siler.
  @override
  Future<void> clearAll() async {
    await HiveBoxes.notifications.clear();
    await _notifyStream();
  }
}
