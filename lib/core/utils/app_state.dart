import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../../domain/entities/notification.dart' as entity;

/// PawCare eski monolitik uygulama durum yöneticisi.
/// [DEPRECATED - Faz 1]: Uygulama kodu genelinde çiftbaşlılık (AppState) tamamen kaldırılmış,
/// durum yönetimi BLoC/Cubit mimarisine devredilmiştir. Bu dosya yalnızca eski testlerin
/// geriye dönük uyumluluğu için tutulmaktadır.
@Deprecated(
  'Faz 1 refaktörü ile AppState tamamen kaldırılmıştır. Yeni kodlarda Cubit/BLoC kullanınız.',
)
class AppState extends ChangeNotifier {
  UserRole _role = UserRole.owner;
  int _ownerNavIndex = 0;
  int _sitterNavIndex = 0;
  String _selectedCategory = 'Tümü';
  String _searchQuery = '';
  SitterListing? _selectedSitter;

  UserRole get role => _role;
  int get ownerNavIndex => _ownerNavIndex;
  int get sitterNavIndex => _sitterNavIndex;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  SitterListing? get selectedSitter => _selectedSitter;

  void setRole(UserRole newRole) {
    _role = newRole;
    notifyListeners();
  }

  void setOwnerNavIndex(int index) {
    _ownerNavIndex = index;
    notifyListeners();
  }

