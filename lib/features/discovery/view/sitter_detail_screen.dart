import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/paw_header_actions.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/firebase_booking_repository.dart';
import '../../../domain/entities/booking.dart' as entity;
import '../../../domain/repositories/booking_repository_interface.dart';
import '../../../domain/services/booking_conflict_service.dart';
import '../../pets/cubit/pets_cubit.dart';
import '../../../core/widgets/modals/call_modal.dart';

/// Bakıcı ve Hizmet Detay Ekranı — Tarih seçimi, fiyatlama ve Clean Architecture rezervasyon akışı.
class SitterDetailScreen extends StatefulWidget {
  final SitterListing sitter;
  final VoidCallback onBack;
  final VoidCallback onBookingCompleted;
  final BookingRepositoryInterface? bookingRepository;

  const SitterDetailScreen({
    super.key,
    required this.sitter,
    required this.onBack,
    required this.onBookingCompleted,
    this.bookingRepository,
  });

  @override
  State<SitterDetailScreen> createState() => _SitterDetailScreenState();
}

class _SitterDetailScreenState extends State<SitterDetailScreen> {
  DateTime _focusedDay = DateTime(2026, 10, 24);
  DateTime? _rangeStart = DateTime(2026, 10, 24);
  DateTime? _rangeEnd = DateTime(2026, 10, 26);
  final _careNotesController = TextEditingController(
    text: 'Barley tavuk alerjisine sahip, kendi maması çantada teslim edilecektir.',
  );
  int _activeGalleryIndex = 0;
  List<entity.BookingRequest> _existingBookings = [];

  @override
  void initState() {
    super.initState();
    _loadExistingBookings();
  }

