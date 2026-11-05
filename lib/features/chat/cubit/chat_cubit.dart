import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/user_role.dart';

class ChatState {
  final Map<String, List<ChatMessage>> conversations;

  const ChatState({this.conversations = const {}});

  List<ChatMessage> getMessagesFor(String participantName, UserRole role) {
    final list = conversations[participantName] ?? _defaultMessages(participantName);
    // Eğer bakıcı rolündeysek, sahip tarafından atılan mesajlar sol tarafta görünür (isMe tersine döner)
    return list.map((m) {
      if (m.senderRole != null) {
        return m.copyWith(isMe: m.senderRole == role);
      }
      return m;
    }).toList();
  }

  ChatState copyWith({Map<String, List<ChatMessage>>? conversations}) {
    return ChatState(conversations: conversations ?? this.conversations);
  }

  static List<ChatMessage> _defaultMessages(String name) {
    return [
      ChatMessage(
        id: 'msg_1',
        senderName: name,
        text: 'Merhaba! Yürüyüş için Caddebostan sahilindeyiz, her şey harika gidiyor 🐾',
        time: '14:15',
        isMe: false,
        senderRole: UserRole.sitter,
      ),
      const ChatMessage(
        id: 'msg_2',
        senderName: 'Aygen Y.',
        text: 'Harika görünüyor, Barley çok mutlu görünüyor! Bol su vermeyi unutmayın lütfen 😊',
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
  ChatCubit()
      : super(
          ChatState(
            conversations: {
              'Mert Demir': ChatState._defaultMessages('Mert Demir'),
              'Ayşe Yılmaz': ChatState._defaultMessages('Ayşe Yılmaz'),
            },
          ),
        );

  void sendMessage(
    String text, {
    required String participantName,
    required UserRole currentRole,
  }) {
    final timeStr = DateFormat('HH:mm').format(DateTime.now());
    final senderName =
        currentRole == UserRole.sitter ? participantName : 'Aygen Y.';

    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderName: senderName,
      text: text,
      time: timeStr,
      isMe: true,
      senderRole: currentRole,
    );

    final currentList =
        List<ChatMessage>.from(state.conversations[participantName] ?? []);
    currentList.add(newMsg);

    final updatedMap = Map<String, List<ChatMessage>>.from(state.conversations);
    updatedMap[participantName] = currentList;

    emit(state.copyWith(conversations: updatedMap));
  }
}

