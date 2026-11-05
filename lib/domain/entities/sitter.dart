/// Bakıcı ilanını ve hizmet detaylarını temsil eden saf iş alanı varlığı (Entity).
class SitterListing {
  final String id;
  final String? userId;
  final String name;
  final String facilityTitle;
  final String category; // 'Köpek Oteli', 'Köpek Gezdirme', 'Gündüz Bakımı'
  final double rating;
  final int reviewsCount;
  final double pricePerUnit;
  final String unitLabel; // 'gece', 'saat', 'gün'
  final String location;
  final double distanceKm;
  final String imagePath;
  final List<String> galleryPaths;
  final String bio;
  final List<String> amenities;
  final bool isVerified;

  const SitterListing({
    required this.id,
    this.userId,
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
      userId: userId ?? this.userId,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
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

  factory SitterListing.fromMap(Map<String, dynamic> map, {String? docId}) {
    return SitterListing(
      id: docId ?? (map['id'] as String? ?? ''),
      userId: map['userId'] as String?,
      name: map['name'] as String? ?? '',
      facilityTitle: map['facilityTitle'] as String? ?? '',
      category: map['category'] as String? ?? 'Köpek Oteli',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: (map['reviewsCount'] as num?)?.toInt() ?? 0,
      pricePerUnit: (map['pricePerUnit'] as num?)?.toDouble() ?? 500.0,
      unitLabel: map['unitLabel'] as String? ?? 'gece',
      location: map['location'] as String? ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 1.0,
      imagePath: map['imagePath'] as String? ?? 'assets/images/ayse.jpg',
      galleryPaths: List<String>.from(map['galleryPaths'] as List? ?? []),
      bio: map['bio'] as String? ?? '',
      amenities: List<String>.from(map['amenities'] as List? ?? []),
      isVerified: map['isVerified'] as bool? ?? true,
    );
  }
}

/// Hizmet Veren — Sunulan Hizmet Kalemi
class SitterServiceItem {
  final String id;
  final String title;
  final int price;
  final String unit; // '/ gece', '/ gün', '/ saat'
  final String description;

  const SitterServiceItem({
    required this.id,
    required this.title,
    required this.price,
    required this.unit,
    required this.description,
  });

  SitterServiceItem copyWith({
    String? id,
    String? title,
    int? price,
    String? unit,
    String? description,
  }) {
    return SitterServiceItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      description: description ?? this.description,
    );
  }
}

/// Müsaitlik Takvimi Durum Türü
enum CalendarDayStatusType {
  full, // Dolu
  limited, // 1-2 Oda Müsait
  available, // Tamamen Müsait
}

/// Müsaitlik Takvim Günü Modeli
class SitterCalendarDay {
  final String id;
  final String day;
  final String month;
  final String weekday;
  final String status;
  final CalendarDayStatusType statusType;
  final String details;

  const SitterCalendarDay({
    required this.id,
    required this.day,
    required this.month,
    required this.weekday,
    required this.status,
    required this.statusType,
    required this.details,
  });

  SitterCalendarDay copyWith({
    String? id,
    String? day,
    String? month,
    String? weekday,
    String? status,
    CalendarDayStatusType? statusType,
    String? details,
  }) {
    return SitterCalendarDay(
      id: id ?? this.id,
      day: day ?? this.day,
      month: month ?? this.month,
      weekday: weekday ?? this.weekday,
      status: status ?? this.status,
      statusType: statusType ?? this.statusType,
      details: details ?? this.details,
    );
  }
}
