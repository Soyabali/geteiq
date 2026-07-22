import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/brand_mark.dart';
import 'login_screen.dart';

/// Screen 2 — pick a sign-in role.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  void _go(BuildContext context, UserRole role) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 3),
          const Center(child: BrandMark(size: 92)),
          const SizedBox(height: AppSpacing.xl),
          Center(child: const BrandWordmark(fontSize: 32)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose how you want to sign in',
            textAlign: TextAlign.center,
            style: t.bodyLarge?.copyWith(color: AppColors.muted),
          ),
          const Spacer(flex: 2),
          PrimaryButton(
            label: 'Management Login',
            onPressed: () => _go(context, UserRole.management),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Login as Guard',
            onPressed: () => _go(context, UserRole.guard),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
