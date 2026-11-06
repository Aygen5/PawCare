import 'package:cloud_firestore/cloud_firestore.dart';

/// Sistem ve kullanıcı bildirimini temsil eden saf iş alanı varlığı (Entity).
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'booking', 'vaccine', 'chat', 'system', 'walk'

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type = 'system',
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    String? type,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': type,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    return NotificationItem(
      id: docId ?? map['id'] ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      timestamp: parsedTime,
      isRead: map['isRead'] as bool? ?? false,
      type: map['type'] as String? ?? 'system',
    );
  }
}
