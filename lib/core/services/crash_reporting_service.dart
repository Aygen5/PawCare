import 'package:flutter/foundation.dart';

/// Uygulama genelinde beklenmedik hataları, çökmeleri (crash) ve istisnaları
/// merkezi olarak yakalayan ve raporlayan servis.
///
/// Flutter framework hataları (FlutterError.onError) ve asenkron/platform
/// seviyesindeki yakalanmamış hataları (PlatformDispatcher.instance.onError)
/// dinler. Firebase Crashlytics veya Sentry eklendiğinde tek noktadan bağlanabilir.
class CrashReportingService {
  CrashReportingService._();

  static final List<String> _breadcrumbs = [];
  static String? _currentUserId;
  static bool _initialized = false;

  /// Servisin başlatılıp başlatılmadığını döner.
  static bool get isInitialized => _initialized;

  /// Kayıtlı ekmek kırıntıları (breadcrumbs) listesi (hata anındaki son eylemler).
  static List<String> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  /// Mevcut kullanıcı kimliği.
  static String? get currentUserId => _currentUserId;

  /// Hata izleme altyapısını başlatır ve global hata kancalarını bağlar.
  static Future<void> init({bool attachGlobalHandlers = true}) async {
    _initialized = true;

    if (attachGlobalHandlers) {
      // 1. Flutter Framework çizim ve render hatalarını yakala
      FlutterError.onError = (FlutterErrorDetails details) {
        recordFlutterError(details);
      };

      // 2. Dart asenkron ve Isolate seviyesindeki yakalanmamış hataları yakala
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        recordError(
          error,
          stack,
          reason: 'PlatformDispatcher unhandled exception',
          fatal: true,
        );
        return true; // Hatanın uygulamayı ani ve kontrolsüz çökertmesini engeller
      };
    }

    log('CrashReportingService initialized successfully.');
  }

  /// Kullanıcı kimliğini hata raporlarına iliştirmek için kaydeder.
  static void setUserIdentifier(String userId) {
    _currentUserId = userId;
    log('CrashReporting: User identified as $userId');
  }

  /// Kullanıcı çıkış yaptığında kimlik bilgisini temizler.
  static void clearUserIdentifier() {
    _currentUserId = null;
    log('CrashReporting: User identifier cleared');
  }

  /// Hatanın öncesindeki adımları (breadcrumbs) kaydeder.
  static void log(String message) {
    final entry = '[${DateTime.now().toIso8601String()}] $message';
    _breadcrumbs.add(entry);
    if (_breadcrumbs.length > 100) {
      _breadcrumbs.removeAt(0); // Son 100 eylemi tut
    }

    if (kDebugMode) {
      debugPrint('[CrashReporting] $entry');
    }
  }

  /// Flutter framework seviyesindeki bir hatayı yakalar ve kaydeder.
  static void recordFlutterError(FlutterErrorDetails details) {
    log('FlutterError: ${details.exceptionAsString()}');
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
    // Gelecekte: FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }

  /// Genel bir hatayı veya istisnayı kaydeder.
  static void recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    final errorLog =
        'Error recorded [fatal=$fatal, reason=${reason ?? 'N/A'}]: $error\n${stack ?? ''}';
    log(errorLog);

    if (kDebugMode) {
      debugPrint('[CrashReporting ERROR] $errorLog');
    }
    // Gelecekte: FirebaseCrashlytics.instance.recordError(error, stack, reason: reason, fatal: fatal);
  }

  /// Testler için durumu sıfırlar.
  @visibleForTesting
  static void resetForTesting() {
    _breadcrumbs.clear();
    _currentUserId = null;
    _initialized = false;
  }
}