  Future<void> _loadExistingBookings() async {
    final repo = widget.bookingRepository ?? FirebaseBookingRepository();
    try {
      final list = await repo.getAllBookings();
      if (mounted) {
        setState(() {
          _existingBookings = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _careNotesController.dispose();
    super.dispose();
  }

  int get _selectedUnits {
    if (_rangeStart == null) return 1;
    if (_rangeEnd == null) return 1;
    final diff = _rangeEnd!.difference(_rangeStart!).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get _subtotal => widget.sitter.pricePerUnit * _selectedUnits;
  double get _serviceFee => 50.0;
  double get _totalPrice => _subtotal + _serviceFee;

  Future<void> _sendBookingRequest() async {
    final start = _rangeStart ?? DateTime.now();
    final end = _rangeEnd ?? DateTime.now().add(const Duration(days: 1));

    // Çakışma Kontrolü (Booking Conflict Check)
    final conflict = BookingConflictService.hasConflict(
      requestedStart: start,
      requestedEnd: end,
      existingBookings: _existingBookings,
      sitterId: widget.sitter.id,
    );

    if (conflict) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark
              ? AppColors.darkSurface
              : AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.event_busy, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Tarih Çakışması',
                style: AppTypography.titleCard.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            'Seçtiğiniz tarihler arasında bakıcının onaylanmış başka bir rezervasyonu bulunmaktadır. Lütfen takvimde kırmızı ile işaretlenmemiş müsait günleri seçiniz.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Tamam',
                style: AppTypography.labelTag.copyWith(
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final petDog =
        context.read<PetsCubit?>()?.state.dog ?? PetsCubit.fallbackDog;
    final booking = BookingRequest(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      sitterId: widget.sitter.id,
      sitterName: widget.sitter.name,
      sitterPhoto: widget.sitter.imagePath,
      petName: petDog.name,
      petBreed: petDog.breed,
      serviceTitle:
          '${widget.sitter.category} — $_selectedUnits ${widget.sitter.unitLabel} Rezervasyon',
      startDate: start,
      endDate: end,
      totalPrice: _totalPrice,
      careNotes: _careNotesController.text,
      status: BookingStatus.pending,
    );

    // 1. Clean Architecture: Rezervasyonu FirebaseBookingRepository'ye kalıcı kaydet
    final repo = widget.bookingRepository ?? FirebaseBookingRepository();
    await repo.addBooking(booking);

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Talebiniz İletildi!',
              style: AppTypography.headlineSection.copyWith(
                color: isDark
                    ? AppColors.darkOnSurface
                    : const Color(0xFF1E3023),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.sitter.name} talebinizi inceleyip onaylayacaktır. Hizmet Veren paneline geçerek talebi görüntüleyebilirsiniz.',
              style: AppTypography.bodyDefault.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : const Color(0xFF344638),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  widget.onBookingCompleted();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Tamam',
                  style: AppTypography.titleCard.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dog = context.watch<PetsCubit?>()?.state.dog ?? PetsCubit.fallbackDog;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fotoğraf Galerisi, Geri Dönüş ve Sağ Üst Aksiyonlar
              Stack(
                children: [
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: PageView.builder(
                      itemCount: widget.sitter.galleryPaths.length,
                      onPageChanged: (idx) =>
                          setState(() => _activeGalleryIndex = idx),
                      itemBuilder: (context, idx) {
                        return Image.asset(
                          widget.sitter.galleryPaths[idx],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => Container(
                            height: 280,
                            color: AppColors.surfaceContainerLow,
                            child: const Icon(
                              Icons.storefront,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.primary,
                        ),
                        onPressed: widget.onBack,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          child: IconButton(
                            icon: const Icon(
                              Icons.phone,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            onPressed: () => CallModal.show(
                              context,
                              contactName: widget.sitter.name,
                              roleSubtitle: widget.sitter.facilityTitle,
                              phoneNumber: '+90 532 555 01 23',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Standart Profil ve Bildirim Başlık Aksiyonları
                        const PawHeaderActions(),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_activeGalleryIndex + 1} / ${widget.sitter.galleryPaths.length}',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Bakıcı Detay Gövdesi
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.sitter.facilityTitle,
                                      style: AppTypography.headlineScreen,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.sitter.name} • ${widget.sitter.location}',
                                style: AppTypography.bodyDefault,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainerHigh
                                : AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkOutlineVariant.withValues(
                                      alpha: 0.6,
                                    )
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Color(0xFFE5A823),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.sitter.rating}',
                                style: AppTypography.titleCard.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                ' (${widget.sitter.reviewsCount})',
                                style: AppTypography.caption.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.outlineVariant),
                    const SizedBox(height: 14),
                    Text(
                      'Tesis Hakkında',
                      style: AppTypography.headlineSection,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.sitter.bio, style: AppTypography.bodyDefault),
                    const SizedBox(height: 18),
                    Text(
                      'Tesis Olanakları',
                      style: AppTypography.headlineSection,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.sitter.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainer
                                : AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkOutlineVariant.withValues(
                                      alpha: 0.4,
                                    )
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                amenity,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : const Color(0xFF1E3023),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.outlineVariant),
                    const SizedBox(height: 18),

                    // Rezervasyon Yapılacak Evcil Hayvan Bilgisi
                    Text(
                      'Rezervasyon Yapılacak Köpek',
                      style: AppTypography.headlineSection,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage(dog.photoPath),
                            onBackgroundImageError: (_, _) {},
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dog.name,
                                  style: AppTypography.titleCard.copyWith(
                                    color: isDark
                                        ? AppColors.darkOnSurface
                                        : const Color(0xFF1E3023),
                                  ),
                                ),
                                Text(
                                  '${dog.breed} • ${dog.ageYears} Yaş • ${dog.weightKg} kg',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.darkOnSurfaceVariant
                                        : const Color(0xFF344638),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // TableCalendar Tarih Aralığı Seçim Takvimi
                    Text(
                      'Tarih Aralığı Seçimi',
                      style: AppTypography.headlineSection,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.cardShadow,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutlineVariant.withValues(
                                  alpha: 0.3,
                                )
                              : AppColors.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      ),
                      child: TableCalendar(
                        firstDay: DateTime(2026, 1, 1),
                        lastDay: DateTime(2027, 12, 31),
                        focusedDay: _focusedDay,
                        rangeSelectionMode: RangeSelectionMode.toggledOn,
                        rangeStartDay: _rangeStart,
                        rangeEndDay: _rangeEnd,
                        calendarFormat: CalendarFormat.month,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: AppTypography.titleCard.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurface
                                : const Color(0xFF1E3023),
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          rangeStartDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          rangeEndDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          rangeHighlightColor: isDark
                              ? AppColors.darkSecondaryContainer
                              : AppColors.secondaryContainer,
                          todayDecoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                            ),
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: TextStyle(
                            color: isDark
                                ? AppColors.darkOnSurface
                                : const Color(0xFF1E3023),
                          ),
                          weekendTextStyle: TextStyle(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : const Color(0xFF344638),
                          ),
                          outsideTextStyle: TextStyle(
                            color: isDark
                                ? AppColors.darkOutlineVariant
                                : AppColors.outlineVariant,
                          ),
                        ),
                        onRangeSelected: (start, end, focusedDay) {
                          setState(() {
                            _rangeStart = start;
                            _rangeEnd = end;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            final isOccupied =
                                BookingConflictService.isDayOccupied(
                              day,
                              _existingBookings,
                              sitterId: widget.sitter.id,
                            );
                            if (isOccupied) {
                              return Positioned(
                                bottom: 2,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.error,
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Takvim Doluluk Bilgilendirme Çubuğu
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Kırmızı İşaret: Bakıcının Dolu / Onaylı Olduğu Günler',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Özel Bakım ve Not Alanı
                    Text(
                      'Özel Bakım ve Beslenme Notu',
                      style: AppTypography.headlineSection,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _careNotesController,
                      maxLines: 3,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurface
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: isDark
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'Alerjiler, rutinler, ilaçlar veya özel istekler...',
                        hintStyle: AppTypography.bodyDefault.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.secondary.withValues(alpha: 0.7),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkOutlineVariant.withValues(
                                    alpha: 0.4,
                                  )
                                : AppColors.outlineVariant.withValues(
                                    alpha: 0.4,
                                  ),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkOutlineVariant.withValues(
                                    alpha: 0.4,
                                  )
                                : AppColors.outlineVariant.withValues(
                                    alpha: 0.4,
                                  ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Fiyat Hesaplama ve Özeti Kutusu
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutlineVariant.withValues(
                                  alpha: 0.4,
                                )
                              : AppColors.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₺${widget.sitter.pricePerUnit.toInt()} x $_selectedUnits ${widget.sitter.unitLabel}',
                                style: AppTypography.bodyDefault.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : const Color(0xFF1E3023),
                                ),
                              ),
                              Text(
                                '₺${_subtotal.toInt()}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : const Color(0xFF1E3023),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PawCare Hizmet Bedeli',
                                style: AppTypography.bodyDefault.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : const Color(0xFF344638),
                                ),
                              ),
                              Text(
                                '₺${_serviceFee.toInt()}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : const Color(0xFF1E3023),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.outlineVariant,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Toplam Tutar',
                                style: AppTypography.headlineSection.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : const Color(0xFF1E3023),
                                ),
                              ),
                              Text(
                                '₺${_totalPrice.toInt()}',
                                style: AppTypography.headlineHero.copyWith(
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rezervasyon Talebi Gönder Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _sendBookingRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Rezervasyon Talebi Gönder',
                          style: AppTypography.titleCard.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
