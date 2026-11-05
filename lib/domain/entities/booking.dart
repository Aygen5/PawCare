import 'package:cloud_firestore/cloud_firestore.dart';

/// Rezervasyon durumunu temsil eden enum.
enum BookingStatus { pending, confirmed, rejected, completed }

/// Rezervasyon talebini ve detaylarını temsil eden saf iş alanı varlığı (Entity).
class BookingRequest {
  final String id;
  final String? ownerId;
  final String? dogId;
  final String sitterId;
  final String sitterName;
  final String sitterPhoto;
  final String petName;
  final String petBreed;
  final String serviceTitle;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String careNotes;
  final BookingStatus status;
  final DateTime? createdAt;

  const BookingRequest({
    required this.id,
    this.ownerId,
    this.dogId,
    required this.sitterId,
    required this.sitterName,
    required this.sitterPhoto,
    required this.petName,
    required this.petBreed,
    required this.serviceTitle,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.careNotes,
    this.status = BookingStatus.pending,
    this.createdAt,
  });

  BookingRequest copyWith({
    String? id,
    String? ownerId,
    String? dogId,
    String? sitterId,
    String? sitterName,
    String? sitterPhoto,
    String? petName,
    String? petBreed,
    String? serviceTitle,
    DateTime? startDate,
    DateTime? endDate,
    double? totalPrice,
    String? careNotes,
    BookingStatus? status,
    DateTime? createdAt,
  }) {
    return BookingRequest(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      dogId: dogId ?? this.dogId,
      sitterId: sitterId ?? this.sitterId,
      sitterName: sitterName ?? this.sitterName,
      sitterPhoto: sitterPhoto ?? this.sitterPhoto,
      petName: petName ?? this.petName,
      petBreed: petBreed ?? this.petBreed,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalPrice: totalPrice ?? this.totalPrice,
      careNotes: careNotes ?? this.careNotes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'dogId': dogId,
      'sitterId': sitterId,
      'sitterName': sitterName,
      'sitterPhoto': sitterPhoto,
      'petName': petName,
      'petBreed': petBreed,
      'serviceTitle': serviceTitle,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalPrice': totalPrice,
      'careNotes': careNotes,
      'status': status.name,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory BookingRequest.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return BookingRequest(
      id: docId ?? (map['id'] as String? ?? ''),
      ownerId: map['ownerId'] as String?,
      dogId: map['dogId'] as String?,
      sitterId: map['sitterId'] as String? ?? '',
      sitterName: map['sitterName'] as String? ?? '',
      sitterPhoto: map['sitterPhoto'] as String? ?? '',
      petName: map['petName'] as String? ?? '',
      petBreed: map['petBreed'] as String? ?? '',
      serviceTitle: map['serviceTitle'] as String? ?? '',
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      careNotes: map['careNotes'] as String? ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : null,
    );
  }
}
