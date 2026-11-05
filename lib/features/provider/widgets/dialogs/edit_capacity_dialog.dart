import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../cubit/provider_cubit.dart';

class EditCapacityDialog extends StatefulWidget {
  final int initialTotal;
  final int initialOccupied;

  const EditCapacityDialog({
    super.key,
    required this.initialTotal,
    required this.initialOccupied,
  });

  static Future<void> show(
    BuildContext context, {
    required int initialTotal,
    required int initialOccupied,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ProviderCubit>(),
        child: EditCapacityDialog(
          initialTotal: initialTotal,
          initialOccupied: initialOccupied,
        ),
      ),
    );
  }

  @override
  State<EditCapacityDialog> createState() => _EditCapacityDialogState();
}

class _EditCapacityDialogState extends State<EditCapacityDialog> {
  late int _total;
  late int _occupied;

  @override
  void initState() {
    super.initState();
    _total = widget.initialTotal;
    _occupied = widget.initialOccupied;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final available = (_total - _occupied).clamp(0, _total);

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Oda Kontenjanını Güncelle',
        style: AppTypography.titleCard.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Toplam Süit Kapasitesi:', style: AppTypography.bodyMedium),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _total > 1
                        ? () => setState(() {
                              _total--;
                              if (_occupied > _total) _occupied = _total;
                            })
                        : null,
                  ),
                  Text(
                    '$_total',
                    style: AppTypography.headlineSection.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _total++),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dolu Süit Sayısı:', style: AppTypography.bodyMedium),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _occupied > 0
                        ? () => setState(() => _occupied--)
                        : null,
                  ),
                  Text(
                    '$_occupied',
                    style: AppTypography.headlineSection.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _occupied < _total
                        ? () => setState(() => _occupied++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Anlık Boş / Müsait Süit:',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$available Süit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'İptal',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<ProviderCubit>().updateCapacity(
              total: _total,
              occupied: _occupied,
            );
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Oda kontenjanı güncellendi!'),
                backgroundColor:
                    isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
            foregroundColor:
                isDark ? AppColors.darkOnPrimary : AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