  void setSitterNavIndex(int index) {
    _sitterNavIndex = index;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectSitter(SitterListing? sitter) {
    _selectedSitter = sitter;
    notifyListeners();
  }

  // Köpek profil verileri
  static final Dog _defaultDog = Dog(
    id: 'dog_1',
    name: 'Barley',
    breed: 'Golden Retriever',
    ageYears: 2,
    weightKg: 28.5,
    gender: 'Erkek',
    microchip: '900215002941842',
    photoPath: 'assets/images/barley.jpg',
    allergyNote: 'Tavuk proteini alerjisi — Yalnızca kuzu etli mama veriniz.',
    behaviorNote: 'İnsanlara ve diğer köpeklere karşı son derece uysal, oyuncu ve enerjik.',
    clinicName: 'Kadıköy Veteriner Polikliniği',
    clinicPhone: '+90 216 345 67 89',
    vaccinations: [
      Vaccination(
        id: 'v_1',
        title: 'Karma Aşı (DHPPi+L)',
        dueDate: '26 Ekim 2026',
        status: VaccineStatus.upcoming,
        vetName: 'Dr. Selin Bulut',
      ),
      Vaccination(
        id: 'v_2',
        title: 'Kuduz Aşısı (Rabies)',
        dueDate: '14 Haziran 2026',
        status: VaccineStatus.completed,
        vetName: 'Dr. Selin Bulut',
        completionDate: '14 Haziran 2026',
      ),
      Vaccination(
        id: 'v_3',
        title: 'İç & Dış Parazit Tedavisi',
        dueDate: '02 Eylül 2026',
        status: VaccineStatus.completed,
        vetName: 'Dr. Selin Bulut',
        completionDate: '02 Eylül 2026',
      ),
      Vaccination(
        id: 'v_4',
        title: 'Kennel Cough (Bronşin)',
        dueDate: '15 Kasım 2026',
        status: VaccineStatus.upcoming,
        vetName: 'Dr. Selin Bulut',
      ),
    ],
  );

  late final List<Dog> _dogs = [_defaultDog];
  late Dog _currentDog = _defaultDog;

  Dog get currentDog => _currentDog;
  List<Dog> get dogs => List.unmodifiable(_dogs);

  void selectDog(Dog dog) {
    _currentDog = dog;
    notifyListeners();
  }

  void addDog(Dog newDog) {
    _dogs.add(newDog);
    _currentDog = newDog;
    notifyListeners();
  }

  void updateDog(Dog updated) {
    final idx = _dogs.indexWhere((d) => d.id == updated.id);
    if (idx != -1) {
      _dogs[idx] = updated;
    } else {
      _dogs.add(updated);
    }
    if (_currentDog.id == updated.id) {
      _currentDog = updated;
    }
    notifyListeners();
  }

  void updateDogPhoto(String newPath) {
    _currentDog = _currentDog.copyWith(photoPath: newPath);
    final idx = _dogs.indexWhere((d) => d.id == _currentDog.id);
    if (idx != -1) {
      _dogs[idx] = _currentDog;
    }
    notifyListeners();
  }

  // Hizmet veren ilanları
  final List<SitterListing> _sitters = [
    SitterListing(
      id: 'sitter_1',
      name: 'Ayşe Yılmaz',
      facilityTitle: 'Mutlu Patiler Butik Köpek Oteli',
      category: 'Köpek Oteli',
      rating: 4.9,
      reviewsCount: 128,
      pricePerUnit: 450,
      unitLabel: 'gece',
      location: 'Caddebostan, Kadıköy',
      distanceKm: 1.2,
      imagePath: 'assets/images/ayse.jpg',
      galleryPaths: [
        'assets/images/hotel_garden.jpg',
        'assets/images/ayse.jpg',
        'assets/images/barley.jpg',
      ],
      bio: '7 yıldır profesyonel evcil hayvan bakım uzmanıyım. Müstakil bahçeli evimizde misafirlerimize 7/24 birebir ilgi, geniş çim oyun alanı ve sevgi dolu bir konaklama sunuyoruz.',
      amenities: [
        'Geniş Çim Bahçe',
        '7/24 Kamera Takibi',
        'Günde 3 Kez Yürüyüş',
        'Klimalı Süitler',
        'Veteriner Protokolü',
      ],
      isVerified: true,
    ),
    SitterListing(
      id: 'sitter_2',
      name: 'Mert Demir',
      facilityTitle: 'ProDog Profesyonel Gezdirici & Eğitmen',
      category: 'Köpek Gezdirme',
      rating: 5.0,
      reviewsCount: 84,
      pricePerUnit: 250,
      unitLabel: 'saat',
      location: 'Moda Sahil, Kadıköy',
      distanceKm: 2.1,
      imagePath: 'assets/images/mert.jpg',
      galleryPaths: [
        'assets/images/mert.jpg',
        'assets/images/hotel_garden.jpg',
      ],
      bio: 'Sertifikalı köpek eğitmeni ve profesyonel gezdirici. Köpeğinizin fiziksel ve mental enerjisini atabileceği güvenli, tempolu ve eğlenceli yürüyüş seansları düzenliyorum.',
      amenities: [
        'Canlı GPS Takibi',
        'Pozitif Pekiştirme',
        'Birebir Yürüyüş',
        'Fotoğraflı Bildirim',
      ],
      isVerified: true,
    ),
    SitterListing(
      id: 'sitter_3',
      name: 'Selin & Can Kaya',
      facilityTitle: 'Pati Köşkü Gündüz Bakım Evi',
      category: 'Gündüz Bakımı',
      rating: 4.8,
      reviewsCount: 62,
      pricePerUnit: 350,
      unitLabel: 'gün',
      location: 'Fenerbahçe, Kadıköy',
      distanceKm: 3.4,
      imagePath: 'assets/images/hotel_garden.jpg',
      galleryPaths: [
        'assets/images/hotel_garden.jpg',
        'assets/images/ayse.jpg',
      ],
      bio: 'Siz işteyken dostunuz evde yalnız kalmasın. Sosyalleşme seansları, dinlenme odaları ve özel beslenme takibiyle güvenli gündüz bakımı sağlıyoruz.',
      amenities: [
        'Sosyal Oyun Grubu',
        'İlaç & Diyet Takibi',
        'Ses Yalıtımlı Dinlenme',
      ],
      isVerified: true,
    ),
  ];

  List<SitterListing> get sitters {
    if (_selectedCategory == 'Tümü' && _searchQuery.isEmpty) {
      return _sitters;
    }
    return _sitters.where((s) {
      final matchesCategory =
          _selectedCategory == 'Tümü' || s.category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.facilityTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.location.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Rezervasyon listesi
  final List<BookingRequest> _bookings = [
    BookingRequest(
      id: 'book_101',
      sitterId: 'sitter_1',
      sitterName: 'Ayşe Yılmaz',
      sitterPhoto: 'assets/images/ayse.jpg',
      petName: 'Barley',
      petBreed: 'Golden Retriever',
      serviceTitle: 'Köpek Oteli — 2 Gece Konaklama',
      startDate: DateTime(2026, 10, 24),
      endDate: DateTime(2026, 10, 26),
      totalPrice: 950.0,
      careNotes: 'Barley tavuk alerjisine sahip, kendi maması çantada teslim edilecektir. Akşam 19:00 civarı teslim edeceğiz.',
      status: BookingStatus.pending,
    ),
    BookingRequest(
      id: 'book_100',
      sitterId: 'sitter_2',
      sitterName: 'Mert Demir',
      sitterPhoto: 'assets/images/mert.jpg',
      petName: 'Barley',
      petBreed: 'Golden Retriever',
      serviceTitle: 'Caddebostan Sahil Parkı Yürüyüşü',
      startDate: DateTime(2026, 10, 23, 14, 0),
      endDate: DateTime(2026, 10, 23, 15, 0),
      totalPrice: 250.0,
      careNotes: 'Tempolu sahil yürüyüşü, bol su molası.',
      status: BookingStatus.confirmed,
    ),
  ];

  List<BookingRequest> get bookings => _bookings;

  void addBooking(BookingRequest newBooking) {
    _bookings.insert(0, newBooking);
    notifyListeners();
  }

  void updateBookingStatus(String bookingId, BookingStatus newStatus) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].status = newStatus;
      notifyListeners();
    }
  }

  // Katılımcı bazlı demo sohbet mesajları
  final Map<String, List<ChatMessage>> _conversations = {
    'Mert Demir': [
      ChatMessage(
        id: 'm1',
        senderName: 'Mert Demir',
        senderRole: UserRole.sitter,
        text:
            'Merhaba Aygen Hanım! Barley ile Caddebostan Sahil Parkı girişinde buluştuk.',
        time: '14:02',
        isMe: false,
      ),
      ChatMessage(
        id: 'm2',
        senderName: 'Aygen',
        senderRole: UserRole.owner,
        text:
            'Harika Mert Bey! Enerjisi yerindedir umarım, sabah biraz heyecanlıydı.',
        time: '14:05',
        isMe: true,
      ),
      ChatMessage(
        id: 'm3',
        senderName: 'Mert Demir',
        senderRole: UserRole.sitter,
        text:
            'Çok neşeli! Çim alanda biraz koştuk, şimdi gölgelikte su molası veriyoruz. Canlı takip üzerinden konumumuzu izleyebilirsiniz 🐾',
        time: '14:18',
        isMe: false,
      ),
    ],
    'Ayşe Yılmaz': [
      ChatMessage(
        id: 'ayse_1',
        senderName: 'Ayşe Yılmaz',
        senderRole: UserRole.sitter,
        text:
            'Merhaba Aygen Hanım! Barley için köpek oteli rezervasyon talebinizi aldım.',
        time: '11:30',
        isMe: false,
      ),
      ChatMessage(
        id: 'ayse_2',
        senderName: 'Aygen',
        senderRole: UserRole.owner,
        text:
            'Merhaba Ayşe Hanım, tavuk alerjisine dikkat edebilirseniz çok sevinirim!',
        time: '11:45',
        isMe: true,
      ),
    ],
  };

  /// Sohbet oda adını normalize eder (ör. 'Aygen (Köpek Sahibi)' -> 'Ayşe Yılmaz')
  String _normalizeConversationKey(String target) {
    final lower = target.toLowerCase();
    if (lower.contains('aygen')) {
      return 'Ayşe Yılmaz';
    }
    if (lower.contains('ayşe') || lower.contains('ayse')) {
      return 'Ayşe Yılmaz';
    }
    if (lower.contains('mert')) {
      return 'Mert Demir';
    }
    return target;
  }

  /// Geriye dönük uyumluluk: parametresiz çağrıda varsayılan Mert Demir sohbetini döner
  List<ChatMessage> get chatMessages => getChatMessagesFor('Mert Demir');

  /// Katılımcıya ait sohbet mesajlarını getirir
  List<ChatMessage> getChatMessagesFor([String participantName = 'Mert Demir']) {
    final key = _normalizeConversationKey(participantName);
    return _conversations.putIfAbsent(key, () => []);
  }

  /// Aktif role duyarlı mesaj gönderme ve karşı role anında bildirim oluşturma
  void sendChatMessage(String text, {String participantName = 'Mert Demir'}) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final key = _normalizeConversationKey(participantName);
    final room = _conversations.putIfAbsent(key, () => []);

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final UserRole senderRole = _role;
    final String senderName;

    if (_role == UserRole.sitter) {
      senderName = 'Ayşe Yılmaz';
      room.add(
        ChatMessage(
          id: 'msg_${now.millisecondsSinceEpoch}',
          senderName: senderName,
          senderRole: senderRole,
          text: cleanText,
          time: timeStr,
          isMe: true,
        ),
      );

      // Karşı tarafa (Köpek Sahibi - Aygen) anında bildirim düşer
      addNotification(
        entity.NotificationItem(
          id: 'notif_chat_${now.millisecondsSinceEpoch}',
          title: 'Ayşe Yılmaz\'dan Yeni Mesaj 💬',
          body: cleanText,
          timestamp: now,
          isRead: false,
          type: 'system',
        ),
        targetRole: UserRole.owner,
      );
    } else {
      senderName = 'Aygen';
      room.add(
        ChatMessage(
          id: 'msg_${now.millisecondsSinceEpoch}',
          senderName: senderName,
          senderRole: senderRole,
          text: cleanText,
          time: timeStr,
          isMe: true,
        ),
      );

      // Karşı tarafa (Hizmet Veren - Ayşe) anında bildirim düşer
      addNotification(
        entity.NotificationItem(
          id: 'notif_chat_${now.millisecondsSinceEpoch}',
          title: 'Aygen Yıldırım\'dan Yeni Mesaj 💬',
          body: cleanText,
          timestamp: now,
          isRead: false,
          type: 'system',
        ),
        targetRole: UserRole.sitter,
      );
    }

    notifyListeners();
  }

