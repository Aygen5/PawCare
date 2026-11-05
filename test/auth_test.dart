import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/data/repositories/in_memory_auth_repository.dart';
import 'package:paw_care/domain/entities/user_role.dart';
import 'package:paw_care/features/auth/cubit/auth_cubit.dart';

void main() {
  group('Firebase & Clean Architecture Auth Testleri', () {
    late InMemoryAuthRepository authRepository;
    late AuthCubit authCubit;

    setUp(() {
      authRepository = InMemoryAuthRepository();
      authCubit = AuthCubit(authRepository: authRepository);
    });

    tearDown(() {
      authCubit.close();
      authRepository.dispose();
    });

    test('Başlangıç durumu kimlik doğrulanmamış olmalıdır', () {
      expect(authCubit.state.isAuthenticated, isFalse);
      expect(authCubit.state.user, isNull);
    });

    test('Geçersiz e-posta adresi ile giriş reddedilmelidir', () async {
      final success = await authCubit.login(
        email: 'gecersiz-eposta',
        password: '12345678',
      );

      expect(success, isFalse);
      expect(authCubit.state.isAuthenticated, isFalse);
      expect(authCubit.state.errorMessage, contains('geçerli bir e-posta'));
    });

    test('6 karakterden kısa şifre ile giriş reddedilmelidir', () async {
      final success = await authCubit.login(
        email: 'aygen@pawcare.com',
        password: '123',
      );

      expect(success, isFalse);
      expect(authCubit.state.errorMessage, contains('en az 6 karakter'));
    });

    test('Doğru bilgilerle e-posta/şifre girişi başarılı olmalı ve durumu güncellenmelidir', () async {
      final success = await authCubit.login(
        email: 'aygen@pawcare.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(authCubit.state.isAuthenticated, isTrue);
      expect(authCubit.state.userEmail, 'aygen@pawcare.com');
      expect(authCubit.state.role, UserRole.owner);
    });

    test('Kayıt olma akışı yeni kullanıcı oluşturmalı ve oturumu açmalıdır', () async {
      final success = await authCubit.signUp(
        name: 'Ayşe Yılmaz',
        email: 'ayse@pawcare.com',
        password: 'password123',
        role: UserRole.sitter,
      );

      expect(success, isTrue);
      expect(authCubit.state.isAuthenticated, isTrue);
      expect(authCubit.state.userName, 'Ayşe Yılmaz');
      expect(authCubit.state.role, UserRole.sitter);
    });

    test('Çıkış yapıldığında oturum durumu sıfırlanmalıdır', () async {
      await authCubit.login(
        email: 'aygen@pawcare.com',
        password: 'password123',
      );
      expect(authCubit.state.isAuthenticated, isTrue);

      await authCubit.logout();
      expect(authCubit.state.isAuthenticated, isFalse);
      expect(authCubit.state.user, isNull);
    });
  });
}

