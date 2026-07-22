import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The gateIQ four-square glyph, drawn rather than shipped as an image so it
/// stays crisp at any size and on any density.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 84, this.rounded = true});

  final double size;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    // Squares and gaps scale with the mark so proportions hold at any size.
    final cell = size * 0.19;
    final gap = size * 0.075;
    final stroke = size * 0.036;

    Widget square({required bool filled}) => Container(
      width: cell,
      height: cell,
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.transparent,
        border: filled ? null : Border.all(color: Colors.white, width: stroke),
        borderRadius: BorderRadius.circular(cell * 0.26),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradientDeep,
        borderRadius: BorderRadius.circular(
          rounded ? size * 0.26 : AppRadii.md,
        ),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                square(filled: false),
                SizedBox(width: gap),
                square(filled: false),
              ],
            ),
            SizedBox(height: gap),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                square(filled: false),
                SizedBox(width: gap),
                square(filled: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Wordmark used beside the glyph.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 30, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'gateIQ',
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        fontSize: fontSize,
        color: color ?? AppColors.ink,
        letterSpacing: -0.8,
      ),
    );
  }
}
