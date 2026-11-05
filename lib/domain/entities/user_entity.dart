import 'user_role.dart';

/// Kimliği doğrulanmış kullanıcıyı temsil eden saf Domain varlığı (Entity).
class UserEntity {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime? createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = UserRole.owner,
    this.photoUrl,
    this.phoneNumber,
    this.createdAt,
  });

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? photoUrl,
    String? phoneNumber,
    DateTime? createdAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map, {String? uid}) {
    final roleStr = map['role'] as String?;
    return UserEntity(
      uid: uid ?? (map['uid'] as String? ?? ''),
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: roleStr == 'sitter' ? UserRole.sitter : UserRole.owner,
      photoUrl: map['photoUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }
}

