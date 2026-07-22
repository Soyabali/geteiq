import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/demo_data.dart';
import '../models/invite.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/brand_mark.dart';

/// Screen 8 — the shareable gate pass.
///
/// Uses the warmer ticket palette from the design so it reads as a distinct
/// artefact rather than another app screen.
class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key, required this.invite});

  final Invite invite;

  /// Payload the guard's scanner reads.
  String get _qrPayload =>
      'gateiq://invite?code=${invite.code}&flat=${Uri.encodeComponent(DemoData.flat)}';

  String get _window {
    final day = DateFormat('d MMMM yyyy').format(invite.startsAt);
    final f = DateFormat('hh:mm a');
    return '$day, ${f.format(invite.startsAt)} - ${f.format(invite.endsAt)}';
  }

  String get _guestLine {
    final g = invite.guests;
    if (g.isEmpty) return 'your guest';
    if (g.length == 1) return g.first.name;
    return '${g.first.name} +${g.length - 1} more';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gutter = AppSpacing.gutter(context);
    final width = MediaQuery.sizeOf(context).width;
    // QR scales with the device but stays scannable and never overflows.
    final qrSize = (width * 0.46).clamp(150.0, 220.0);

    return Scaffold(
      backgroundColor: AppColors.ticketBg,
      appBar: AppBar(
        backgroundColor: AppColors.ticketBg,
        titleSpacing: gutter,
        leadingWidth: gutter + 32,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Invite Pass',
          style: t.headlineSmall?.copyWith(color: AppColors.ticketInk),
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(
              Icons.ios_share_rounded,
              size: 21,
              color: AppColors.ticketInk,
            ),
            onPressed: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Sharing coming soon')),
              ),
          ),
          SizedBox(width: gutter - AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: CenteredFill(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.lg,
              gutter,
              AppSpacing.xxl,
            ),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              Text(
                '${DemoData.host} has invited $_guestLine.',
                textAlign: TextAlign.center,
                style: t.headlineSmall?.copyWith(
                  color: AppColors.ticketInk,
                  height: 1.3,
                ),
              ),
              if (invite.note.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  '"${invite.note}"',
                  textAlign: TextAlign.center,
                  style: t.bodyLarge?.copyWith(
                    color: AppColors.ticketMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Show this QR code or OTP to the guard at gate',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: AppColors.ticketMuted),
              ),
              const SizedBox(height: AppSpacing.xl),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    boxShadow: AppShadows.card,
                  ),
                  child: QrImageView(
                    data: _qrPayload,
                    version: QrVersions.auto,
                    size: qrSize,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.ticketInk,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.ticketInk,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              const _OrDivider(),
              const SizedBox(height: AppSpacing.xl),

              Center(child: _CodeChip(code: invite.code)),

              const SizedBox(height: AppSpacing.xxl),
              Text(
                _window,
                textAlign: TextAlign.center,
                style: t.titleSmall?.copyWith(color: AppColors.ticketInk),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${DemoData.flat}, ${DemoData.society}',
                textAlign: TextAlign.center,
                style: t.titleSmall?.copyWith(color: AppColors.ticketInk),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                DemoData.address,
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(
                  color: AppColors.ticketMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandMark(size: 26),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'gateIQ',
                    style: t.titleMedium?.copyWith(color: AppColors.ticketInk),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.ticketBg,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.md,
              gutter,
              AppSpacing.md,
            ),
            child: CenteredBar(
              child: PrimaryButton(
                label: 'Done',
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark plate holding the fallback entry code, tappable to copy.
class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Code copied')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1F3A36),
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.card,
        ),
        child: Text(
          code,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            letterSpacing: 6,
            fontSize: 32,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.ticketMuted)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'OR',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.ticketMuted),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.ticketMuted)),
      ],
    );
  }
}
