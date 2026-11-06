import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care/core/services/crash_reporting_service.dart';

void main() {
  group('Faz 6.3: CrashReportingService Hata ve Çökme İzleme Testleri', () {
    setUp(() {
      CrashReportingService.resetForTesting();
    });

    test('init() servisi doğru şekilde başlatmalıdır', () async {
      expect(CrashReportingService.isInitialized, isFalse);
      await CrashReportingService.init(attachGlobalHandlers: false);
      expect(CrashReportingService.isInitialized, isTrue);
      expect(CrashReportingService.breadcrumbs, isNotEmpty);
      expect(CrashReportingService.breadcrumbs.first, contains('initialized successfully'));
    });

    test('setUserIdentifier ve clearUserIdentifier kullanıcı kimliğini yönetmelidir', () {
      CrashReportingService.setUserIdentifier('user_abc_123');
      expect(CrashReportingService.currentUserId, 'user_abc_123');
      expect(CrashReportingService.breadcrumbs.last, contains('user_abc_123'));

      CrashReportingService.clearUserIdentifier();
      expect(CrashReportingService.currentUserId, isNull);
      expect(CrashReportingService.breadcrumbs.last, contains('identifier cleared'));
    });

    test('log() ekmek kırıntılarını (breadcrumbs) sırayla kaydetmeli ve maksimum sınırı korumalıdır', () {
      for (int i = 0; i < 110; i++) {
        CrashReportingService.log('Aksiyon $i');
      }

      // Maksimum 100 kayıt tutmalı
      expect(CrashReportingService.breadcrumbs.length, 100);
      expect(CrashReportingService.breadcrumbs.last, contains('Aksiyon 109'));
    });

    test('recordError() genel istisnaları formatlı şekilde kaydetmelidir', () {
      final testError = StateError('Geçersiz işlem');
      final testStack = StackTrace.current;

      CrashReportingService.recordError(
        testError,
        testStack,
        reason: 'Veritabanı bağlantı kopması',
        fatal: true,
      );

      final lastLog = CrashReportingService.breadcrumbs.last;
      expect(lastLog, contains('fatal=true'));
      expect(lastLog, contains('reason=Veritabanı bağlantı kopması'));
      expect(lastLog, contains('Geçersiz işlem'));
    });

    test('recordFlutterError() framework hatalarını kaydetmelidir', () {
      final details = FlutterErrorDetails(
        exception: Exception('RenderBox overflow'),
        library: 'widgets',
        context: ErrorDescription('while building a widget'),
      );

      CrashReportingService.recordFlutterError(details);

      final lastLog = CrashReportingService.breadcrumbs.last;
      expect(lastLog, contains('FlutterError: Exception: RenderBox overflow'));
    });
  });
}