  // Bildirim yönetimi — Rol Bazlı Ayrışım
  List<entity.NotificationItem> _ownerNotifications = [
    NotificationItem(
      id: 'owner_notif_1',
      title: 'Aşı Hatırlatması 💉',
      body: 'Barley için Karma Aşı (DHPPi+L) randevu zamanı yaklaşıyor.',
      timestamp: DateTime(2026, 10, 24, 9, 30),
      isRead: false,
      type: 'vaccine',
    ),
    NotificationItem(
      id: 'owner_notif_2',
      title: 'Yürüyüş Zamanı 🦮',
      body:
          'Bugün saat 17:00 için planlanan Caddebostan sahil yürüyüşü yaklaşıyor.',
      timestamp: DateTime(2026, 10, 24, 8, 15),
      isRead: false,
      type: 'system',
    ),
    NotificationItem(
      id: 'owner_notif_3',
      title: 'Rezervasyon Güncellemesi 🐾',
      body: 'Mert Demir sahil yürüyüşü talebinizi onayladı.',
      timestamp: DateTime(2026, 10, 23, 14, 0),
      isRead: true,
      type: 'booking',
    ),
  ];

  List<entity.NotificationItem> _sitterNotifications = [
    NotificationItem(
      id: 'sitter_notif_1',
      title: 'Yeni Rezervasyon Talebi 📋',
      body:
          'Aygen Yıldırım, Barley (Golden Retriever) için 2 gecelik otel konaklama talebi gönderdi.',
      timestamp: DateTime(2026, 10, 24, 10, 15),
      isRead: false,
      type: 'booking',
    ),
    NotificationItem(
      id: 'sitter_notif_2',
      title: 'Misafir Pati Girişi 🐶',
      body:
          'Bugün saat 14:00\'te misafir pati "Luna" için süit odaya giriş yapılacak.',
      timestamp: DateTime(2026, 10, 24, 8, 0),
      isRead: false,
      type: 'system',
    ),
    NotificationItem(
      id: 'sitter_notif_3',
      title: 'Ödeme Hesaba Aktarıldı 💳',
      body: 'Barley konaklaması için ₺900 ön ödeme cüzdan bakiyenize eklendi.',
      timestamp: DateTime(2026, 10, 23, 16, 30),
      isRead: true,
      type: 'booking',
    ),
  ];

