import 'package:flutter/material.dart';

/// Design tokens lifted directly from the gateIQ prototype.
/// Every colour, radius and shadow in the app resolves through here so the
/// look stays consistent across all 8 screens.
class AppColors {
  const AppColors._();

  /// Brand orange — the single accent the whole product is built around.
  static const brand = Color(0xFFEA530A);
  static const brandDeep = Color(0xFFD4470A);
  static const brandTint = Color(0xFFFCEBE1);

  /// Near-black used for headings and primary body copy.
  static const ink = Color(0xFF101820);
  static const inkSoft = Color(0xFF374151);
  static const muted = Color(0xFF6B7280);
  static const faint = Color(0xFF9CA3AF);

  /// Warm paper background — keeps white cards reading as raised surfaces.
  static const canvas = Color(0xFFF7F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E0D9);
  static const borderSoft = Color(0xFFECEAE4);
  static const fieldFill = Color(0xFFF7F4EE);

  /// Ticket / pass screen palette.
  static const ticketBg = Color(0xFFEFEDE7);
  static const ticketInk = Color(0xFF3A2E1F);
  static const ticketMuted = Color(0xFF8A7455);

  static const success = Color(0xFF15803D);
  static const danger = Color(0xFFB3261E);

  /// Hero gradient for the sponsored banner and brand surfaces.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEA530A), Color(0xFFF97316)],
  );

  static const brandGradientDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEA530A), Color(0xFFD4470A)],
  );
}

class AppRadii {
  const AppRadii._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 14.0;
  static const xl = 16.0;
  static const xxl = 24.0;
  static const pill = 999.0;

  static const cardShape = BorderRadius.all(Radius.circular(xl));
  static const buttonShape = BorderRadius.all(Radius.circular(lg));
  static const sheetShape = BorderRadius.vertical(top: Radius.circular(xxl));
}

class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Horizontal page gutter. Widens on tablets so content never stretches
  /// into an unreadable line length.
  static double gutter(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 900) return 40;
    if (w >= 600) return 28;
    if (w <= 360) return 16;
    return 20;
  }

  /// Caps content width on large screens / tablets so the phone-first layout
  /// stays centred and proportional instead of spanning the full width.
  static const maxContentWidth = 520.0;
}

class AppShadows {
  const AppShadows._();

  /// Soft ambient lift for white cards.
  static const card = [
    BoxShadow(
      color: Color(0x0F101820),
      blurRadius: 18,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
    BoxShadow(color: Color(0x08101820), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// Signature orange glow under the primary CTA — straight from the mockups.
  static const brandGlow = [
    BoxShadow(color: Color(0x42EA530A), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const sheet = [
    BoxShadow(color: Color(0x1F101820), blurRadius: 32, offset: Offset(0, -8)),
  ];
}
