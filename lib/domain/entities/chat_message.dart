import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'user_role.dart';

/// Bakıcı ve köpek sahibi arasındaki mesajlaşma kaydını temsil eden saf iş alanı varlığı (Entity).
class ChatMessage {
  final String id;
  final String? chatId;
  final String? senderId;
  final String? receiverId;
  final String senderName;
  final String text;
  final String time;
  final DateTime timestamp;
  final bool isMe;
  final bool isRead;
  final String? mediaUrl;
  final UserRole? senderRole;

  ChatMessage({
    required this.id,
    this.chatId,
    this.senderId,
    this.receiverId,
    required this.senderName,
    required this.text,
    String? time,
    DateTime? timestamp,
    this.isMe = false,
    this.isRead = false,
    this.mediaUrl,
    this.senderRole,
  })  : timestamp = timestamp ?? DateTime.now(),
        time = time ?? DateFormat('HH:mm').format(timestamp ?? DateTime.now());

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? senderName,
    String? text,
    String? time,
    DateTime? timestamp,
    bool? isMe,
    bool? isRead,
    String? mediaUrl,
    UserRole? senderRole,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      time: time ?? this.time,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      isRead: isRead ?? this.isRead,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      senderRole: senderRole ?? this.senderRole,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (chatId != null) 'chatId': chatId,
      if (senderId != null) 'senderId': senderId,
      if (receiverId != null) 'receiverId': receiverId,
      'senderName': senderName,
      'text': text,
      'time': time,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (senderRole != null) 'senderRole': senderRole!.name,
    };
  }

  factory ChatMessage.fromMap(
    Map<String, dynamic> map, [
    String? docId,
    String? currentUserId,
  ]) {
    DateTime parsedTime;
    final rawTime = map['timestamp'];
    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate();
    } else if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
    } else if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    final senderId = map['senderId'] as String?;
    final isMe = currentUserId != null && senderId != null
        ? senderId == currentUserId
        : (map['isMe'] as bool? ?? false);

    UserRole? role;
    if (map['senderRole'] != null) {
      final roleStr = map['senderRole'].toString().toLowerCase();
      if (roleStr == 'sitter') {
        role = UserRole.sitter;
      } else if (roleStr == 'owner') {
        role = UserRole.owner;
      }
    }

    return ChatMessage(
      id: docId ?? map['id'] ?? '',
      chatId: map['chatId'] as String?,
      senderId: senderId,
      receiverId: map['receiverId'] as String?,
      senderName: map['senderName'] as String? ?? 'Kullanıcı',
      text: map['text'] as String? ?? '',
      time: map['time'] as String? ?? DateFormat('HH:mm').format(parsedTime),
      timestamp: parsedTime,
      isMe: isMe,
      isRead: map['isRead'] as bool? ?? false,
      mediaUrl: map['mediaUrl'] as String?,
      senderRole: role,
    );
  }
}