  List<entity.NotificationItem> get notifications =>
      _role == UserRole.sitter ? _sitterNotifications : _ownerNotifications;

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  void markNotificationAsRead(String id) {
    final list = _role == UserRole.sitter
        ? _sitterNotifications
        : _ownerNotifications;
    final idx = list.indexWhere((n) => n.id == id);
    if (idx != -1 && !list[idx].isRead) {
      list[idx] = list[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void addNotification(
    entity.NotificationItem notification, {
    UserRole? targetRole,
  }) {
    final roleToUse = targetRole ?? _role;
    if (roleToUse == UserRole.sitter) {
      _sitterNotifications.insert(0, notification);
    } else {
      _ownerNotifications.insert(0, notification);
    }
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    if (_role == UserRole.sitter) {
      _sitterNotifications = _sitterNotifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
    } else {
      _ownerNotifications = _ownerNotifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
    }
    notifyListeners();
  }

  // ==========================================
  // Hizmet Veren — İlan & Fiyatlandırma Durumu
  // ==========================================
  String _sitterFacilityTitle = 'Mutlu Patiler Butik Köpek Oteli';
  String _sitterLocation = 'Kadıköy, İstanbul';
  String _sitterBio =
      '600 m² geniş çim bahçe, klimalı süit odalar, 7/24 kamera takibi ve veteriner anlaşmalı güvenli butik köpek oteli.';

  String get sitterFacilityTitle => _sitterFacilityTitle;
  String get sitterLocation => _sitterLocation;
  String get sitterBio => _sitterBio;

  final List<SitterServiceItem> _sitterServices = [
    const SitterServiceItem(
      id: 'srv_1',
      title: 'Butik Köpek Oteli Konaklama',
      price: 450,
      unit: '/ gece',
      description: 'Özel süit oda, günde 3 yürüyüş, 7/24 kamera takibi',
      icon: Icons.hotel_outlined,
    ),
    const SitterServiceItem(
      id: 'srv_2',
      title: 'Gündüz Kreşi & Sosyalleşme',
      price: 300,
      unit: '/ gün',
      description: 'Sabah 08:30 - Akşam 19:00 arası bahçe oyunları',
      icon: Icons.wb_sunny_outlined,
    ),
    const SitterServiceItem(
      id: 'srv_3',
      title: 'Bireysel Yürüyüş & Egzersiz',
      price: 180,
      unit: '/ saat',
      description: 'Sahil parkı tempolu yürüyüş ve su molası',
      icon: Icons.directions_walk_outlined,
    ),
  ];

  List<SitterServiceItem> get sitterServices =>
      List.unmodifiable(_sitterServices);

  final List<String> _sitterAmenities = [
    '600 m² Çitli Bahçe',
    '7/24 Kamera İzleme',
    'Acil Veteriner Protokolü',
    'Klimalı Süit Odalar',
    'Özel Diyet & Alerji Yönetimi',
    'Günlük Foto & Video Paylaşımı',
  ];

  List<String> get sitterAmenities => List.unmodifiable(_sitterAmenities);

  void updateSitterFacilityInfo({
    String? facilityTitle,
    String? bio,
    String? location,
  }) {
    if (facilityTitle != null && facilityTitle.trim().isNotEmpty) {
      _sitterFacilityTitle = facilityTitle.trim();
    }
    if (bio != null && bio.trim().isNotEmpty) {
      _sitterBio = bio.trim();
    }
    if (location != null && location.trim().isNotEmpty) {
      _sitterLocation = location.trim();
    }
    final idx = _sitters.indexWhere((s) => s.id == 'sitter_1');
    if (idx != -1) {
      _sitters[idx] = _sitters[idx].copyWith(
        facilityTitle: facilityTitle ?? _sitters[idx].facilityTitle,
        bio: bio ?? _sitters[idx].bio,
        location: location ?? _sitters[idx].location,
      );
    }
    notifyListeners();
  }

  void addSitterService(SitterServiceItem service) {
    _sitterServices.add(service);
    notifyListeners();
  }

  void updateSitterService(
    String serviceId, {
    String? title,
    int? price,
    String? unit,
    String? description,
    IconData? icon,
  }) {
    final idx = _sitterServices.indexWhere((s) => s.id == serviceId);
    if (idx != -1) {
      _sitterServices[idx] = _sitterServices[idx].copyWith(
        title: title,
        price: price,
        unit: unit,
        description: description,
        icon: icon,
      );
      if (idx == 0 && price != null) {
        final sitterIdx = _sitters.indexWhere((s) => s.id == 'sitter_1');
        if (sitterIdx != -1) {
          _sitters[sitterIdx] =
              _sitters[sitterIdx].copyWith(pricePerUnit: price.toDouble());
        }
      }
      notifyListeners();
    }
  }

  void removeSitterService(String serviceId) {
    if (_sitterServices.length > 1) {
      _sitterServices.removeWhere((s) => s.id == serviceId);
      notifyListeners();
    }
  }

  void addSitterAmenity(String amenity) {
    final trimmed = amenity.trim();
    if (trimmed.isNotEmpty && !_sitterAmenities.contains(trimmed)) {
      _sitterAmenities.add(trimmed);
      notifyListeners();
    }
  }

  void removeSitterAmenity(String amenity) {
    _sitterAmenities.remove(amenity);
    notifyListeners();
  }

  // ==========================================
  // Hizmet Veren — Müsaitlik Takvimi Durumu
  // ==========================================
  int _totalSuites = 6;
  int _occupiedSuites = 5;
  int _availableSuites = 1;

  int get totalSuites => _totalSuites;
  int get occupiedSuites => _occupiedSuites;
  int get availableSuites => _availableSuites;

  final List<SitterCalendarDay> _sitterCalendarDays = [
    const SitterCalendarDay(
      id: 'cal_24',
      day: '24',
      month: 'Eki',
      weekday: 'Bugün',
      status: 'Dolu (3 Misafir)',
      statusType: CalendarDayStatusType.full,
      details: 'Barley (Süit 3) • Luna (Süit 1) • Çakıl (Süit 2)',
    ),
    const SitterCalendarDay(
      id: 'cal_25',
      day: '25',
      month: 'Eki',
      weekday: 'Pazar',
      status: '1 Oda Müsait',
      statusType: CalendarDayStatusType.limited,
      details: 'Barley (Konaklama devam) • Luna (Süit 1)',
    ),
    const SitterCalendarDay(
      id: 'cal_26',
      day: '26',
      month: 'Eki',
      weekday: 'Pazartesi',
      status: '3 Oda Müsait',
      statusType: CalendarDayStatusType.available,
      details: 'Luna öğleden sonra çıkış yapacak',
    ),
    const SitterCalendarDay(
      id: 'cal_27',
      day: '27',
      month: 'Eki',
      weekday: 'Salı',
      status: 'Tamamen Müsait',
      statusType: CalendarDayStatusType.available,
      details: 'Tüm süitler için rezervasyon kabul ediliyor',
    ),
  ];

  List<SitterCalendarDay> get sitterCalendarDays =>
      List.unmodifiable(_sitterCalendarDays);

  void updateCalendarDay(
    String id, {
    String? status,
    CalendarDayStatusType? statusType,
    String? details,
  }) {
    final idx = _sitterCalendarDays.indexWhere((d) => d.id == id);
    if (idx != -1) {
      _sitterCalendarDays[idx] = _sitterCalendarDays[idx].copyWith(
        status: status,
        statusType: statusType,
        details: details,
      );
      notifyListeners();
    }
  }

  void addCalendarDay(SitterCalendarDay day) {
    _sitterCalendarDays.add(day);
    notifyListeners();
  }

  void updateSuitesCapacity({int? total, int? occupied, int? available}) {
    if (total != null) _totalSuites = total;
    if (occupied != null) _occupiedSuites = occupied;
    if (available != null) _availableSuites = available;
    notifyListeners();
  }
}

/// Hizmet Veren — Sunulan Hizmet Kalemi
class SitterServiceItem {
  final String id;
  final String title;
  final int price;
  final String unit; // '/ gece', '/ gün', '/ saat'
  final String description;
  final IconData icon;

  const SitterServiceItem({
    required this.id,
    required this.title,
    required this.price,
    required this.unit,
    required this.description,
    required this.icon,
  });

  SitterServiceItem copyWith({
    String? id,
    String? title,
    int? price,
    String? unit,
    String? description,
    IconData? icon,
  }) {
    return SitterServiceItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }
}

/// Müsaitlik Takvimi Durum Türü
enum CalendarDayStatusType {
  full, // Dolu
  limited, // 1-2 Oda Müsait
  available, // Tamamen Müsait
}

/// Müsaitlik Takvim Günü Modeli
class SitterCalendarDay {
  final String id;
  final String day;
  final String month;
  final String weekday;
  final String status;
  final CalendarDayStatusType statusType;
  final String details;

  const SitterCalendarDay({
    required this.id,
    required this.day,
    required this.month,
    required this.weekday,
    required this.status,
    required this.statusType,
    required this.details,
  });

  SitterCalendarDay copyWith({
    String? id,
    String? day,
    String? month,
    String? weekday,
    String? status,
    CalendarDayStatusType? statusType,
    String? details,
  }) {
    return SitterCalendarDay(
      id: id ?? this.id,
      day: day ?? this.day,
      month: month ?? this.month,
      weekday: weekday ?? this.weekday,
      status: status ?? this.status,
      statusType: statusType ?? this.statusType,
      details: details ?? this.details,
    );
  }
}

/// AppState erişimi için InheritedNotifier sağlayıcı sınıfı.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppStateScope>()
        : context.getInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'Bağlam içinde AppStateScope bulunamadı.');
    return scope!.notifier!;
  }
}
