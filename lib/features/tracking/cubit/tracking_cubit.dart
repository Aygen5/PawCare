import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/location_service.dart';
import '../../../domain/entities/walk_point.dart';
import '../../../domain/entities/walk_session.dart';
import '../../../domain/repositories/walk_repository_interface.dart';
import 'tracking_state.dart';

/// Canlı yürüyüş takip ve GPS yayın Cubit'i.
/// Hem köpek sahibi (izleyici) hem de bakıcı (GPS yayınlayıcı) modlarını yönetir.
class TrackingCubit extends Cubit<TrackingState> {
  final WalkRepositoryInterface walkRepository;
  final LocationService _locationService;

  StreamSubscription<WalkSession?>? _walkSubscription;
  StreamSubscription<Position>? _gpsSubscription;
  Timer? _tickerTimer;

  TrackingCubit({
    required this.walkRepository,
    LocationService? locationService,
  })  : _locationService = locationService ?? LocationService(),
        super(const TrackingState());

  /// Köpek Sahibi Modu: Firestore'daki yürüyüşü anlık Stream ile dinler.
  void initOwnerTracking({
    required String bookingId,
    String sitterName = 'Mert Yılmaz',
    String dogName = 'Barley',
  }) {
    emit(state.copyWith(
      status: TrackingStatus.loading,
      isSitter: false,
      errorMessage: null,
    ));

    _walkSubscription?.cancel();
    _walkSubscription = walkRepository.watchWalk(bookingId).listen(
      (session) {
        if (session != null) {
          emit(state.copyWith(
            status: session.isActive
                ? TrackingStatus.active
                : TrackingStatus.completed,
            session: session,
          ));
        } else {
          // Henüz Firestore'da oturum başlamamışsa, hazır bekleme oturumu sun
          final initialSession = WalkSession(
            id: bookingId,
            bookingId: bookingId,
            sitterId: 'sitter_1',
            sitterName: sitterName,
            dogId: 'dog_1',
            dogName: dogName,
            isActive: true,
            currentLatitude: 40.9632,
            currentLongitude: 29.0621,
            totalDistanceMeters: 0.0,
            startedAt: DateTime.now(),
            routePoints: [
              WalkPoint(
                latitude: 40.9632,
                longitude: 29.0621,
                timestamp: DateTime.now(),
              ),
            ],
          );
          emit(state.copyWith(
            status: TrackingStatus.active,
            session: initialSession,
          ));
        }
      },
      onError: (e) {
        emit(state.copyWith(
          status: TrackingStatus.error,
          errorMessage: 'Yürüyüş verisi alınamadı: $e',
        ));
      },
    );

    // Süre sayacı için her saniye state'i tetikler (duration dinamik güncellensin)
    _startTicker();
  }

  /// Bakıcı Modu: Gerçek GPS ile yürüyüşü başlatır ve Firestore'a koordinat basar.
  Future<void> startSitterWalk({
    required String bookingId,
    required String sitterId,
    required String sitterName,
    required String dogId,
    required String dogName,
    bool simulate = false,
  }) async {
    emit(state.copyWith(
      status: TrackingStatus.loading,
      isSitter: true,
      isSimulating: simulate,
      errorMessage: null,
    ));

    try {
      double startLat = 40.9632;
      double startLng = 29.0621;

      if (!simulate) {
        final hasPermission =
            await _locationService.checkAndRequestPermission();
        if (!hasPermission) {
          // İzin yoksa veya simülasyon istenirse simülasyona fallback
          simulate = true;
        } else {
          final pos = await _locationService.getCurrentPosition();
          if (pos != null) {
            startLat = pos.latitude;
            startLng = pos.longitude;
          }
        }
      }

      final session = await walkRepository.startWalk(
        bookingId: bookingId,
        sitterId: sitterId,
        sitterName: sitterName,
        dogId: dogId,
        dogName: dogName,
        initialLat: startLat,
        initialLng: startLng,
      );

      emit(state.copyWith(
        status: TrackingStatus.active,
        session: session,
        isSimulating: simulate,
        userPosition: LatLng(startLat, startLng),
      ));

      // GPS Akışını başlat
      _gpsSubscription?.cancel();
      final stream = simulate
          ? _locationService.getSimulatedPositionStream()
          : _locationService.getPositionStream(distanceFilter: 3);

      _gpsSubscription = stream.listen((Position pos) {
        _onNewPositionReceived(bookingId, pos);
      });

      _startTicker();
    } catch (e) {
      emit(state.copyWith(
        status: TrackingStatus.error,
        errorMessage: 'Yürüyüş başlatılamadı: $e',
      ));
    }
  }

  void _onNewPositionReceived(String bookingId, Position pos) {
    final currentSession = state.session;
    if (currentSession == null || !currentSession.isActive) return;

    final lastLat = currentSession.currentLatitude;
    final lastLng = currentSession.currentLongitude;

    final distanceMeters = _locationService.calculateDistance(
      lastLat,
      lastLng,
      pos.latitude,
      pos.longitude,
    );

    // GPS gürültüsünü filtrelemek için en az 1.5 metre yer değiştirme kontrolü
    if (distanceMeters < 1.5 && currentSession.routePoints.isNotEmpty) {
      return;
    }

    final newPoint = WalkPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      timestamp: pos.timestamp,
      speed: pos.speed,
      accuracy: pos.accuracy,
    );

    // Repository üzerinden Firestore ve yerel duruma bas
    walkRepository.updateWalkLocation(
      walkId: bookingId,
      point: newPoint,
      addedDistanceMeters: distanceMeters,
    );

    final updatedPoints = List<WalkPoint>.from(currentSession.routePoints)
      ..add(newPoint);
    final updatedSession = currentSession.copyWith(
      currentLatitude: pos.latitude,
      currentLongitude: pos.longitude,
      totalDistanceMeters: currentSession.totalDistanceMeters + distanceMeters,
      routePoints: updatedPoints,
    );

    emit(state.copyWith(
      session: updatedSession,
      userPosition: LatLng(pos.latitude, pos.longitude),
    ));
  }

  /// Bakıcı yürüyüşü sonlandırır.
  Future<void> endSitterWalk(String bookingId) async {
    _gpsSubscription?.cancel();
    _tickerTimer?.cancel();

    try {
      final endedSession = await walkRepository.endWalk(bookingId);
      emit(state.copyWith(
        status: TrackingStatus.completed,
        session: endedSession,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TrackingStatus.error,
        errorMessage: 'Yürüyüş sonlandırılırken hata: $e',
      ));
    }
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed && state.isActive && state.session != null) {
        // Oturumun duration getter'ı her çağrıldığında o anki zamana göre hesaplandığı için
        // state'i tazeleyerek UI sayacını tetikleriz.
        emit(state.copyWith(session: state.session));
      }
    });
  }

  @override
  Future<void> close() {
    _walkSubscription?.cancel();
    _gpsSubscription?.cancel();
    _tickerTimer?.cancel();
    return super.close();
  }
}
