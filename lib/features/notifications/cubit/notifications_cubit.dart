import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/firebase_notification_repository.dart';
import '../../../domain/entities/notification.dart';
import '../../../domain/repositories/notification_repository_interface.dart';
import '../../../domain/usecases/notification/get_notifications_use_case.dart';
import '../../../domain/usecases/notification/mark_notification_read_use_case.dart';
import 'notifications_state.dart';

/// Bildirimlerin yüklenmesini, okundu işaretlenmesini ve yerel demo olaylarını yöneten Clean Architecture Cubit'i.
class NotificationsCubit extends Cubit<NotificationsState> {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;
  final NotificationRepositoryInterface _notificationRepository;
  StreamSubscription<List<NotificationItem>>? _notificationSubscription;

  NotificationsCubit({
    GetNotificationsUseCase? getNotificationsUseCase,
    MarkNotificationReadUseCase? markNotificationReadUseCase,
    NotificationRepositoryInterface? notificationRepository,
    List<NotificationItem>? initialNotifications,
  }) : _notificationRepository =
            notificationRepository ?? FirebaseNotificationRepository(),
        _getNotificationsUseCase =
            getNotificationsUseCase ??
            GetNotificationsUseCase(
              notificationRepository ?? FirebaseNotificationRepository(),
            ),
        _markNotificationReadUseCase =
            markNotificationReadUseCase ??
            MarkNotificationReadUseCase(
              notificationRepository ?? FirebaseNotificationRepository(),
            ),
        super(const NotificationsState()) {
    if (initialNotifications != null && initialNotifications.isNotEmpty) {
      _applyNotifications(initialNotifications, state.activeFilter);
    } else {
      loadNotifications();
    }
    _startWatching();
  }

  void _startWatching() {
    _notificationSubscription?.cancel();
    _notificationSubscription =
        _notificationRepository.watchNotifications().listen((list) {
      if (list.isNotEmpty) {
        _applyNotifications(list, state.activeFilter);
      }
    });
  }

  /// Veritabanındaki tüm bildirimleri asenkron getirir ve filtre durumuna göre listeyi yayar.
  Future<void> loadNotifications({List<NotificationItem>? fallbackNotifications}) async {
    try {
      emit(state.copyWith(status: NotificationsStatus.loading));
      var list = await _getNotificationsUseCase.call();
      if (list.isEmpty &&
          fallbackNotifications != null &&
          fallbackNotifications.isNotEmpty) {
        list = fallbackNotifications;
      }
      _applyNotifications(list, state.activeFilter);
    } catch (e) {
      if (fallbackNotifications != null && fallbackNotifications.isNotEmpty) {
        _applyNotifications(fallbackNotifications, state.activeFilter);
      } else {
        emit(
          state.copyWith(
            status: NotificationsStatus.error,
            errorMessage: 'Bildirimler yüklenirken hata oluştu: $e',
          ),
        );
      }
    }
  }

  /// Aktif filtre türünü günceller (Tümü, Okunmamış, Aşı, Rezervasyon).
  void setFilter(NotificationFilter filter) {
    _applyNotifications(state.allNotifications, filter);
  }

  /// Filtreye göre listeyi ve okunmamış sayacını günceller.
  void _applyNotifications(
    List<NotificationItem> all,
    NotificationFilter filter,
  ) {
    List<NotificationItem> filtered;
    switch (filter) {
      case NotificationFilter.all:
        filtered = all;
        break;
      case NotificationFilter.unread:
        filtered = all.where((n) => !n.isRead).toList();
        break;
      case NotificationFilter.booking:
        filtered = all.where((n) => n.type == 'booking').toList();
        break;
      case NotificationFilter.vaccine:
        filtered = all.where((n) => n.type == 'vaccine').toList();
        break;
    }

    final unread = all.where((n) => !n.isRead).length;

    emit(
      state.copyWith(
        status: NotificationsStatus.loaded,
        allNotifications: all,
        filteredNotifications: filtered,
        activeFilter: filter,
        unreadCount: unread,
        errorMessage: null,
        markingId: null,
      ),
    );
  }

  /// Tek bir bildirimi okundu olarak işaretler.
  Future<void> markAsRead(String id) async {
    try {
      emit(state.copyWith(markingId: id));
      await _markNotificationReadUseCase.markSingleAsRead(id);
      await loadNotifications();
    } catch (_) {
      final updated = state.allNotifications.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList();
      _applyNotifications(updated, state.activeFilter);
    }
  }

  /// Tüm bildirimleri okundu olarak işaretler.
  Future<void> markAllAsRead() async {
    try {
      await _markNotificationReadUseCase.markAllAsRead();
      await loadNotifications();
    } catch (_) {
      final updated = state.allNotifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _applyNotifications(updated, state.activeFilter);
    }
  }

  /// 4 tanımlı yerel olay bildiriminden birini tetikler ve listeye ekler.
  Future<void> triggerLocalEventNotification({
    required String title,
    required String body,
    String type = 'system',
  }) async {
    final newNotif = NotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
    );

    try {
      await _notificationRepository.addNotification(newNotif);
      await loadNotifications();
    } catch (_) {
      final updated = [newNotif, ...state.allNotifications];
      _applyNotifications(updated, state.activeFilter);
    }
  }

  /// Tüm bildirimleri temizler.
  Future<void> clearAll() async {
    try {
      await _markNotificationReadUseCase.clearAll();
      await loadNotifications();
    } catch (_) {
      _applyNotifications([], state.activeFilter);
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
