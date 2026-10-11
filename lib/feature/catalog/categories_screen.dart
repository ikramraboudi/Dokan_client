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

/// Provider pour charger toutes les catégories
final allCategoriesProvider = FutureProvider<List<CategoryUiModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCategories();
});

/// ============================================================
///  SOUKNA — ÉCRAN TOUTES LES CATÉGORIES (ÉTAPE 2)
/// ============================================================
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Toutes les catégories',
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(allCategoriesProvider);
        },
        child: categoriesAsync.when(
          loading: () => const LoadingState(itemCount: 7),
          error: (err, _) => ErrorState(
            onRetry: () => ref.invalidate(allCategoriesProvider),
          ),
          data: (categories) {
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
                          context.push(
                            '${AppRoutes.catalog}?category=${Uri.encodeComponent(category.name)}',
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimens.space16),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(AppDimens.radius12),
                                ),
                                child: Icon(
                                  category.icon,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: AppDimens.space16),
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
