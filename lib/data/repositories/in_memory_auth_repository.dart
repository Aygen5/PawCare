import 'dart:async';

import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository_interface.dart';

/// Testler ve çevrimdışı çalışma senaryoları için in-memory Auth repository.
class InMemoryAuthRepository implements AuthRepositoryInterface {
  final _controller = StreamController<UserEntity?>.broadcast();
  UserEntity? _current;

  InMemoryAuthRepository({UserEntity? initialUser}) : _current = initialUser;

  @override
  Stream<UserEntity?> get authStateChanges => _controller.stream;

  @override
  UserEntity? get currentUser => _current;

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final role = email.contains('ayse') ? UserRole.sitter : UserRole.owner;
    final user = UserEntity(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: role == UserRole.sitter ? 'Ayşe Yılmaz' : 'Aygen Y.',
      role: role,
    );
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    final user = UserEntity(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: fullName,
      role: role,
      createdAt: DateTime.now(),
    );
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // In-memory no-op
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    _current = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

