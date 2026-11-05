import '../../../domain/entities/booking.dart';
import '../../../domain/entities/sitter.dart';

/// Hizmet veren panelinin veri yükleme durumları.
enum ProviderStatus { initial, loading, loaded, error }

/// Hizmet veren paneli durum modeli.
class ProviderState {
  final ProviderStatus status;
  final List<BookingRequest> bookings;
  final List<BookingRequest> pendingBookings;
  final List<BookingRequest> confirmedBookings;
  final double totalEarnings;
  final String? errorMessage;
  final String? updatingBookingId;

  // Tesis Bilgileri
  final String facilityTitle;
  final String facilityLocation;
  final String facilityBio;
  final List<SitterServiceItem> services;
  final List<String> amenities;

  // Kapasite & Takvim
  final int totalSuites;
  final int occupiedSuites;
  final List<SitterCalendarDay> calendarDays;

  const ProviderState({
    this.status = ProviderStatus.initial,
    this.bookings = const [],
    this.pendingBookings = const [],
    this.confirmedBookings = const [],
    this.totalEarnings = 4250.0,
    this.errorMessage,
    this.updatingBookingId,
    this.facilityTitle = 'Mutlu Patiler Köpek Oteli',
    this.facilityLocation = 'Caddebostan, Kadıköy',
    this.facilityBio =
        '10 dönüm çim bahçe içinde, 7/24 veteriner hekim gözetiminde ve web kameralı bireysel süitlerde 5 yıldızlı köpek konaklama ve kreş deneyimi.',
    this.services = const [
      SitterServiceItem(
        id: 'srv_1',
        title: 'Standart Süit Konaklama',
        price: 950,
        unit: '/ gece',
        description: 'Bireysel ısıtmalı süit, günde 3 öğün beslenme ve 4 yürüyüş seansı dahildir.',
      ),
      SitterServiceItem(
        id: 'srv_2',
        title: 'Gündüz Kreş & Sosyalleşme',
        price: 450,
        unit: '/ gün',
        description: '08:00 - 19:00 arası açık çim bahçede serbest oyun ve sosyalleşme.',
      ),
      SitterServiceItem(
        id: 'srv_3',
        title: 'Özel Sahil Yürüyüşü (1 Saat)',
        price: 250,
        unit: '/ seans',
        description: 'Caddebostan sahilinde birebir tempolu yürüyüş ve GPS takibi.',
      ),
    ],
    this.amenities = const [
      'Geniş Çim Bahçe (5000 m²)',
      '7/24 Canlı HD Kamera Erişimi',
      'Veteriner Hekim Kontrolü',
      'Yerden Isıtmalı Bireysel Süitler',
      'Klimalı Kapalı Oyun Alanı',
      'Özel Beslenme & İlaç Takibi',
    ],
    this.totalSuites = 12,
    this.occupiedSuites = 8,
    this.calendarDays = const [
      SitterCalendarDay(
        id: 'day_1',
        day: '24',
        month: 'Ekim',
        weekday: 'Cuma',
        status: 'Dolu (12/12)',
        statusType: CalendarDayStatusType.full,
        details: 'Tüm süitler rezerve edilmiştir.',
      ),
      SitterCalendarDay(
        id: 'day_2',
        day: '25',
        month: 'Ekim',
        weekday: 'Cumartesi',
        status: 'Dolu (12/12)',
        statusType: CalendarDayStatusType.full,
        details: 'Hafta sonu yoğunluğu nedeniyle tam kapasitedir.',
      ),
      SitterCalendarDay(
        id: 'day_3',
        day: '26',
        month: 'Ekim',
        weekday: 'Pazar',
        status: '2 Süit Müsait',
        statusType: CalendarDayStatusType.limited,
        details: 'Öğleden sonra 2 süit çıkışı yapılacaktır.',
      ),
      SitterCalendarDay(
        id: 'day_4',
        day: '27',
        month: 'Ekim',
        weekday: 'Pazartesi',
        status: 'Müsait (6 Süit)',
        statusType: CalendarDayStatusType.available,
        details: 'Hafta içi konaklama ve gündüz bakımı açıktır.',
      ),
    ],
  });

  bool get isLoading => status == ProviderStatus.loading;
  bool get isLoaded => status == ProviderStatus.loaded;
  bool get isError => status == ProviderStatus.error;
  int get availableSuites => (totalSuites - occupiedSuites).clamp(0, totalSuites);

  ProviderState copyWith({
    ProviderStatus? status,
    List<BookingRequest>? bookings,
    List<BookingRequest>? pendingBookings,
    List<BookingRequest>? confirmedBookings,
    double? totalEarnings,
    String? errorMessage,
    String? updatingBookingId,
    String? facilityTitle,
    String? facilityLocation,
    String? facilityBio,
    List<SitterServiceItem>? services,
    List<String>? amenities,
    int? totalSuites,
    int? occupiedSuites,
    List<SitterCalendarDay>? calendarDays,
  }) {
    return ProviderState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      pendingBookings: pendingBookings ?? this.pendingBookings,
      confirmedBookings: confirmedBookings ?? this.confirmedBookings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      errorMessage: errorMessage,
      updatingBookingId: updatingBookingId,
      facilityTitle: facilityTitle ?? this.facilityTitle,
      facilityLocation: facilityLocation ?? this.facilityLocation,
      facilityBio: facilityBio ?? this.facilityBio,
      services: services ?? this.services,
      amenities: amenities ?? this.amenities,
      totalSuites: totalSuites ?? this.totalSuites,
      occupiedSuites: occupiedSuites ?? this.occupiedSuites,
      calendarDays: calendarDays ?? this.calendarDays,
    );
  }
}
