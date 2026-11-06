import '../entities/chat_message.dart';

/// Canlı sohbet ve mesajlaşma repository sözleşmesi.
abstract class ChatRepositoryInterface {
  /// Belirtilen sohbete ait mesajları gerçek zamanlı (Stream) dinler.
  Stream<List<ChatMessage>> watchMessages(String chatId);

  /// Belirtilen sohbete ait mesajları tek seferlik çeker.
  Future<List<ChatMessage>> getMessages(String chatId);

  /// Sohbete yeni bir mesaj gönderir ve Firestore'a yazar.
  Future<void> sendMessage({
    required String chatId,
    required ChatMessage message,
  });

  /// Karşı taraftan gelen okunmamış mesajları okundu olarak işaretler.
  Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  });
}
