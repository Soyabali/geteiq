import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Rounded, shadowed search field used across the list and report screens.
/// Shows a clear ("✕") button once the user has typed something.
class PillSearchField extends StatelessWidget {
  const PillSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: AppShadows.card,
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        textInputAction: TextInputAction.search,
        style: t.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: t.bodyLarge?.copyWith(color: AppColors.faint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.faint),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.muted,
                  onPressed: () {
                    controller.clear();
                    onChanged();
                  },
                ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: _border,
          enabledBorder: _border,
          focusedBorder: _border,
        ),
      ),
    );
  }

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.pill),
    borderSide: BorderSide.none,
  );
}
