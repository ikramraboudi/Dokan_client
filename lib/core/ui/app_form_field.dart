import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// ============================================================
///  SOUKNA — CHAMP DE FORMULAIRE RÉUTILISABLE
/// ============================================================
class AppFormField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isPassword;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Widget? prefixIcon;
  final String? helperText;
  final bool enabled;

  const AppFormField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.helperText,
    this.enabled = true,
  });

  @override
  State<AppFormField> createState() => _AppFormFieldState();
}

class _AppFormFieldState extends State<AppFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppDimens.space8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword ? _obscureText : false,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          enabled: widget.enabled,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            prefixIcon: widget.prefixIcon != null
                ? IconTheme(
                    data: const IconThemeData(
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    child: widget.prefixIcon!,
                  )
                : null,
            suffixIcon: widget.isPassword
                ? Semantics(
                    label: _obscureText
                        ? 'Afficher le mot de passe'
                        : 'Masquer le mot de passe',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: _obscureText
                          ? 'Afficher le mot de passe'
                          : 'Masquer le mot de passe',
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
