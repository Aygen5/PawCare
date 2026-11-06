import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository_interface.dart';
import '../local/hive_boxes.dart';
import '../models/models.dart' as model;
import 'notification_repository.dart';

/// Cloud Firestore destekli bildirim deposu.
/// `users/{userId}/notifications/{notificationId}` koleksiyonunda çalışır.
/// Çevrimdışı ve test senaryoları için yerel `NotificationRepository` (Hive) ve in-memory fallback'e sahiptir.
class FirebaseNotificationRepository implements NotificationRepositoryInterface {
  final FirebaseFirestore? _firestoreInstance;
  final FirebaseAuth? _firebaseAuthInstance;
  final NotificationRepository _localRepo;
  final Map<String, NotificationItem> _inMemoryItems = {};
  final StreamController<List<NotificationItem>> _inMemoryController =
      StreamController<List<NotificationItem>>.broadcast();

  FirebaseNotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    NotificationRepository? localRepo,
  })  : _firestoreInstance = firestore,
        _firebaseAuthInstance = firebaseAuth,
        _localRepo = localRepo ?? NotificationRepository();

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  FirebaseAuth? get _firebaseAuth {
    if (_firebaseAuthInstance != null) return _firebaseAuthInstance;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (_) {}
    return null;
  }

  String? get _currentUserId {
    try {
      return _firebaseAuth?.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  bool get _isHiveOpen {
    try {
      return Hive.isBoxOpen(HiveBoxes.notificationsBox);
    } catch (_) {
      return false;
    }
  }

  model.NotificationItem _toModel(NotificationItem item) {
    return model.NotificationItem(
      id: item.id,
      title: item.title,
      body: item.body,
      timestamp: item.timestamp,
      isRead: item.isRead,
      type: item.type,
    );
  }

  void _emitInMemory() {
    final list = _inMemoryItems.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (!_inMemoryController.isClosed) {
      _inMemoryController.add(list);
    }
  }

  @override
  Future<List<NotificationItem>> getNotifications() async {
    // 1. Önce Hive veya yerel bellek
    List<NotificationItem> cached = [];
    if (_isHiveOpen) {
      cached = await _localRepo.getNotifications();
    } else {
      cached = _inMemoryItems.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    // 2. Firestore senkronizasyonu
    try {
      final fs = _firestore;
      final uid = _currentUserId;

      if (fs != null && uid != null && uid.isNotEmpty) {
        final snapshot = await fs
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final remoteList = snapshot.docs.map((doc) {
            return NotificationItem.fromMap(doc.data(), doc.id);
          }).toList();

          // Yerel depoya aktar
          for (final item in remoteList) {
            _inMemoryItems[item.id] = item;
            if (_isHiveOpen) {
              await _localRepo.addNotification(_toModel(item));
            }
          }
          return remoteList;
        }
      }
    } catch (e) {
      debugPrint('getNotifications firestore error: $e');
    }

    return cached;
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final fs = _firestore;
      final uid = _currentUserId;

      if (fs != null && uid != null && uid.isNotEmpty) {
        final snapshot = await fs
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .count()
            .get();

        return snapshot.count ?? 0;
      }
    } catch (_) {}

    if (_isHiveOpen) {
      return await _localRepo.getUnreadCount();
    }
    return _inMemoryItems.values.where((n) => !n.isRead).length;
  }

  @override
  Stream<List<NotificationItem>> watchNotifications() {
    try {
      final fs = _firestore;
      final uid = _currentUserId;

      if (fs != null && uid != null && uid.isNotEmpty) {
        return fs
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return NotificationItem.fromMap(doc.data(), doc.id);
          }).toList();

          for (final n in list) {
            _inMemoryItems[n.id] = n;
            if (_isHiveOpen) {
              _localRepo.addNotification(_toModel(n));
            }
          }
          return list;
        });
      }
    } catch (_) {}

    if (_isHiveOpen) {
      return _localRepo.watchNotifications();
    }

    Future.microtask(() => _emitInMemory());
    return _inMemoryController.stream;
  }

  @override
  Future<void> addNotification(NotificationItem notification) async {
    _inMemoryItems[notification.id] = notification;
    _emitInMemory();

    if (_isHiveOpen) {
      await _localRepo.addNotification(_toModel(notification));
    }

    // Cloud Firestore'a yaz
    try {
      final fs = _firestore;
      final uid = _currentUserId;

      if (fs != null && uid != null && uid.isNotEmpty) {
        await fs
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc(notification.id)
            .set(notification.toMap());
      }
    } catch (e) {
      debugPrint('addNotification firestore error: $e');
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    if (_inMemoryItems.containsKey(id)) {
      _inMemoryItems[id] = _inMemoryItems[id]!.copyWith(isRead: true);
      _emitInMemory();
    }

    if (_isHiveOpen) {
      await _localRepo.markAsRead(id);
    }

    try {
      final fs = _firestore;
      final uid = _currentUserId;

      if (fs != null && uid != null && uid.isNotEmpty) {
        await fs
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc(id)
            .update({'isRead': true});
      }
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead() async {
    for (final key in _inMemoryItems.keys) {
      _inMemoryItems[key] = _inMemoryItems[key]!.copyWith(isRead: true);
    }
    _emitInMemory();

    if (_isHiveOpen) {
      await _localRepo.markAllAsRead();
    }

    try {
      final fs = _firestore;
      final uid = _currentUserId;

      if (fs != null && uid != null && uid.isNotEmpty) {
        final unreadDocs = await fs
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .get();

        final batch = fs.batch();
        for (final doc in unreadDocs.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  @override
  Future<void> clearAll() async {
    _inMemoryItems.clear();
    _emitInMemory();

    if (_isHiveOpen) {
      await _localRepo.clearAll();
    }

    try {
      final fs = _firestore;
      final uid = _currentUserId;

      if (fs != null && uid != null && uid.isNotEmpty) {
        final allDocs = await fs
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .get();

        final batch = fs.batch();
        for (final doc in allDocs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (_) {}
  }
}
