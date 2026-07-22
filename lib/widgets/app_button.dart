import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The gradient CTA used at the bottom of most screens.
///
/// Ships with the brand glow shadow and a subtle press-scale so it feels
/// responsive on both platforms.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailing,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailing;
  final bool loading;
  final bool expand;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.45,
            duration: const Duration(milliseconds: 180),
            child: Container(
              width: widget.expand ? double.infinity : null,
              // 54 keeps a comfortable tap target without crowding small phones.
              height: 54,
              padding: widget.expand
                  ? null
                  : const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradientDeep,
                borderRadius: AppRadii.buttonShape,
                boxShadow: enabled ? AppShadows.brandGlow : null,
              ),
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                          if (widget.trailing != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              widget.trailing,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet counterpart to [PrimaryButton] — white surface, hairline border.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.buttonShape,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}
