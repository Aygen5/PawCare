// ignore_for_file: annotate_overrides

import 'package:hive/hive.dart';

import '../../domain/entities/booking.dart' show BookingStatus;
import '../../domain/entities/entities.dart' as entity;
import '../../domain/entities/user_role.dart' show UserRole;
import '../../domain/entities/vaccination.dart' show VaccineStatus;

export '../../domain/entities/booking.dart' show BookingStatus;
export '../../domain/entities/user_role.dart' show UserRole;
export '../../domain/entities/vaccination.dart' show VaccineStatus;

part 'models.g.dart';

@HiveType(typeId: 2)
class Vaccination extends HiveObject implements entity.Vaccination {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String dueDate;

  @HiveField(3)
  final VaccineStatus status;

  @HiveField(4)
  final String vetName;

  @HiveField(5)
  final String? completionDate;

  Vaccination({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.vetName,
    this.completionDate,
  });

  Vaccination copyWith({
    String? id,
    String? title,
    String? dueDate,
    VaccineStatus? status,
    String? vetName,
    String? completionDate,
  }) {
    return Vaccination(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      vetName: vetName ?? this.vetName,
      completionDate: completionDate ?? this.completionDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate,
      'status': status.name,
      'vetName': vetName,
      'completionDate': completionDate,
    };
  }

  @override
  Map<String, dynamic> toMap() => toJson();

  factory Vaccination.fromJson(Map<String, dynamic> json) {
    return Vaccination(
      id: json['id'] as String,
      title: json['title'] as String,
      dueDate: json['dueDate'] as String,
      status: VaccineStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VaccineStatus.upcoming,
      ),
      vetName: json['vetName'] as String,
      completionDate: json['completionDate'] as String?,
    );
  }

  factory Vaccination.fromEntity(entity.Vaccination v) {
    if (v is Vaccination) return v;
    return Vaccination(
      id: v.id,
      title: v.title,
      dueDate: v.dueDate,
      status: v.status,
      vetName: v.vetName,
      completionDate: v.completionDate,
    );
  }
}

@HiveType(typeId: 3)
class Dog extends HiveObject implements entity.Dog {
  @override
  String? get ownerId => null;

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String breed;

  @HiveField(3)
  final int ageYears;

  @HiveField(4)
  final double weightKg;

  @HiveField(5)
  final String gender;

  @HiveField(6)
  final String microchip;

  @HiveField(7)
  final String photoPath;

  @HiveField(8)
  final String allergyNote;

  @HiveField(9)
  final String behaviorNote;

  @HiveField(10)
  final String clinicName;

  @HiveField(11)
  final String clinicPhone;

  @HiveField(12)
  final List<Vaccination> vaccinations;

  Dog({
    required this.id,
    required this.name,
    required this.breed,
    required this.ageYears,
    required this.weightKg,
    required this.gender,
    required this.microchip,
    required this.photoPath,
    required this.allergyNote,
    required this.behaviorNote,
    required this.clinicName,
    required this.clinicPhone,
    required this.vaccinations,
  });

