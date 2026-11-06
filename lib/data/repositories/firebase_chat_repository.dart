import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository_interface.dart';

/// Cloud Firestore tabanlı gerçek zamanlı birebir sohbet deposu.
/// `chats/{chatId}/messages/{messageId}` koleksiyon yapısı ile çalışır.
/// Çevrimdışı ve test senaryoları için yerel bellek (in-memory) desteği barındırır.
class FirebaseChatRepository implements ChatRepositoryInterface {
  final FirebaseFirestore? _firestoreInstance;
  final FirebaseAuth? _firebaseAuthInstance;
  final Map<String, List<ChatMessage>> _inMemoryMessages = {};
  final Map<String, StreamController<List<ChatMessage>>> _inMemoryControllers = {};

  FirebaseChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestoreInstance = firestore,
        _firebaseAuthInstance = firebaseAuth;

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

  String? get currentUserId {
    try {
      return _firebaseAuth?.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  StreamController<List<ChatMessage>> _getOrCreateController(String chatId) {
    return _inMemoryControllers.putIfAbsent(
      chatId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    final fs = _firestore;
    final uid = currentUserId;

    if (fs != null) {
      try {
        return fs
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .snapshots()
            .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return ChatMessage.fromMap(doc.data(), doc.id, uid);
          }).toList();

          // Yerel önbelleği güncelle
          _inMemoryMessages[chatId] = list;
          return list;
        }).handleError((error) {
          debugPrint('watchMessages error, falling back to memory: $error');
          return _inMemoryMessages[chatId] ?? [];
        });
      } catch (e) {
        debugPrint('watchMessages init error: $e');
      }
    }

    // In-Memory Fallback
    final controller = _getOrCreateController(chatId);
    if (_inMemoryMessages.containsKey(chatId)) {
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(_inMemoryMessages[chatId]!);
        }
      });
    }
    return controller.stream;
  }

  @override
  Future<List<ChatMessage>> getMessages(String chatId) async {
    final fs = _firestore;
    final uid = currentUserId;

    if (fs != null) {
      try {
        final snapshot = await fs
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs.map((doc) {
            return ChatMessage.fromMap(doc.data(), doc.id, uid);
          }).toList();
          _inMemoryMessages[chatId] = list;
          return list;
        }
      } catch (e) {
        debugPrint('getMessages error: $e');
      }
    }

    return _inMemoryMessages[chatId] ?? [];
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required ChatMessage message,
  }) async {
    // 1. Yerel durumu güncelle
    final currentList = List<ChatMessage>.from(_inMemoryMessages[chatId] ?? []);
    currentList.add(message);
    _inMemoryMessages[chatId] = currentList;
    _getOrCreateController(chatId).add(currentList);

    // 2. Cloud Firestore'a yaz
    final fs = _firestore;
    if (fs != null) {
      try {
        final chatDoc = fs.collection('chats').doc(chatId);
        
        // Üst sohbet meta bilgisini güncelle
        await chatDoc.set({
          'chatId': chatId,
          'lastMessage': message.text,
          'lastSenderId': message.senderId ?? currentUserId,
          'lastSenderName': message.senderName,
          'updatedAt': message.timestamp.millisecondsSinceEpoch,
        }, SetOptions(merge: true));

        // Alt mesaj koleksiyonuna ekle
        await chatDoc.collection('messages').doc(message.id).set(message.toMap());
      } catch (e) {
        debugPrint('sendMessage firestore error: $e');
      }
    }
  }

  @override
  Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    // Yerel okundu güncellemesi
    final list = _inMemoryMessages[chatId];
    if (list != null) {
      final updated = list.map((m) {
        if (m.senderId != currentUserId && !m.isRead) {
          return m.copyWith(isRead: true);
        }
        return m;
      }).toList();
      _inMemoryMessages[chatId] = updated;
      _getOrCreateController(chatId).add(updated);
    }

    final fs = _firestore;
    if (fs != null) {
      try {
        final unreadDocs = await fs
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .get();

        final batch = fs.batch();
        for (final doc in unreadDocs.docs) {
          if (doc.data()['senderId'] != currentUserId) {
            batch.update(doc.reference, {'isRead': true});
          }
        }
        await batch.commit();
      } catch (e) {
        debugPrint('markMessagesAsRead error: $e');
      }
    }
  }
}
