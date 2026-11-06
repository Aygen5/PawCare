import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/firebase_chat_repository.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/user_role.dart';
import '../../../domain/repositories/chat_repository_interface.dart';

class ChatState {
  final Map<String, List<ChatMessage>> conversations;
  final bool isLoading;
  final String? activeChatId;

  const ChatState({
    this.conversations = const {},
    this.isLoading = false,
    this.activeChatId,
  });

  List<ChatMessage> getMessagesFor(String participantName, UserRole role) {
    final list =
        conversations[participantName] ?? _defaultMessages(participantName);
    // Rol bazlı 'isMe' hizalaması
    return list.map((m) {
      if (m.senderRole != null) {
        return m.copyWith(isMe: m.senderRole == role);
      }
      return m;
    }).toList();
  }

  ChatState copyWith({
    Map<String, List<ChatMessage>>? conversations,
    bool? isLoading,
    String? activeChatId,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      activeChatId: activeChatId ?? this.activeChatId,
    );
  }

  static List<ChatMessage> _defaultMessages(String name) {
    return [
      ChatMessage(
        id: 'msg_1',
        senderName: name,
        text:
            'Merhaba! Yürüyüş için Caddebostan sahilindeyiz, her şey harika gidiyor 🐾',
        time: '14:15',
        isMe: false,
        senderRole: UserRole.sitter,
      ),
      ChatMessage(
        id: 'msg_2',
        senderName: 'Aygen Y.',
        text:
            'Harika görünüyor, Barley çok mutlu görünüyor! Bol su vermeyi unutmayın lütfen 😊',
        time: '14:18',
        isMe: true,
        senderRole: UserRole.owner,
      ),
      ChatMessage(
        id: 'msg_3',
        senderName: name,
        text: 'Merak etmeyin, gölgede kısa bir su molası verdik bile!',
        time: '14:22',
        isMe: false,
        senderRole: UserRole.sitter,
      ),
    ];
  }
}

class ChatCubit extends Cubit<ChatState> {
  final ChatRepositoryInterface chatRepository;
  StreamSubscription<List<ChatMessage>>? _chatSubscription;

  ChatCubit({ChatRepositoryInterface? chatRepository})
      : chatRepository = chatRepository ?? FirebaseChatRepository(),
        super(
          ChatState(
            conversations: {
              'Mert Demir': ChatState._defaultMessages('Mert Demir'),
              'Ayşe Yılmaz': ChatState._defaultMessages('Ayşe Yılmaz'),
            },
          ),
        );

  /// Gerçek zamanlı Firestore akışını başlatır
  void initChatStream({
    required String chatId,
    required String participantName,
    required UserRole currentRole,
  }) {
    emit(state.copyWith(isLoading: true, activeChatId: chatId));

    _chatSubscription?.cancel();
    _chatSubscription = chatRepository.watchMessages(chatId).listen(
      (remoteMessages) {
        final currentMap =
            Map<String, List<ChatMessage>>.from(state.conversations);

        if (remoteMessages.isNotEmpty) {
          currentMap[participantName] = remoteMessages;
        } else if (!currentMap.containsKey(participantName)) {
          currentMap[participantName] =
              ChatState._defaultMessages(participantName);
        }

        emit(state.copyWith(conversations: currentMap, isLoading: false));
      },
      onError: (_) {
        emit(state.copyWith(isLoading: false));
      },
    );
  }

  /// Yeni mesaj gönderir ve Firestore'a kalıcı olarak yazar
  Future<void> sendMessage(
    String text, {
    required String participantName,
    required UserRole currentRole,
    String? chatId,
    String? senderId,
    String? receiverId,
  }) async {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final senderName =
        currentRole == UserRole.sitter ? participantName : 'Aygen Y.';
    final effectiveChatId =
        chatId ?? state.activeChatId ?? 'chat_${participantName.replaceAll(' ', '_').toLowerCase()}';

    final newMsg = ChatMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      chatId: effectiveChatId,
      senderId: senderId,
      receiverId: receiverId,
      senderName: senderName,
      text: text,
      time: timeStr,
      timestamp: now,
      isMe: true,
      senderRole: currentRole,
    );

    // Yerel durumu anında güncelle (optimistic update)
    final currentList =
        List<ChatMessage>.from(state.conversations[participantName] ?? []);
    currentList.add(newMsg);

    final updatedMap = Map<String, List<ChatMessage>>.from(state.conversations);
    updatedMap[participantName] = currentList;

    emit(state.copyWith(conversations: updatedMap));

    // Firestore'a kalıcı yaz
    await chatRepository.sendMessage(
      chatId: effectiveChatId,
      message: newMsg,
    );
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
