import 'vaccination.dart';

/// Köpek profilini ve sağlık geçmişini temsil eden saf iş alanı varlığı (Entity).
class Dog {
  final String id;
  final String? ownerId;
  final String name;
  final String breed;
  final int ageYears;
  final double weightKg;
  final String gender;
  final String microchip;
  final String photoPath;
  final String allergyNote;
  final String behaviorNote;
  final String clinicName;
  final String clinicPhone;
  final List<Vaccination> vaccinations;

  const Dog({
    required this.id,
    this.ownerId,
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
    List<Vaccination>? vaccinations,
  }) {
    return Dog(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
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
      vaccinations: vaccinations ?? this.vaccinations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
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
      'vaccinations': vaccinations.map((v) => v.toMap()).toList(),
    };
  }

  factory Dog.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Dog(
      id: docId ?? (map['id'] as String? ?? ''),
      ownerId: map['ownerId'] as String?,
      name: map['name'] as String? ?? '',
      breed: map['breed'] as String? ?? '',
      ageYears: (map['ageYears'] as num?)?.toInt() ?? 0,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      gender: map['gender'] as String? ?? 'Erkek',
      microchip: map['microchip'] as String? ?? '',
      photoPath: map['photoPath'] as String? ?? 'assets/images/barley.jpg',
      allergyNote: map['allergyNote'] as String? ?? '',
      behaviorNote: map['behaviorNote'] as String? ?? '',
      clinicName: map['clinicName'] as String? ?? '',
      clinicPhone: map['clinicPhone'] as String? ?? '',
      vaccinations: (map['vaccinations'] as List<dynamic>?)
              ?.map((v) => Vaccination.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
