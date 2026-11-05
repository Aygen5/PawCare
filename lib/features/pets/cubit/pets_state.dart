import '../../../domain/entities/dog.dart';

/// Evcil hayvan profil ekranının yüklenme durumlarını temsil eder.
enum PetsStatus { initial, loading, loaded, error }

/// Köpek Profili ve Sağlık Yönetimi özellik durum sınıfı.
class PetsState {
  final PetsStatus status;
  final Dog? dog;
  final List<Dog> dogs;
  final String? errorMessage;
  final bool isPhotoUpdating;

  const PetsState({
    this.status = PetsStatus.initial,
    this.dog,
    this.dogs = const [],
    this.errorMessage,
    this.isPhotoUpdating = false,
  });

  bool get isLoading => status == PetsStatus.loading;
  bool get isLoaded => status == PetsStatus.loaded;
  bool get isError => status == PetsStatus.error;

  PetsState copyWith({
    PetsStatus? status,
    Dog? dog,
    List<Dog>? dogs,
    String? errorMessage,
    bool? isPhotoUpdating,
  }) {
    return PetsState(
      status: status ?? this.status,
      dog: dog ?? this.dog,
      dogs: dogs ?? this.dogs,
      errorMessage: errorMessage ?? this.errorMessage,
      isPhotoUpdating: isPhotoUpdating ?? this.isPhotoUpdating,
    );
  }
}
