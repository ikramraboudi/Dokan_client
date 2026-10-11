import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// ============================================================
///  SOUKNA — BARRE SUPÉRIEURE PERSONNALISÉE
/// ============================================================
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const AppTopBar({
    super.key,
    this.title,
    this.showLogo = false,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget;
    if (showBackButton) {
      leadingWidget = Semantics(
        label: 'Retour à l\'écran précédent',
        button: true,
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          tooltip: 'Retour',
          onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
        ),
      );
    }

    Widget? titleWidget;
    if (showLogo) {
      titleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.space4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppDimens.radius8),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          const Text(
            AppConfig.appName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );
    } else if (title != null) {
      titleWidget = Text(
        title!,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
      );
    }

    return AppBar(
      title: titleWidget,
      leading: leadingWidget,
      centerTitle: !showLogo,
      actions: actions,
      bottom: bottom,
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
    );
  }
}