  Dog copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? breed,
    int? ageYears,
    double? weightKg,
    String? gender,
    String? microchip,
    String? photoPath,
    String? allergyNote,
    String? behaviorNote,
    String? clinicName,
    String? clinicPhone,
    covariant List<entity.Vaccination>? vaccinations,
  }) {
    return Dog(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      ageYears: ageYears ?? this.ageYears,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      microchip: microchip ?? this.microchip,
      photoPath: photoPath ?? this.photoPath,
      allergyNote: allergyNote ?? this.allergyNote,
      behaviorNote: behaviorNote ?? this.behaviorNote,
      clinicName: clinicName ?? this.clinicName,
      clinicPhone: clinicPhone ?? this.clinicPhone,
      vaccinations: vaccinations != null
          ? vaccinations
              .map((v) => v is Vaccination ? v : Vaccination.fromEntity(v))
              .toList()
          : this.vaccinations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'ageYears': ageYears,
      'weightKg': weightKg,
      'gender': gender,
      'microchip': microchip,
      'photoPath': photoPath,
      'allergyNote': allergyNote,
      'behaviorNote': behaviorNote,
      'clinicName': clinicName,
      'clinicPhone': clinicPhone,
      'vaccinations': vaccinations.map((v) => v.toJson()).toList(),
    };
  }

  @override
  Map<String, dynamic> toMap() => toJson();

  factory Dog.fromJson(Map<String, dynamic> json) {
    return Dog(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: json['breed'] as String,
      ageYears: (json['ageYears'] as num).toInt(),
      weightKg: (json['weightKg'] as num).toDouble(),
      gender: json['gender'] as String,
      microchip: json['microchip'] as String,
      photoPath: json['photoPath'] as String,
      allergyNote: json['allergyNote'] as String,
      behaviorNote: json['behaviorNote'] as String,
      clinicName: json['clinicName'] as String,
      clinicPhone: json['clinicPhone'] as String,
      vaccinations:
          (json['vaccinations'] as List<dynamic>?)
              ?.map((v) => Vaccination.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory Dog.fromEntity(entity.Dog dog) {
    if (dog is Dog) return dog;
    return Dog(
      id: dog.id,
      name: dog.name,
      breed: dog.breed,
      ageYears: dog.ageYears,
      weightKg: dog.weightKg,
      gender: dog.gender,
      microchip: dog.microchip,
      photoPath: dog.photoPath,
      allergyNote: dog.allergyNote,
      behaviorNote: dog.behaviorNote,
      clinicName: dog.clinicName,
      clinicPhone: dog.clinicPhone,
      vaccinations: dog.vaccinations
          .map((v) => Vaccination.fromEntity(v))
          .toList(),
    );
  }
}

@HiveType(typeId: 4)
class SitterListing extends HiveObject implements entity.SitterListing {
  @override
  String? get userId => null;

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String facilityTitle;

  @HiveField(3)
  final String category; // 'Köpek Oteli', 'Köpek Gezdirme', 'Gündüz Bakımı'

  @HiveField(4)
  final double rating;

  @HiveField(5)
  final int reviewsCount;

  @HiveField(6)
  final double pricePerUnit;

  @HiveField(7)
  final String unitLabel; // 'gece', 'saat', 'gün'

  @HiveField(8)
  final String location;

  @HiveField(9)
  final double distanceKm;

  @HiveField(10)
  final String imagePath;

  @HiveField(11)
  final List<String> galleryPaths;

  @HiveField(12)
  final String bio;

  @HiveField(13)
  final List<String> amenities;

  @HiveField(14)
  final bool isVerified;

  SitterListing({
    required this.id,
    required this.name,
    required this.facilityTitle,
    required this.category,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerUnit,
    required this.unitLabel,
    required this.location,
    required this.distanceKm,
    required this.imagePath,
    required this.galleryPaths,
    required this.bio,
    required this.amenities,
    this.isVerified = true,
  });

  SitterListing copyWith({
    String? id,
    String? userId,
    String? name,
    String? facilityTitle,
    String? category,
    double? rating,
    int? reviewsCount,
    double? pricePerUnit,
    String? unitLabel,
    String? location,
    double? distanceKm,
    String? imagePath,
    List<String>? galleryPaths,
    String? bio,
    List<String>? amenities,
    bool? isVerified,
  }) {
    return SitterListing(
      id: id ?? this.id,
      name: name ?? this.name,
      facilityTitle: facilityTitle ?? this.facilityTitle,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      unitLabel: unitLabel ?? this.unitLabel,
      location: location ?? this.location,
      distanceKm: distanceKm ?? this.distanceKm,
      imagePath: imagePath ?? this.imagePath,
      galleryPaths: galleryPaths ?? this.galleryPaths,
      bio: bio ?? this.bio,
      amenities: amenities ?? this.amenities,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'facilityTitle': facilityTitle,
      'category': category,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'pricePerUnit': pricePerUnit,
      'unitLabel': unitLabel,
      'location': location,
      'distanceKm': distanceKm,
      'imagePath': imagePath,
      'galleryPaths': galleryPaths,
      'bio': bio,
      'amenities': amenities,
      'isVerified': isVerified,
    };
  }

  @override
  Map<String, dynamic> toMap() => toJson();

  factory SitterListing.fromJson(Map<String, dynamic> json) {
    return SitterListing(
      id: json['id'] as String,
      name: json['name'] as String,
      facilityTitle: json['facilityTitle'] as String,
      category: json['category'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewsCount: (json['reviewsCount'] as num).toInt(),
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      unitLabel: json['unitLabel'] as String,
      location: json['location'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      imagePath: json['imagePath'] as String,
      galleryPaths:
          (json['galleryPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bio: json['bio'] as String,
      amenities:
          (json['amenities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isVerified: json['isVerified'] as bool? ?? true,
    );
  }

  factory SitterListing.fromEntity(entity.SitterListing s) {
    if (s is SitterListing) return s;
    return SitterListing(
      id: s.id,
      name: s.name,
      facilityTitle: s.facilityTitle,
      category: s.category,
      rating: s.rating,
      reviewsCount: s.reviewsCount,
      pricePerUnit: s.pricePerUnit,
      unitLabel: s.unitLabel,
      location: s.location,
      distanceKm: s.distanceKm,
      imagePath: s.imagePath,
      galleryPaths: s.galleryPaths,
      bio: s.bio,
      amenities: s.amenities,
      isVerified: s.isVerified,
    );
  }
}

@HiveType(typeId: 6)
class BookingRequest extends HiveObject implements entity.BookingRequest {
  @override
  String? get ownerId => null;

  @override
  String? get dogId => null;

  @override
  DateTime? get createdAt => null;

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sitterId;

  @HiveField(2)
  final String sitterName;

  @HiveField(3)
  final String sitterPhoto;

  @HiveField(4)
  final String petName;

  @HiveField(5)
  final String petBreed;

  @HiveField(6)
  final String serviceTitle;

  @HiveField(7)
  final DateTime startDate;

  @HiveField(8)
  final DateTime endDate;

  @HiveField(9)
  final double totalPrice;

  @HiveField(10)
  final String careNotes;

  @HiveField(11)
  BookingStatus status;

  BookingRequest({
    required this.id,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sitterId': sitterId,
      'sitterName': sitterName,
      'sitterPhoto': sitterPhoto,
      'petName': petName,
      'petBreed': petBreed,
      'serviceTitle': serviceTitle,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalPrice': totalPrice,
      'careNotes': careNotes,
      'status': status.name,
    };
  }

  @override
  Map<String, dynamic> toMap() => toJson();

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      id: json['id'] as String,
      sitterId: json['sitterId'] as String,
      sitterName: json['sitterName'] as String,
      sitterPhoto: json['sitterPhoto'] as String,
      petName: json['petName'] as String,
      petBreed: json['petBreed'] as String,
      serviceTitle: json['serviceTitle'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      careNotes: json['careNotes'] as String,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
    );
  }

  factory BookingRequest.fromEntity(entity.BookingRequest b) {
    if (b is BookingRequest) return b;
    return BookingRequest(
      id: b.id,
      sitterId: b.sitterId,
      sitterName: b.sitterName,
      sitterPhoto: b.sitterPhoto,
      petName: b.petName,
      petBreed: b.petBreed,
      serviceTitle: b.serviceTitle,
      startDate: b.startDate,
      endDate: b.endDate,
      totalPrice: b.totalPrice,
      careNotes: b.careNotes,
      status: b.status,
    );
  }
}

@HiveType(typeId: 7)
class ChatMessage extends HiveObject implements entity.ChatMessage {
  @override
  @HiveField(0)
  final String id;

  @override
  @HiveField(1)
  final String senderName;

  @override
  @HiveField(2)
  final String text;

  @override
  @HiveField(3)
  final String time;

  @override
  @HiveField(4)
  final bool isMe;

  @override
  final UserRole? senderRole;

  @override
  @HiveField(5)
  final String? chatId;

  @override
  @HiveField(6)
  final String? senderId;

  @override
  @HiveField(7)
  final String? receiverId;

  @override
  @HiveField(8)
  final DateTime timestamp;

  @override
  @HiveField(9)
  final bool isRead;

  @override
  @HiveField(10)
  final String? mediaUrl;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.time,
    required this.isMe,
    this.senderRole,
    this.chatId,
    this.senderId,
    this.receiverId,
    DateTime? timestamp,
    this.isRead = false,
    this.mediaUrl,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
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

  @override
  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'text': text,
      'time': time,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isMe': isMe,
      'isRead': isRead,
      'mediaUrl': mediaUrl,
      if (senderRole != null) 'senderRole': senderRole!.name,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      chatId: json['chatId'] as String?,
      senderId: json['senderId'] as String?,
      receiverId: json['receiverId'] as String?,
      senderName: json['senderName'] as String? ?? '',
      text: json['text'] as String? ?? '',
      time: json['time'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      isMe: json['isMe'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      mediaUrl: json['mediaUrl'] as String?,
    );
  }
}

@HiveType(typeId: 8)
class NotificationItem extends HiveObject implements entity.NotificationItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final bool isRead;

  @HiveField(5)
  final String type; // 'booking', 'vaccine', 'chat', 'system'

  NotificationItem({
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

  @override
  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: json['type'] as String? ?? 'system',
    );
  }
}
