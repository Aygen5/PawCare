import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:paw_care/core/services/location_service.dart';
import 'package:paw_care/data/repositories/firebase_walk_repository.dart';
import 'package:paw_care/domain/entities/walk_point.dart';
import 'package:paw_care/domain/entities/walk_session.dart';
import 'package:paw_care/features/tracking/cubit/tracking_cubit.dart';
import 'package:paw_care/features/tracking/cubit/tracking_state.dart';

void main() {
  group('Faz 4: Canlı Navigasyon & Gerçek GPS Takip Motoru Testleri', () {
    test('WalkPoint toMap ve fromMap serileştirmesi kayıpsız çalışmalıdır', () {
      final now = DateTime(2026, 11, 5, 20, 0, 0);
      final point = WalkPoint(
        latitude: 40.9632,
        longitude: 29.0621,
        timestamp: now,
        speed: 1.4,
        accuracy: 4.2,
      );

      final map = point.toMap();
      expect(map['latitude'], 40.9632);
      expect(map['longitude'], 29.0621);
      expect(map['speed'], 1.4);
      expect(map['accuracy'], 4.2);
      expect(map['timestamp'], now.millisecondsSinceEpoch);

      final fromMap = WalkPoint.fromMap(map);
      expect(fromMap.latitude, point.latitude);
      expect(fromMap.longitude, point.longitude);
      expect(fromMap.speed, point.speed);
      expect(fromMap.accuracy, point.accuracy);
      expect(fromMap.timestamp.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('WalkSession mesafe, süre ve rota koordinatlarını doğru hesaplamalıdır', () {
      final start = DateTime(2026, 11, 5, 20, 0, 0);
      final p1 = WalkPoint(latitude: 40.9632, longitude: 29.0621, timestamp: start);
      final p2 = WalkPoint(latitude: 40.9640, longitude: 29.0630, timestamp: start.add(const Duration(minutes: 10)));

      final session = WalkSession(
        id: 'walk_caddebostan_1',
        bookingId: 'booking_1',
        sitterId: 'sitter_mert',
        sitterName: 'Mert Yılmaz',
        dogId: 'dog_barley',
        dogName: 'Barley',
        isActive: true,
        currentLatitude: 40.9640,
        currentLongitude: 29.0630,
        totalDistanceMeters: 1450.0,
        startedAt: start,
        routePoints: [p1, p2],
      );

      expect(session.totalDistanceKm, 1.45);
      expect(session.distanceFormatted, '1.45 km');
      expect(session.routeCoordinates.length, 2);
      expect(session.routeCoordinates.first, const LatLng(40.9632, 29.0621));
      expect(session.routeCoordinates.last, const LatLng(40.9640, 29.0630));
      expect(session.startLatLng, const LatLng(40.9632, 29.0621));
      expect(session.currentLatLng, const LatLng(40.9640, 29.0630));

      final map = session.toMap();
      expect(map['id'], 'walk_caddebostan_1');
      expect(map['isActive'], isTrue);
      expect(map['totalDistanceMeters'], 1450.0);
      expect((map['coordinates'] as List).length, 2);

      final fromMap = WalkSession.fromMap(map, 'walk_caddebostan_1');
      expect(fromMap.id, 'walk_caddebostan_1');
      expect(fromMap.sitterName, 'Mert Yılmaz');
      expect(fromMap.dogName, 'Barley');
      expect(fromMap.routePoints.length, 2);
    });

    test('LocationService iki koordinat arası mesafeyi doğru hesaplamalıdır', () {
      final service = LocationService(isSimulationMode: true);
      // Caddebostan Sahil iki nokta arası mesafe
      final distance = service.calculateDistance(
        40.9632,
        29.0621,
        40.9640,
        29.0630,
      );

      expect(distance, greaterThan(100.0));
      expect(distance, lessThan(300.0));
    });

    test('FirebaseWalkRepository yürüyüş başlatma, güncelleme ve tamamlama yaşam döngüsünü yönetmelidir', () async {
      final repo = FirebaseWalkRepository();
      const bookingId = 'test_booking_101';

      // 1. Yürüyüş Başlatma
      final started = await repo.startWalk(
        bookingId: bookingId,
        sitterId: 'sitter_1',
        sitterName: 'Mert',
        dogId: 'dog_1',
        dogName: 'Barley',
        initialLat: 40.9632,
        initialLng: 29.0621,
      );

      expect(started.id, bookingId);
      expect(started.isActive, isTrue);
      expect(started.routePoints.length, 1);
      expect(started.totalDistanceMeters, 0.0);

      // 2. Stream Dinleme ve Konum Güncelleme
      final stream = repo.watchWalk(bookingId);
      final expectations = <WalkSession?>[];
      final sub = stream.listen((s) => expectations.add(s));

      await repo.updateWalkLocation(
        walkId: bookingId,
        point: WalkPoint(
          latitude: 40.9640,
          longitude: 29.0630,
          timestamp: DateTime.now(),
        ),
        addedDistanceMeters: 120.0,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final updated = await repo.getWalk(bookingId);
      expect(updated, isNotNull);
      expect(updated!.routePoints.length, 2);
      expect(updated.totalDistanceMeters, 120.0);
      expect(updated.currentLatitude, 40.9640);

      // 3. Yürüyüşü Tamamlama
      final ended = await repo.endWalk(bookingId);
      expect(ended.isActive, isFalse);
      expect(ended.endedAt, isNotNull);

      await sub.cancel();
    });

    test('TrackingCubit Köpek Sahibi (Owner) izleyici modunda anlık yürüyüşü dinlemelidir', () async {
      final repo = FirebaseWalkRepository();
      final cubit = TrackingCubit(walkRepository: repo);
      const bookingId = 'owner_track_test_1';

      // Önceden başlatılmış bir yürüyüş simüle edelim
      await repo.startWalk(
        bookingId: bookingId,
        sitterId: 'sitter_mert',
        sitterName: 'Mert',
        dogId: 'dog_barley',
        dogName: 'Barley',
        initialLat: 40.9632,
        initialLng: 29.0621,
      );

      cubit.initOwnerTracking(
        bookingId: bookingId,
        sitterName: 'Mert',
        dogName: 'Barley',
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.status, TrackingStatus.active);
      expect(cubit.state.session, isNotNull);
      expect(cubit.state.session!.sitterName, 'Mert');
      expect(cubit.state.session!.dogName, 'Barley');
      expect(cubit.state.isSitter, isFalse);

      await cubit.close();
    });

    test('TrackingCubit Bakıcı (Sitter) modunda simüle GPS ile yürüyüşü başlatıp sonlandırabilmelidir', () async {
      final repo = FirebaseWalkRepository();
      final cubit = TrackingCubit(
        walkRepository: repo,
        locationService: LocationService(isSimulationMode: true),
      );
      const bookingId = 'sitter_track_test_1';

      await cubit.startSitterWalk(
        bookingId: bookingId,
        sitterId: 'sitter_mert',
        sitterName: 'Mert Yılmaz',
        dogId: 'dog_barley',
        dogName: 'Barley',
        simulate: true,
      );

      expect(cubit.state.status, TrackingStatus.active);
      expect(cubit.state.isSitter, isTrue);
      expect(cubit.state.isSimulating, isTrue);
      expect(cubit.state.session, isNotNull);
      expect(cubit.state.session!.isActive, isTrue);

      await cubit.endSitterWalk(bookingId);

      expect(cubit.state.status, TrackingStatus.completed);
      expect(cubit.state.session!.isActive, isFalse);

      await cubit.close();
    });
  });
}

