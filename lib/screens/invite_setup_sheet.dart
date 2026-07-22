import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invite.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import 'select_guests_screen.dart';

/// Screen 5 — invite setup, presented as a bottom sheet over the dashboard.
Future<void> showInviteSetupSheet(BuildContext context, Invite invite) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.45),
    builder: (_) => _InviteSetupSheet(invite: invite),
  );
}

class _InviteSetupSheet extends StatefulWidget {
  const _InviteSetupSheet({required this.invite});

  final Invite invite;

  @override
  State<_InviteSetupSheet> createState() => _InviteSetupSheetState();
}

class _InviteSetupSheetState extends State<_InviteSetupSheet> {
  late final Invite _invite = widget.invite;

  static const _durations = [1, 2, 4, 8, 12, 24];

  TimeOfDay get _start {
    final t = _invite.startTime ?? TimeOfDayValue.fromDateTime(DateTime.now());
    return TimeOfDay(hour: t.hour, minute: t.minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _invite.date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _invite.date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked != null) {
      setState(
        () => _invite.startTime = TimeOfDayValue(
          hour: picked.hour,
          minute: picked.minute,
        ),
      );
    }
  }

  Future<void> _pickDuration() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheetShape),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            const _Grabber(),
            const SizedBox(height: AppSpacing.lg),
            Text('Valid for', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ..._durations.map(
              (h) => ListTile(
                title: Text('$h ${h == 1 ? "Hour" : "Hours"}'),
                trailing: h == _invite.validForHours
                    ? const Icon(Icons.check_rounded, color: AppColors.brand)
                    : null,
                onTap: () => Navigator.of(context).pop(h),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _invite.validForHours = picked);
  }

  void _next() {
    // Grab the navigator before popping — this context is torn down with
    // the sheet route.
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => SelectGuestsScreen(invite: _invite),
      ),
    );
  }

  String get _dateLabel {
    final now = DateTime.now();
    final d = _invite.date;
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow =
        d.year == tomorrow.year &&
        d.month == tomorrow.month &&
        d.day == tomorrow.day;
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    return DateFormat('d MMM yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.gutter(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.sheetShape,
        boxShadow: AppShadows.sheet,
      ),
      // Never taller than 90% of the screen; scrolls inside if content grows.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // Lifts the sheet clear of the keyboard.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              const _Grabber(),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.xl,
                    gutter,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FrequencyTabs(
                        value: _invite.frequency,
                        onChanged: (f) => setState(() => _invite.frequency = f),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _PrivateToggle(
                        value: _invite.isPrivate,
                        onChanged: (v) => setState(() => _invite.isPrivate = v),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _Field(
                        label: 'Select Date',
                        value: _dateLabel,
                        icon: Icons.calendar_today_outlined,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Two columns on normal widths, stacked when cramped.
                      LayoutBuilder(
                        builder: (context, c) {
                          final startField = _Field(
                            label: 'Starting from',
                            value: _start.format(context),
                            icon: Icons.schedule_rounded,
                            onTap: _pickTime,
                          );
                          final validField = _Field(
                            label: 'Valid for',
                            value:
                                '${_invite.validForHours} ${_invite.validForHours == 1 ? "Hour" : "Hours"}',
                            icon: Icons.hourglass_empty_rounded,
                            onTap: _pickDuration,
                          );
                          if (c.maxWidth < 320) {
                            return Column(
                              children: [
                                startField,
                                const SizedBox(height: AppSpacing.xl),
                                validField,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: startField),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(child: validField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      PrimaryButton(label: 'Select Guest(s)', onPressed: _next),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    );
  }
}

/// Underlined "Once / Frequently" segmented control.
class _FrequencyTabs extends StatelessWidget {
  const _FrequencyTabs({required this.value, required this.onChanged});

  final InviteFrequency value;
  final ValueChanged<InviteFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    Widget tab(InviteFrequency f, String label, {bool last = false}) {
      final selected = f == value;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(f),
        child: Padding(
          // The last tab doesn't need a trailing gap — keeping it on every
          // tab was the difference between fitting and overflowing by a few
          // pixels on narrower phones (~360-390 logical width).
          padding: EdgeInsets.only(
            right: last ? 0 : AppSpacing.xxl,
            bottom: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: t.titleLarge?.copyWith(
                  color: selected ? AppColors.ink : AppColors.faint,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: 3,
                width: selected ? 28 : 0,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // A defensive horizontal scroll (rather than a bare Row) means a very
    // narrow phone or larger text scale shrinks the tabs' hit area instead of
    // hard-overflowing the layout.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          tab(InviteFrequency.once, 'Once'),
          tab(InviteFrequency.frequently, 'Frequently', last: true),
        ],
      ),
    );
  }
}

class _PrivateToggle extends StatelessWidget {
  const _PrivateToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom box so it matches the mockup's square checkbox.
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: value ? AppColors.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(
                color: value ? AppColors.brand : AppColors.border,
                width: 1.8,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Make it private', style: t.titleMedium),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    style: t.bodySmall,
                    children: [
                      const TextSpan(
                        text:
                            'This allows silent entries of your guests without disturbing others ',
                      ),
                      TextSpan(
                        text: 'Know more',
                        style: t.bodySmall?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            value ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: AppColors.brand,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Label above a tappable value with a trailing affordance icon.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: t.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(icon, size: 19, color: AppColors.brand),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
        ],
      ),
    );
  }
}
