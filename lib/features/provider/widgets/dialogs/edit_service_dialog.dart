import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/sitter.dart';
import '../../cubit/provider_cubit.dart';

class EditServiceDialog extends StatefulWidget {
  final SitterServiceItem service;

  const EditServiceDialog({super.key, required this.service});

  static Future<void> show(BuildContext context, SitterServiceItem service) {
    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ProviderCubit>(),
        child: EditServiceDialog(service: service),
      ),
    );
  }

  @override
  State<EditServiceDialog> createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends State<EditServiceDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.service.title);
    _priceCtrl = TextEditingController(text: widget.service.price.toString());
    _descCtrl = TextEditingController(text: widget.service.description);
    _selectedUnit = widget.service.unit;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Hizmet & Fiyat Düzenle',
        style: AppTypography.titleCard.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hizmet Adı', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              style: AppTypography.bodyDefault,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fiyat (₺)', style: AppTypography.caption),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        style: AppTypography.bodyDefault,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkSurfaceContainer
                              : AppColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Birim', style: AppTypography.caption),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceContainer
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUnit,
                            isExpanded: true,
                            dropdownColor: isDark
                                ? AppColors.darkSurfaceContainer
                                : AppColors.surfaceContainerLowest,
                            items: const [
                              DropdownMenuItem(
                                value: '/ gece',
                                child: Text('/ gece'),
                              ),
                              DropdownMenuItem(
                                value: '/ gün',
                                child: Text('/ gün'),
                              ),
                              DropdownMenuItem(
                                value: '/ saat',
                                child: Text('/ saat'),
                              ),
                              DropdownMenuItem(
                                value: '/ seans',
                                child: Text('/ seans'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedUnit = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Açıklama', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              style: AppTypography.bodyDefault,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
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
            final parsedPrice =
                int.tryParse(_priceCtrl.text) ?? widget.service.price;
            final updated = widget.service.copyWith(
              title: _titleCtrl.text.trim(),
              price: parsedPrice,
              unit: _selectedUnit,
              description: _descCtrl.text.trim(),
            );
            context.read<ProviderCubit>().updateService(updated);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Hizmet başarıyla güncellendi!'),
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

