import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/core/services/phone_call_service.dart';
import 'package:paw_care/data/repositories/firebase_chat_repository.dart';
import 'package:paw_care/data/repositories/firebase_notification_repository.dart';
import 'package:paw_care/domain/entities/chat_message.dart';
import 'package:paw_care/domain/entities/notification.dart';
import 'package:paw_care/domain/entities/user_role.dart';
import 'package:paw_care/features/chat/cubit/chat_cubit.dart';
import 'package:paw_care/features/notifications/cubit/notifications_cubit.dart';

void main() {
  group('Faz 5: Gerçek Zamanlı İletişim, Sesli Arama & Bildirim Testleri', () {
    test('ChatMessage toMap ve fromMap serileştirmesi kayıpsız çalışmalıdır', () {
      final now = DateTime(2026, 11, 6, 10, 30);
      final msg = ChatMessage(
        id: 'msg_101',
        chatId: 'chat_mert_aygen',
        senderId: 'user_aygen',
        receiverId: 'user_mert',
        senderName: 'Aygen Y.',
        text: 'Barley bugün mamasını yedi mi acaba?',
        time: '10:30',
        timestamp: now,
        isMe: true,
        isRead: false,
        senderRole: UserRole.owner,
      );

      final map = msg.toMap();
      expect(map['id'], 'msg_101');
      expect(map['chatId'], 'chat_mert_aygen');
      expect(map['senderId'], 'user_aygen');
      expect(map['receiverId'], 'user_mert');
      expect(map['text'], 'Barley bugün mamasını yedi mi acaba?');
      expect(map['senderRole'], 'owner');

      final reconstructed = ChatMessage.fromMap(map, 'msg_101', 'user_aygen');
      expect(reconstructed.id, 'msg_101');
      expect(reconstructed.senderName, 'Aygen Y.');
      expect(reconstructed.text, msg.text);
      expect(reconstructed.isMe, isTrue);
      expect(reconstructed.senderRole, UserRole.owner);
    });

    test('FirebaseChatRepository mesaj gönderme ve gerçek zamanlı stream akışını yönetmelidir', () async {
      final repo = FirebaseChatRepository();
      const chatId = 'test_chat_room_1';

      final stream = repo.watchMessages(chatId);
      final emitted = <List<ChatMessage>>[];
      final sub = stream.listen((list) => emitted.add(list));

      final msg1 = ChatMessage(
        id: 'm1',
        chatId: chatId,
        senderName: 'Mert Demir',
        text: 'Sahildeyiz, hava çok güzel 🦮',
        time: '12:00',
        isMe: false,
        senderRole: UserRole.sitter,
      );

      await repo.sendMessage(chatId: chatId, message: msg1);
      await Future.delayed(const Duration(milliseconds: 50));

      final messages = await repo.getMessages(chatId);
      expect(messages.length, 1);
      expect(messages.first.text, 'Sahildeyiz, hava çok güzel 🦮');

      final msg2 = ChatMessage(
        id: 'm2',
        chatId: chatId,
        senderName: 'Aygen Y.',
        text: 'Süper, fotoğrafları bekliyorum!',
        time: '12:02',
        isMe: true,
        senderRole: UserRole.owner,
      );

      await repo.sendMessage(chatId: chatId, message: msg2);
      await Future.delayed(const Duration(milliseconds: 50));

      final updatedMessages = await repo.getMessages(chatId);
      expect(updatedMessages.length, 2);

      await sub.cancel();
    });

    test('PhoneCallService telefon numaralarını doğru temizlemelidir', () {
      expect(
        PhoneCallService.cleanPhoneNumber('+90 (532) 890 12 34'),
        '+905328901234',
      );
      expect(
        PhoneCallService.cleanPhoneNumber('0532-890-12-34'),
        '05328901234',
      );
      expect(
        PhoneCallService.cleanPhoneNumber('  +90 555 123 45 67  '),
        '+905551234567',
      );
    });

    test('NotificationItem toMap ve fromMap dönüşümü doğru çalışmalıdır', () {
      final now = DateTime(2026, 11, 6, 11, 0);
      final item = NotificationItem(
        id: 'notif_123',
        title: 'Rezervasyon Onaylandı! 🐾',
        body: 'Mert Demir ile seansınız onaylandı.',
        timestamp: now,
        isRead: false,
        type: 'booking',
      );

      final map = item.toMap();
      expect(map['id'], 'notif_123');
      expect(map['title'], 'Rezervasyon Onaylandı! 🐾');
      expect(map['isRead'], isFalse);
      expect(map['type'], 'booking');

      final reconstructed = NotificationItem.fromMap(map, 'notif_123');
      expect(reconstructed.id, 'notif_123');
      expect(reconstructed.title, item.title);
      expect(reconstructed.body, item.body);
      expect(reconstructed.type, 'booking');
    });

    test('FirebaseNotificationRepository bildirim ekleme ve okundu durumunu güncelleyebilmelidir', () async {
      final repo = FirebaseNotificationRepository();
      final item = NotificationItem(
        id: 'test_n1',
        title: 'Test Bildirimi',
        body: 'Sistem bildirimi gövdesi',
        timestamp: DateTime.now(),
        isRead: false,
        type: 'system',
      );

      await repo.addNotification(item);
      final list = await repo.getNotifications();
      expect(list.any((n) => n.id == 'test_n1'), isTrue);

      await repo.markAsRead('test_n1');
      final updatedList = await repo.getNotifications();
      final target = updatedList.firstWhere((n) => n.id == 'test_n1');
      expect(target.isRead, isTrue);
    });

    test('ChatCubit initChatStream ile gerçek zamanlı mesaj dinleyebilmelidir', () async {
      final repo = FirebaseChatRepository();
      final cubit = ChatCubit(chatRepository: repo);
      const chatId = 'cubit_chat_test';

      cubit.initChatStream(
        chatId: chatId,
        participantName: 'Mert Demir',
        currentRole: UserRole.owner,
      );

      await cubit.sendMessage(
        'Merhaba Mert Bey!',
        chatId: chatId,
        participantName: 'Mert Demir',
        currentRole: UserRole.owner,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final messages = cubit.state.getMessagesFor('Mert Demir', UserRole.owner);
      expect(messages.any((m) => m.text == 'Merhaba Mert Bey!'), isTrue);

      await cubit.close();
    });

    test('NotificationsCubit bildirimleri doğru yüklemeli ve sayacı hesaplamalıdır', () async {
      final repo = FirebaseNotificationRepository();
      final cubit = NotificationsCubit(notificationRepository: repo);

      await cubit.triggerLocalEventNotification(
        title: 'Canlı Yürüyüş Bildirimi',
        body: 'Yürüyüş başladı',
        type: 'walk',
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.allNotifications.isNotEmpty, isTrue);
      expect(cubit.state.unreadCount, greaterThanOrEqualTo(1));

      await cubit.close();
    });
  });
}
