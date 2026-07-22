import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/failure_dialog.dart';
import '../widgets/success_dialog.dart';

/// Guard flow — manually register a walk-in guest at the gate.
///
/// Opened from the dashboard's "Add Guest" button when the logged-in role is
/// guard. It works with STATIC data for now (no backend). When the API is
/// ready, only the two spots marked `TODO(api)` below need to change.
class GuardInviteScreen extends StatefulWidget {
  const GuardInviteScreen({super.key});

  @override
  State<GuardInviteScreen> createState() => _GuardInviteScreenState();
}

class _GuardInviteScreenState extends State<GuardInviteScreen> {
  // Used to validate the two text fields (name + mobile).
  final _formKey = GlobalKey<FormState>();

  // Text typed by the guard.
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // The department the guard picked (null until they choose one).
  String? _selectedDepartment;

  // true while the invite is being "created" — shows a spinner on the button.
  bool _isCreating = false;

  // TODO(api): replace this hard-coded list with the departments returned by
  // your API. Nothing else in this file needs to change.
  static const List<String> _departments = [
    'HR',
    'Sales',
    'IT',
    'Admin',
    'Facility',
    'Security',
    'Finance',
    'Reception',
  ];

  // ── FAKE API RESPONSE (UI only) ───────────────────────────────────
  // Tomorrow these two values will come from your API response instead.
  //   result == 1  →  success  →  SuccessDialog
  //   result == 0  →  error    →  FailureDialog
  // Change _fakeResult to 0 to preview the error dialog.
  static const int _fakeResult = 1;
  static const String _fakeMessage = 'Invite created successfully';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Opens a bottom sheet with the department list and stores the picked one.
  Future<void> _pickDepartment() async {
    FocusScope.of(context).unfocus(); // close the keyboard first

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheetShape),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Select Department',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Flexible + a scrollable list so the sheet never overflows —
            // it just scrolls when the list is long or the screen is short.
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // One tappable row per department.
                  for (final dept in _departments)
                    ListTile(
                      title: Text(dept),
                      // Show a tick next to the currently selected one.
                      trailing: dept == _selectedDepartment
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.brand,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(dept),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );

    // Save the choice (picked is null if the guard just closed the sheet).
    if (picked != null) {
      setState(() => _selectedDepartment = picked);
    }
  }

  /// Runs when "Create Invite" is tapped.
  Future<void> _createInvite() async {
    // 1) Validate the name + mobile fields. Stop if something is wrong.
    if (!_formKey.currentState!.validate()) return;

    // 2) The department is chosen separately, so check it by hand.
    if (_selectedDepartment == null) {
      _showMessage('Please select a department');
      return;
    }

    // 3) All fields are valid. Show the loading spinner on the button.
    FocusScope.of(context).unfocus();
    setState(() => _isCreating = true);

    // The values the backend will need.
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final department = _selectedDepartment!;

    // Handy while there's no API — prints what would be sent. Remove later.
    debugPrint('Create invite → name: $name, phone: $phone, dept: $department');

    // ── TODO(api): CALL YOUR API HERE ─────────────────────────────────
    // Replace the fake block below with the real request, then read
    // `result` and `msg` from the response:
    //
    //   final res = await dio.post('/invites/walk-in', data: {
    //     'guestName': name, 'mobile': phone, 'department': department,
    //   });
    //   final int result = res.data['result'];   // 1 = success, 0 = error
    //   final String message = res.data['msg'];
    //
    // For now we FAKE the response with the static values at the top.
    await Future<void>.delayed(const Duration(milliseconds: 600)); // fake wait
    final int result = _fakeResult;
    final String message = _fakeMessage;
    // ──────────────────────────────────────────────────────────────────

    if (!mounted) return;
    setState(() => _isCreating = false);

    // 4) Show the right dialog based on the result (both auto-close in 4s).
    if (result == 1) {
      // SUCCESS → green dialog, then go back to the dashboard.
      await SuccessDialog.show(context, message);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      // ERROR → red dialog. Stay on this screen so the guard can retry.
      await FailureDialog.show(context, message);
    }
  }

  /// Small helper to show a snackbar message.
  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Invite Setup',
      // The orange "Create Invite" button pinned at the bottom.
      bottomBar: PrimaryButton(
        label: 'Create Invite',
        loading: _isCreating,
        onPressed: _isCreating ? null : _createInvite,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Manually add a walk-in guest at the gate',
              style: t.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Guest name ────────────────────────────────────────────
            Text('Guest Name', style: t.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Guest name'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a name'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Mobile number ─────────────────────────────────────────
            Text('Mobile No.', style: t.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              // Only allow digits, up to 10 of them.
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                hintText: '98765 43210',
                prefixText: '+91  ',
              ),
              validator: (value) => (value == null || value.trim().length != 10)
                  ? 'Enter a 10-digit number'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Department (tap to open the picker) ───────────────────
            Text('Select Department', style: t.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: _pickDepartment,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.muted,
                  ),
                ),
                // Show the picked department, or a grey hint if none yet.
                child: Text(
                  _selectedDepartment ?? 'Select department',
                  style: _selectedDepartment == null
                      ? t.bodyLarge?.copyWith(color: AppColors.faint)
                      : t.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text(
              'Host will be notified after invite is created. '
              'Guest can show OTP at gate.',
              style: t.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
