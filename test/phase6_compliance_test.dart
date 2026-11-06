import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/data/repositories/in_memory_auth_repository.dart';
import 'package:paw_care/domain/entities/user_entity.dart';
import 'package:paw_care/domain/entities/user_role.dart';
import 'package:paw_care/features/auth/cubit/auth_cubit.dart';

void main() {
  group('Faz 6.4: Apple Guideline 5.1.1 & Mağaza Uyumluluk Testleri', () {
    test('InMemoryAuthRepository deleteAccount() kullanıcı oturumunu ve verisini sıfırlamalıdır', () async {
      final user = UserEntity(
        uid: 'user_delete_123',
        email: 'test@pawcare.com',
        displayName: 'Test Kullanıcı',
        role: UserRole.owner,
      );

      final repo = InMemoryAuthRepository(initialUser: user);
      expect(repo.currentUser, isNotNull);
      expect(repo.currentUser?.uid, 'user_delete_123');

      await repo.deleteAccount();

      expect(repo.currentUser, isNull);
    });

    test('AuthCubit deleteAccount() başarı durumunda oturumu kapatmalı ve state güncellemelidir', () async {
      final user = UserEntity(
        uid: 'user_delete_456',
        email: 'barley@pawcare.com',
        displayName: 'Barley Sahibi',
        role: UserRole.owner,
      );

      final repo = InMemoryAuthRepository(initialUser: user);
      final cubit = AuthCubit(authRepository: repo);

      // Başlangıçta giriş yapalım
      await cubit.login(email: 'barley@pawcare.com', password: 'password123');
      expect(cubit.state.isAuthenticated, isTrue);

      // Hesabı kalıcı olarak sil
      final result = await cubit.deleteAccount();
      expect(result, isTrue);
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.user, isNull);

      await cubit.close();
    });
  });
}
