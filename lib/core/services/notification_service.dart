import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/firebase_notification_repository.dart';
import '../../domain/entities/notification.dart';

/// Firebase Cloud Messaging arka plan mesaj dinleyicisi.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM arka plan bildirimi alindi: ${message.messageId}');
}

/// Firebase Cloud Messaging (FCM) ve Sistem Bildirim Servisi.
/// İzinleri yönetir, FCM token'ını Firestore'a senkronize eder ve gelen bildirimleri dinler.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseNotificationRepository _notificationRepo =
      FirebaseNotificationRepository();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  /// FCM Servisini başlatır ve izinleri talep eder.
  Future<void> initialize({String? currentUserId}) async {
    try {
      if (Firebase.apps.isEmpty) return;

      // 1. Bildirim İznini İste (iOS & Android 13+)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Izin Durumu: ${settings.authorizationStatus}');

      // 2. Token al ve Firestore'a senkronize et
      if (currentUserId != null && currentUserId.isNotEmpty) {
        await syncFcmToken(currentUserId);
      }

      // 3. Ön Plan Mesaj Dinleyicisi
      _foregroundSubscription?.cancel();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          debugPrint('On plan FCM bildirimi: ${message.notification?.title}');
          _handleIncomingRemoteMessage(message, currentUserId);
        },
      );

      // 4. Token / Kayıt yenilendiğinde tekrar kaydet
      messaging.onRegistered.listen((token) {
        if (currentUserId != null && currentUserId.isNotEmpty) {
          _saveTokenToFirestore(currentUserId, token);
        }
      });
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Cihazı FCM'e kaydeder ve token'ı kullanıcının Firestore profiline yazar.
  Future<void> syncFcmToken(String userId) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseMessaging.instance.register();
    } catch (e) {
      debugPrint('FCM Token sync error: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token Firestore users/$userId dokumanina kaydedildi.');
      }
    } catch (e) {
      debugPrint('FCM token save error: $e');
    }
  }

  void _handleIncomingRemoteMessage(RemoteMessage message, String? userId) {
    final notification = message.notification;
    if (notification == null) return;

    final item = NotificationItem(
      id: message.messageId ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: notification.title ?? 'Yeni Bildirim',
      body: notification.body ?? '',
      timestamp: DateTime.now(),
      type: message.data['type'] ?? 'system',
      isRead: false,
    );

    _notificationRepo.addNotification(item);
  }

  /// Rezervasyon onaylandığında köpek sahibine bildirim gönderir.
  Future<void> notifyBookingConfirmed({
    required String ownerUserId,
    required String petName,
    required String sitterName,
  }) async {
    final item = NotificationItem(
      id: 'notif_booking_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Rezervasyon Onaylandı! 🐾',
      body: '$sitterName, $petName için rezervasyonunuzu onayladı. Bizi tercih ettiğiniz için teşekkürler!',
      timestamp: DateTime.now(),
      type: 'booking',
      isRead: false,
    );

    await _notificationRepo.addNotification(item);
  }

  /// Yeni sohbet mesajı geldiğinde alıcıya bildirim düşürür.
  Future<void> notifyNewChatMessage({
    required String receiverUserId,
    required String senderName,
    required String messageText,
  }) async {
    final item = NotificationItem(
      id: 'notif_chat_${DateTime.now().millisecondsSinceEpoch}',
      title: '$senderName yeni mesaj gönderdi 💬',
      body: messageText,
      timestamp: DateTime.now(),
      type: 'chat',
      isRead: false,
    );

    await _notificationRepo.addNotification(item);
  }

  /// Canlı yürüyüş başladığında köpek sahibine anlık bildirim düşürür.
  Future<void> notifyWalkStarted({
    required String ownerUserId,
    required String petName,
    required String sitterName,
  }) async {
    final item = NotificationItem(
      id: 'notif_walk_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Yürüyüş Başladı! 🦮',
      body: '$sitterName ve $petName Caddebostan sahilinde yürüyüşe çıktı. Canlı haritadan anlık takip edebilirsiniz.',
      timestamp: DateTime.now(),
      type: 'walk',
      isRead: false,
    );

    await _notificationRepo.addNotification(item);
  }

  void dispose() {
    _foregroundSubscription?.cancel();
  }
}
