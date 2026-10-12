/// ============================================================================
/// RÔLE DU FICHIER :
/// Feuille modale de filtrage multicritères (`FilterSheet`).
/// Permet à l'utilisateur de restreindre l'affichage du catalogue par :
/// 1) Catégorie via des puces interactives `ChoiceChip`.
/// 2) Fourchette de prix dynamique (de 0 à 300 DT) avec un double curseur `RangeSlider`.
/// 3) Disponibilité immédiate grâce à un interrupteur `SwitchListTile`.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Feuille Modale de Filtres).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `lib/feature/catalog/catalog_screen.dart` lors du clic sur "Filtrer".
/// - Dépend de :
///   * `core/config/app_config.dart` pour le formatage des prix dans le RangeSlider.
///   * `core/theme/app_colors.dart` et `core/theme/app_dimens.dart`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Classe de données immuable regroupant les critères de filtrage actifs.
class FilterCriteria {
  final String? category;
  final double minPrice;
  final double maxPrice;
  final bool inStockOnly;

  const FilterCriteria({
    this.category,
    this.minPrice = 0.0,
    this.maxPrice = 300.0,
    this.inStockOnly = false,
  });

  /// Indique si au moins un filtre est actif (pour colorer le bouton ou afficher les chips).
  bool get isActive =>
      category != null || minPrice > 0.0 || maxPrice < 300.0 || inStockOnly;

  FilterCriteria copyWith({
    String? Function()? category,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
  }) {
    return FilterCriteria(
      category: category != null ? category() : this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }
}

/// Feuille modale interactive de configuration des filtres.
class FilterSheet extends StatefulWidget {
  final FilterCriteria initialCriteria;
  final List<String> availableCategories;
  final ValueChanged<FilterCriteria> onApply;

  const FilterSheet({
    super.key,
    required this.initialCriteria,
    required this.availableCategories,
    required this.onApply,
  });

  /// Méthode statique d'ouverture retournant les critères mis à jour.
  static Future<FilterCriteria?> show(
    BuildContext context, {
    required FilterCriteria initialCriteria,
    required List<String> availableCategories,
  }) {
    return showModalBottomSheet<FilterCriteria>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterSheet(
        initialCriteria: initialCriteria,
        availableCategories: availableCategories,
        onApply: (criteria) => Navigator.of(context).pop(criteria),
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String? _selectedCategory;
  late RangeValues _priceRange;
  late bool _inStockOnly;

  static const double _absoluteMin = 0.0;
  static const double _absoluteMax = 300.0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCriteria.category;
    _priceRange = RangeValues(
      widget.initialCriteria.minPrice.clamp(_absoluteMin, _absoluteMax),
      widget.initialCriteria.maxPrice.clamp(_absoluteMin, _absoluteMax),
    );
    _inStockOnly = widget.initialCriteria.inStockOnly;
  }

  /// Réinitialise tous les filtres à leurs valeurs par défaut.
  void _reset() {
    setState(() {
      _selectedCategory = null;
      _priceRange = const RangeValues(_absoluteMin, _absoluteMax);
      _inStockOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space20,
            vertical: AppDimens.space16,
          ),
          child: Column(
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

              // En-tête avec titre et bouton Réinitialiser
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtrer les produits',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider),
              const SizedBox(height: AppDimens.space12),

              // Contenu avec défilement interne
              Expanded(
                child: ListView(
                  children: [
                    // --- Section Catégories ---
                    Text(
                      'Catégorie',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppDimens.space8),
                    // MOT TECHNIQUE - ChoiceChip :
                    // Puces permettant une sélection unique parmi les catégories disponibles.
                    Wrap(
                      spacing: AppDimens.space8,
                      runSpacing: AppDimens.space8,
                      children: widget.availableCategories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: AppColors.primarySoft,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // --- Section Fourchette de prix ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fourchette de prix',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${AppConfig.formatPrice(_priceRange.start)} - ${AppConfig.formatPrice(_priceRange.end)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    // MOT TECHNIQUE - RangeSlider :
                    // Curseur à double poignée pour sélectionner un intervalle de valeurs.
                    RangeSlider(
                      values: _priceRange,
                      min: _absoluteMin,
                      max: _absoluteMax,
                      divisions: 30,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.primarySoft,
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // --- Section Disponibilité ---
                    Text(
                      'Disponibilité',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppDimens.space8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'En stock uniquement',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      activeTrackColor: AppColors.primary,
                      value: _inStockOnly,
                      onChanged: (val) {
                        setState(() {
                          _inStockOnly = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space16),

              // Boutons d'action inférieurs
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          FilterCriteria(
                            category: _selectedCategory,
                            minPrice: _priceRange.start,
                            maxPrice: _priceRange.end,
                            inStockOnly: _inStockOnly,
                          ),
                        );
                      },
                      child: const Text('Appliquer les filtres'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
