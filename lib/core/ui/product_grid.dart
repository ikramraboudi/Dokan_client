import 'package:flutter/material.dart';
import '../../data/models/product_ui_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'empty_state.dart';
import 'loading_state.dart';
import 'product_card.dart';

/// ============================================================
///  SOUKNA — GRILLE DE PRODUITS RESPONSIVE AVEC PAGINATION SIMULÉE
/// ============================================================
class ProductGrid extends StatefulWidget {
  final List<ProductUiModel> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final void Function(ProductUiModel product)? onProductTap;
  final void Function(ProductUiModel product)? onFavoriteTap;
  final bool Function(ProductUiModel product)? isFavorite;
  final String emptyTitle;
  final String emptyMessage;
  final ScrollController? scrollController;

  const ProductGrid({
    super.key,
    required this.products,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onProductTap,
    this.onFavoriteTap,
    this.isFavorite,
    this.emptyTitle = 'Aucun produit trouvé',
    this.emptyMessage = 'Aucun article ne correspond à votre sélection.',
    this.scrollController,
  });

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  late ScrollController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _controller = widget.scrollController!;
    } else {
      _controller = ScrollController();
      _internalController = true;
    }
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200) {
      if (!widget.isLoading && !widget.isLoadingMore && widget.hasMore) {
        widget.onLoadMore?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.products.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
          return ShimmerLoading(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppDimens.space16),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppDimens.space12,
                mainAxisSpacing: AppDimens.space16,
                childAspectRatio: 0.62,
              ),
              itemCount: 6,
              itemBuilder: (_, _) => Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radius16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(
                      child: ShimmerBox(
                        height: double.infinity,
                        width: double.infinity,
                        borderRadius: AppDimens.radius16,
                      ),
                    ),
                    SizedBox(height: AppDimens.space8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppDimens.space8),
                      child: ShimmerBox(height: 14, width: 80),
                    ),
                    SizedBox(height: AppDimens.space4),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppDimens.space8),
                      child: ShimmerBox(height: 16, width: double.infinity),
                    ),
                    SizedBox(height: AppDimens.space8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppDimens.space8),
                      child: ShimmerBox(height: 18, width: 60),
                    ),
                    SizedBox(height: AppDimens.space8),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    if (widget.products.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: widget.emptyTitle,
        message: widget.emptyMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;

        return CustomScrollView(
          controller: _controller,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppDimens.space16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppDimens.space12,
                  mainAxisSpacing: AppDimens.space16,
                  childAspectRatio: 0.60,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = widget.products[index];
                    return ProductCard(
                      product: product,
                      isFavorite: widget.isFavorite?.call(product) ?? false,
                      onTap: () => widget.onProductTap?.call(product),
                      onFavoriteTap: () => widget.onFavoriteTap?.call(product),
                    );
                  },
                  childCount: widget.products.length,
                ),
              ),
            ),

            // Indicateur de pagination
            if (widget.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.space16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimens.space32),
            ),
          ],
        );
      },
    );
  }
}
