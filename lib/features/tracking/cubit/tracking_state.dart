import 'package:latlong2/latlong.dart';
import '../../../domain/entities/walk_session.dart';

enum TrackingStatus {
  initial,
  loading,
  active,
  completed,
  error,
}

class TrackingState {
  final TrackingStatus status;
  final WalkSession? session;
  final bool isSitter;
  final bool isSimulating;
  final String? errorMessage;
  final LatLng? userPosition;

  const TrackingState({
    this.status = TrackingStatus.initial,
    this.session,
    this.isSitter = false,
    this.isSimulating = false,
    this.errorMessage,
    this.userPosition,
  });

  bool get isLoading => status == TrackingStatus.loading;
  bool get isActive => status == TrackingStatus.active && (session?.isActive ?? false);
  bool get isCompleted => status == TrackingStatus.completed || (session != null && !session!.isActive);

  List<LatLng> get routeCoordinates => session?.routeCoordinates ?? [];
  LatLng get currentPosition =>
      userPosition ??
      session?.currentLatLng ??
      const LatLng(40.9632, 29.0621); // Caddebostan fallback

  TrackingState copyWith({
    TrackingStatus? status,
    WalkSession? session,
    bool? isSitter,
    bool? isSimulating,
    String? errorMessage,
    LatLng? userPosition,
  }) {
    return TrackingState(
      status: status ?? this.status,
      session: session ?? this.session,
      isSitter: isSitter ?? this.isSitter,
      isSimulating: isSimulating ?? this.isSimulating,
      errorMessage: errorMessage ?? this.errorMessage,
      userPosition: userPosition ?? this.userPosition,
    );
  }
}

