/// ============================================================================
/// RÔLE DU FICHIER :
/// Écran complet de consultation des catégories de produits (`CategoriesScreen`).
/// Affiche la liste verticale des 7 catégories de Dokan avec leur icône,
/// leur nom et le nombre d'articles en stock. Toucher une catégorie ouvre le
/// catalogue pré-filtré (`/catalog?category=...`).
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `feature/catalog/` (Écran Onglet Catégories).
///
/// RELATIONS ET DÉPENDANCES :
/// - Relié à : Onglet 2 du `MainShell` via GoRouter (`AppRoutes.categories`).
/// - Dépend de :
///   * `mock_catalog_repository.dart` pour `catalogRepositoryProvider`.
///   * `core/ui/app_top_bar.dart`, `loading_state.dart`, `error_state.dart`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/loading_state.dart';
import '../../data/mock/mock_catalog_repository.dart';
import '../../data/models/category_ui_model.dart';

/// Provider chargeant de manière asynchrone la liste des catégories du catalogue.
final allCategoriesProvider = FutureProvider<List<CategoryUiModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCategories();
});

/// Écran listant l'intégralité des rubriques du catalogue.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute de l'état asynchrone des catégories
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      // En-tête standard avec titre centré
      appBar: const AppTopBar(
        title: 'Toutes les catégories',
      ),
      // Geste de tirer pour rafraîchir (Pull-to-refresh)
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          // MOT TECHNIQUE - ref.invalidate :
          // Déclare les données comme périmées et relance immédiatement la requête.
          ref.invalidate(allCategoriesProvider);
        },
        // MOT TECHNIQUE - AsyncValue.when :
        // Traitement obligatoire et exhaustif des 3 états (chargement, erreur, succès).
        child: categoriesAsync.when(
          loading: () => const LoadingState(itemCount: 7),
          error: (err, _) => ErrorState(
            onRetry: () => ref.invalidate(allCategoriesProvider),
          ),
          data: (categories) {
            // Liste verticale séparée
            return ListView.separated(
              padding: const EdgeInsets.all(AppDimens.space16),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppDimens.space12),
              itemBuilder: (context, index) {
                final category = categories[index];

                return Semantics(
                  label: 'Catégorie ${category.name}, ${category.productCount} articles disponibles',
                  button: true,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radius16),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Material(
                      color: AppColors.transparent,
                      borderRadius: BorderRadius.circular(AppDimens.radius16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppDimens.radius16),
                        onTap: () {
                          // Ouvre le catalogue avec le paramètre de requête category
                          context.push(
                            '${AppRoutes.catalog}?category=${Uri.encodeComponent(category.name)}',
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimens.space16),
                          child: Row(
                            children: [
                              // Vignette carrée avec icône de la catégorie
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(AppDimens.radius12),
                                  border: Border.all(color: AppColors.border, width: 1.0),
                                ),
                                child: Icon(
                                  category.icon,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: AppDimens.space16),

                              // Nom et nombre d'articles
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: AppDimens.space4),
                                    Text(
                                      '${category.productCount} articles',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              // Flèche de navigation vers la droite
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
