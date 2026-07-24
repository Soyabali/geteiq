import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/invite.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import 'invite_details_screen.dart';

/// Guard-side "Add Manually" screen.
///
/// Same manual-entry form as the management flow's "Add Manually" tab, plus a
/// Department dropdown. Guests are added to the invite and carried to the
/// invite details screen via "Next".
class GuardAddManuallyScreen extends StatefulWidget {
  const GuardAddManuallyScreen({super.key, required this.invite});

  final Invite invite;

  @override
  State<GuardAddManuallyScreen> createState() => _GuardAddManuallyScreenState();
}

class _GuardAddManuallyScreenState extends State<GuardAddManuallyScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Department options for the dropdown.
  static const _departments = ['HR', 'Sales', 'IT Dept', 'Mgmt', 'Owner', 'CO'];
  String? _department;

  // Guests added so far (starts from anything already on the invite).
  late final List<Guest> _selected = List.of(widget.invite.guests);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _addGuest() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final guest = Guest(
      name: _name.text.trim(),
      phone: '+91 ${_phone.text.trim()}',
      department: _department, // captured from the dropdown
    );

    setState(() => _selected.add(guest));
    _name.clear();
    _phone.clear();
    setState(() => _department = null);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Guest added')));
  }

  void _remove(Guest g) => setState(() => _selected.remove(g));

  void _next() {
    widget.invite.guests = _selected;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InviteDetailsScreen(invite: widget.invite),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gutter = AppSpacing.gutter(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: gutter,
        leadingWidth: gutter + 32,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Add Guest'),
      ),
      body: SafeArea(
        bottom: false,
        child: CenteredFill(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.xl,
              gutter,
              AppSpacing.xxl,
            ),
            children: [
              // Manual entry form.
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Guest Name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixText: '+91  ',
                      ),
                      validator: (v) => (v == null || v.trim().length != 10)
                          ? 'Enter a 10-digit number'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Department dropdown — above the "Add Guest" button.
                    DropdownButtonFormField<String>(
                      initialValue: _department,
                      isExpanded: true,
                      // Left/right padding so the selected value lines up with
                      // the text fields above (matches the input theme).
                      padding: EdgeInsets.zero,
                      alignment: AlignmentDirectional.centerStart,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.lg,
                        ),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: _departments
                          .map(
                            (d) => DropdownMenuItem<String>(
                              value: d,
                              child: Text(d),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _department = v),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Select a department' : null,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    PrimaryButton(label: 'Add Guest', onPressed: _addGuest),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Added guests list.
              Row(
                children: [
                  Flexible(
                    child: Text('Added guests', style: t.titleMedium),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('(${_selected.length})', style: t.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (_selected.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'No guests added yet.',
                    style: t.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ..._selected.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _AddedGuestCard(guest: g, onRemove: () => _remove(g)),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.canvas,
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
                label: _selected.isEmpty
                    ? 'Next'
                    : 'Next  ·  ${_selected.length} added',
                trailing: Icons.chevron_right_rounded,
                onPressed: _selected.isEmpty ? null : _next,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One added-guest card: name, phone, department chip, remove button.
class _AddedGuestCard extends StatelessWidget {
  const _AddedGuestCard({required this.guest, required this.onRemove});

  final Guest guest;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      radius: AppRadii.lg,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  guest.name,
                  style: t.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  guest.phone,
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (guest.department != null &&
                    guest.department!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      guest.department!,
                      style: t.labelSmall?.copyWith(
                        color: AppColors.brandDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.muted,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
