import '../../entities/notification.dart';
import '../../repositories/notification_repository_interface.dart';

/// Bildirimleri ve okunmamış bildirim adedini getiren kullanım senaryosu.
class GetNotificationsUseCase {
  final NotificationRepositoryInterface repository;

  const GetNotificationsUseCase(this.repository);

  Future<List<NotificationItem>> call() async {
    return repository.getNotifications();
  }

  Future<int> getUnreadCount() async {
    return repository.getUnreadCount();
  }

  Stream<List<NotificationItem>> watch() {
    return repository.watchNotifications();
  }
}
