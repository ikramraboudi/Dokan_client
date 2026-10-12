/// ============================================================================
/// RÔLE DU FICHIER :
/// Feuille modale glissante de sélection du critère de tri (`SortSheet`).
/// Propose 5 modes de classement (Pertinence, Prix croissant, Prix décroissant,
/// Nouveautés, Popularité) et renvoie la clé sélectionnée au catalogue.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Feuille Modale de Tri).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `lib/feature/catalog/catalog_screen.dart` lors du clic sur "Trier".
/// - Dépend de : `core/theme/app_colors.dart` et `core/theme/app_dimens.dart`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Feuille modale surgissant du bas pour ordonner les articles du catalogue.
class SortSheet extends StatefulWidget {
  final String currentSort;
  final ValueChanged<String> onSelected;

  const SortSheet({
    super.key,
    required this.currentSort,
    required this.onSelected,
  });

  /// Liste des critères de tri disponibles avec leurs libellés en français.
  static const List<Map<String, String>> options = [
    {'key': 'relevance', 'label': 'Pertinence'},
    {'key': 'price_asc', 'label': 'Prix croissant'},
    {'key': 'price_desc', 'label': 'Prix décroissant'},
    {'key': 'newest', 'label': 'Nouveautés'},
    {'key': 'popularity', 'label': 'Popularité'},
  ];

  /// Méthode d'ouverture statique retournant le critère choisi dans un Future.
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

            // En-tête avec titre et bouton fermer
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

            // Liste des boutons radio personnalisés
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

            // Bouton de confirmation
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
