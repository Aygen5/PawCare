import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/paw_header_actions.dart';
import '../../../data/models/models.dart';
import '../cubit/discovery_cubit.dart';
import '../cubit/discovery_state.dart';
import '../widgets/explore_filter_modal.dart';

/// Hizmet Keşfet ve Arama Ekranı — Clean Architecture ve DiscoveryCubit ile yönetilir.
class ExploreScreen extends StatelessWidget {
  final Function(SitterListing) onSitterSelected;
  final DiscoveryCubit? cubit;

  const ExploreScreen({super.key, required this.onSitterSelected, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _ExploreView(onSitterSelected: onSitterSelected),
      );
    }
    return BlocProvider(
      create: (_) => DiscoveryCubit()..loadSitters(),
      child: _ExploreView(onSitterSelected: onSitterSelected),
    );
  }
}

class _ExploreView extends StatefulWidget {
  final Function(SitterListing) onSitterSelected;

  const _ExploreView({required this.onSitterSelected});

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> {
  final List<String> _categories = const [
    'Tümü',
    'Köpek Oteli',
    'Köpek Gezdirme',
    'Gündüz Bakımı',
    'Evde Bakım',
    'Veteriner & Bakım',
  ];

  late final TextEditingController _searchController;
  double _minRating = 0.0;
  double _maxPrice = 2000.0;
  String _sortBy = 'Önerilen';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return BlocConsumer<DiscoveryCubit, DiscoveryState>(
      listener: (context, state) {
        // Arama metni senkronizasyonu
        if (_searchController.text != state.searchQuery) {
          _searchController.text = state.searchQuery;
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sitters = state.sitters;
        final selectedCategory = state.selectedCategory;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => context.read<DiscoveryCubit>().refresh(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst Başlık, Rol Göstergesi ve Sağ Aksiyonlar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.pets,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Köpek Sahibi',
                                      style: AppTypography.labelTag.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hizmet Keşfet',
                                style: AppTypography.headlineScreen,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.tune,
                                color: AppColors.primary,
                              ),
                              onPressed: () {
                                ExploreFilterModal.show(
                                  context,
                                  currentCategory: selectedCategory,
                                  currentMinRating: _minRating,
                                  currentMaxPrice: _maxPrice,
                                  currentSortBy: _sortBy,
                                  onApply:
                                      ({
                                        required String category,
                                        required double minRating,
                                        required double maxPrice,
                                        required String sortBy,
                                      }) {
                                        setState(() {
                                          _minRating = minRating;
                                          _maxPrice = maxPrice;
                                          _sortBy = sortBy;
                                        });
                                        context
                                            .read<DiscoveryCubit>()
                                            .applyFilters(
                                              category: category,
                                              minRating: minRating,
                                              maxPrice: maxPrice,
                                              sortBy: sortBy,
                                            );
                                      },
                                );
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.darkSurfaceContainer
                                    : AppColors.surfaceContainerLowest,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.darkOutlineVariant
                                              .withValues(alpha: 0.4)
                                        : AppColors.outlineVariant.withValues(
                                            alpha: 0.4,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Standart Profil ve Bildirim Başlık Aksiyonları
                            const PawHeaderActions(),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Arama Giriş Alanı
                    TextField(
                      controller: _searchController,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurface
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: isDark
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                      onChanged: (val) {
                        context.read<DiscoveryCubit>().setSearchQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Bakıcı, otel veya ilçe ara (örn. Kadıköy)...',
                        hintStyle: AppTypography.bodyDefault.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.secondary.withValues(alpha: 0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.secondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.secondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<DiscoveryCubit>().setSearchQuery(
                                    '',
                                  );
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
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
                          borderRadius: BorderRadius.circular(18),
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
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Yatay Kategori Çipleri (Filtreler)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(cat),
                              labelStyle: AppTypography.bodyMedium.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              backgroundColor: AppColors.surfaceContainerLowest,
                              selectedColor: AppColors.primary,
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.outlineVariant.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                              onSelected: (_) {
                                context.read<DiscoveryCubit>().setCategory(cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Bulunan Hizmet Sayısı ve Konum Satırı
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Kadıköy & Çevresinde ${sitters.length} Hizmet Bulundu',
                            style: AppTypography.titleCard.copyWith(
                              color: AppColors.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Kadıköy, İstanbul',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Yükleme Durumu veya Boş Liste Kontrolü
                    if (state.isLoading && sitters.isEmpty) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ] else if (sitters.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceContainer
                              : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aradığınız kriterlere uygun hizmet bulunamadı.',
                              style: AppTypography.titleCard,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Farklı bir arama kelimesi veya kategori seçmeyi deneyebilirsiniz.',
                              style: AppTypography.bodyDefault,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                context.read<DiscoveryCubit>().setCategory(
                                  'Tümü',
                                );
                                context.read<DiscoveryCubit>().setSearchQuery(
                                  '',
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Filtreleri Temizle'),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Dikey Bakıcı Kartları Listesi (Stitch Tasarım Sadakati)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sitters.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final s = sitters[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceContainer
                                  : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppColors.cardShadow,
                              border: Border.all(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Kart Başlık Fotoğrafı ve Rozetler
                                Stack(
                                  children: [
                                    Image.asset(
                                      s.imagePath,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        height: 160,
                                        width: double.infinity,
                                        color: AppColors.surfaceContainerLow,
                                        child: const Icon(
                                          Icons.storefront,
                                          color: AppColors.primary,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          s.category,
                                          style: AppTypography.labelTag
                                              .copyWith(
                                                color: AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 14,
                                              color: Color(0xFFE5A823),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${s.rating} (${s.reviewsCount})',
                                              style: AppTypography.labelTag
                                                  .copyWith(
                                                    color: AppColors.onSurface,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Kart Gövdesi
                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s.facilityTitle,
                                                  style: AppTypography
                                                      .headlineSection,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${s.name} • ${s.location} (${s.distanceKm} km)',
                                                  style: AppTypography.caption,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '₺${s.pricePerUnit.toInt()}',
                                                style: AppTypography
                                                    .headlineSection
                                                    .copyWith(
                                                      color: isDark
                                                          ? AppColors.darkPrimary
                                                          : AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              Text(
                                                '/${s.unitLabel}',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                      color: isDark
                                                          ? AppColors
                                                              .darkOnSurfaceVariant
                                                          : const Color(
                                                              0xFF344638,
                                                            ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        s.bio,
                                        style: AppTypography.bodyDefault,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      // Tesis Olanakları Etiketleri
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: s.amenities.take(3).map((
                                          amenity,
                                        ) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors
                                                      .darkSurfaceContainerLow
                                                  : AppColors
                                                      .surfaceContainerLow,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              amenity,
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? AppColors.darkOnSurface
                                                        : const Color(
                                                            0xFF1E3023,
                                                          ),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 16),
                                      // Talep Gönderme Eylem Butonu
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            widget.onSitterSelected(s);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor:
                                                AppColors.onPrimary,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'İncele ve Talep Gönder',
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
