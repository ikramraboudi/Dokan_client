import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// ============================================================
///  SOUKNA — FEUILLE DE TRI (SORTSHEET)
/// ============================================================
class SortSheet extends StatefulWidget {
  final String currentSort;
  final ValueChanged<String> onSelected;

  const SortSheet({
    super.key,
    required this.currentSort,
    required this.onSelected,
  });

  static const List<Map<String, String>> options = [
    {'key': 'relevance', 'label': 'Pertinence'},
    {'key': 'price_asc', 'label': 'Prix croissant'},
    {'key': 'price_desc', 'label': 'Prix décroissant'},
    {'key': 'newest', 'label': 'Nouveautés'},
    {'key': 'popularity', 'label': 'Popularité'},
  ];

  static Future<String?> show(BuildContext context, String currentSort) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SortSheet(
        currentSort: currentSort,
        onSelected: (selected) => Navigator.of(context).pop(selected),
      ),
    );
  }

  @override
  State<SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends State<SortSheet> {
  late String _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.currentSort;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space20,
          vertical: AppDimens.space16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de préhension
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Titre
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trier les produits',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppDimens.space8),

            // Liste des options
            ...SortSheet.options.map((option) {
              final isSelected = _selectedSort == option['key'];

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  option['label']!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 22,
                      )
                    : const Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: AppColors.border,
                        size: 22,
                      ),
                onTap: () {
                  setState(() {
                    _selectedSort = option['key']!;
                  });
                },
              );
            }),

            const SizedBox(height: AppDimens.space16),

            // Bouton Appliquer
            ElevatedButton(
              onPressed: () => widget.onSelected(_selectedSort),
              child: const Text('Appliquer le tri'),
            ),
          ],
        ),
      ),
    );
  }
}
