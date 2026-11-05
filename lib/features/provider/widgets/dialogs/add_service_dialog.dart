import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/sitter.dart';
import '../../cubit/provider_cubit.dart';

class AddServiceDialog extends StatefulWidget {
  const AddServiceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ProviderCubit>(),
        child: const AddServiceDialog(),
      ),
    );
  }

  @override
  State<AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<AddServiceDialog> {
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '200');
  final _descCtrl = TextEditingController();
  String _selectedUnit = '/ gün';

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
        'Yeni Hizmet Ekle',
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
                hintText: 'Örn: Özel Köpek Eğitimi & İtaat',
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
                      Text('Ücret (₺)', style: AppTypography.caption),
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
                hintText: 'Hizmet içeriğini ve sağlanan imkanları yazın',
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
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) return;
            final price = int.tryParse(_priceCtrl.text) ?? 200;

            final newSrv = SitterServiceItem(
              id: 'srv_${DateTime.now().millisecondsSinceEpoch}',
              title: title,
              price: price,
              unit: _selectedUnit,
              description: _descCtrl.text.trim(),
            );

            context.read<ProviderCubit>().addService(newSrv);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title hizmeti listeye eklendi!'),
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
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

