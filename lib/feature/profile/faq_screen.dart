/// ============================================================================
/// RÔLE DU FICHIER : Écran Foire Aux Questions (FAQ) Dokan — interactif, coloré et concis.
/// Chaque question dispose de sa propre couleur pastel, d'une réponse en une seule phrase,
/// d'un accordéon exclusif (une seule réponse ouverte à la fois), d'un rebond de l'emoji
/// et d'une entrée animée échelonnée.
/// INTERAGIT AVEC : faq_data.dart, app_colors.dart, app_config.dart, support_bottom_sheet.dart.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import 'faq_data.dart';
import 'support_bottom_sheet.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> with SingleTickerProviderStateMixin {
  /// Index de la seule question actuellement dépliée (accordéon strict).
  int? _expandedIndex;

  /// Contrôleur gérant l'apparition échelonnée des cartes à l'ouverture de l'écran.
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _handleTileTap(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations && _entranceController.value != 1.0) {
      _entranceController.value = 1.0;
    }

    final hasSupportChannels = AppConfig.supportEmail.trim().isNotEmpty ||
        AppConfig.supportPhone.trim().isNotEmpty ||
        AppConfig.supportWhatsApp.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Questions fréquentes',
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space16,
            vertical: AppDimens.space12,
          ),
          children: [
            // ── En-tête accrocheur ──────────────────────────────────────────
            _buildHeader(),
            const SizedBox(height: AppDimens.space16),

            // ── Liste des 8 questions colorées en accordéon ─────────────────
            ...List.generate(dokanFaqItems.length, (index) {
              final item = dokanFaqItems[index];
              final isExpanded = _expandedIndex == index;

              if (disableAnimations) {
                return _buildFaqCard(item: item, index: index, isExpanded: isExpanded);
              }

              // Entrée échelonnée (~60 ms de décalage par carte)
              final start = (index * 0.07).clamp(0.0, 0.7);
              final end = (start + 0.3).clamp(0.0, 1.0);
              final animation = CurvedAnimation(
                parent: _entranceController,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              );

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(animation),
                  child: _buildFaqCard(item: item, index: index, isExpanded: isExpanded),
                ),
              );
            }),

            const SizedBox(height: AppDimens.space16),

            // ── Bouton support optionnel ─────────────────────────────────────
            if (hasSupportChannels) ...[
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => SupportBottomSheet.show(context),
                  icon: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                  label: const Text(
                    'Contacter le support',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space20,
                      vertical: AppDimens.space12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radius14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ],
        ),
      ),
    );
  }

  /// En-tête « Besoin d'aide ? 💬 » avec sous-titre
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppDimens.radius12),
            ),
            child: const ExcludeSemantics(
              child: Text(
                '💬',
                style: TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.space14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Besoin d\'aide ?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Touchez une question pour voir sa réponse.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte unitaire d'une question FAQ
  Widget _buildFaqCard({
    required FaqItem item,
    required int index,
    required bool isExpanded,
  }) {
    // Couleurs exclusives issues de la palette pastel AppColors
    final strongColor = AppColors.pastelAccents[item.colorIndex % AppColors.pastelAccents.length];
    final softColor = AppColors.pastelAccentsSoft[item.colorIndex % AppColors.pastelAccentsSoft.length];

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space10),
      child: Material(
        color: softColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius14),
          side: BorderSide(
            color: isExpanded ? strongColor : AppColors.border,
            width: isExpanded ? 1.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _handleTileTap(index),
          borderRadius: BorderRadius.circular(AppDimens.radius14),
          child: Semantics(
            button: true,
            label: 'Question : ${item.question}. ${isExpanded ? "Touchez pour fermer la réponse." : "Touchez pour voir la réponse."}',
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne principale : Pastille emoji + Question en gras + Chevron rotatif
                  Row(
                    children: [
                      // Pastille emoji avec couleur forte et micro-animation rebond/rotation
                      _AnimatedEmojiBadge(
                        emoji: item.emoji,
                        backgroundColor: strongColor,
                        isExpanded: isExpanded,
                      ),
                      const SizedBox(width: AppDimens.space12),

                      // Texte de la question
                      Expanded(
                        child: Text(
                          item.question,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimens.space8),

                      // Chevron qui tourne de 180° à l'ouverture
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isExpanded ? strongColor : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  // Déploiement animé de la réponse (AnimatedSize + fondu 250 ms)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topLeft,
                    child: isExpanded
                        ? Padding(
                            padding: const EdgeInsets.only(
                              top: AppDimens.space10,
                              left: 52, // Alignée sous le texte de la question
                              right: AppDimens.space4,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                item.answer,
                                key: ValueKey('faq_ans_$index'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille d'emoji avec animation de rebond et légère rotation lors de l'ouverture
class _AnimatedEmojiBadge extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;
  final bool isExpanded;

  const _AnimatedEmojiBadge({
    required this.emoji,
    required this.backgroundColor,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    Widget badge = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimens.radius12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ExcludeSemantics(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );

    if (disableAnimations) return badge;

    return AnimatedScale(
      scale: isExpanded ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AnimatedRotation(
        turns: isExpanded ? 0.04 : 0.0, // Léger balancement de ~14 degrés
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: badge,
      ),
    );
  }
}
