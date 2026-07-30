import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/invite.dart';
import '../services/VmsManagementPreApprovalVisitor.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import 'dashboard_screen.dart';
import 'ticket_screen.dart';

/// Screen 7 — review the window, add a note, tidy the guest list, create.
class InviteDetailsScreen extends StatefulWidget {
  const InviteDetailsScreen({super.key, required this.invite});

  final Invite invite;

  @override
  State<InviteDetailsScreen> createState() => _InviteDetailsScreenState();
}

class _InviteDetailsScreenState extends State<InviteDetailsScreen> {
  late final _note = TextEditingController(text: widget.invite.note);
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    // Mirror the note onto the invite as it is typed. "Add Guests" pops this
    // screen and coming back builds a NEW InviteDetailsScreen, which seeds
    // _note from widget.invite.note — without this the text would be lost.
    _note.addListener(() => widget.invite.note = _note.text);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String get _window {
    final f = DateFormat('dd MMM yyyy | hh:mm a');
    return '${f.format(widget.invite.startsAt)} – ${f.format(widget.invite.endsAt)}';
  }

  Future<void> _edit(Guest g) async {
    final result = await showDialog<Guest>(
      context: context,
      builder: (_) => _EditGuestDialog(guest: g),
    );
    if (result == null) return;
    setState(() {
      final i = widget.invite.guests.indexOf(g);
      if (i >= 0) widget.invite.guests[i] = result;
    });
  }

  void _remove(Guest g) {
    setState(() => widget.invite.guests.remove(g));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${g.name} removed'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.brand,
            onPressed: () => setState(() => widget.invite.guests.add(g)),
          ),
        ),
      );
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    // pick the note text-field value before sending.
    widget.invite.note = _note.text.trim();
    setState(() => _creating = true);

    try {
      // Call the api with ALL the data:
      // date, time, valid hours, note, and the selected guest list.
      final response = await PreApprovalVisitorRepo().createPreApproval(
        context,
        widget.invite,
      );
      if (!mounted) return;
      setState(() => _creating = false);

      final result = "${response['Result']}";
      final msg = "${response['Msg']}";
      final qrCode = "${response['QRCode']}"; // image url of the QR
      final myQrCode = "${response['MyQRCode']}"; // code shown below the OR
      if (result == "1") {
        // SUCCESS -> show the message as a toast...
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));

        // Guard (iUserType == "1") -> done, drop straight back to the
        // dashboard (no QR/ticket screen for this role).
        // Management (iUserType == "2") -> unchanged: show the QR ticket.
        final prefs = await SharedPreferences.getInstance();
        final isGuard = (prefs.getString('iUserType') ?? '').trim() == "1";
        if (!mounted) return;

        if (isGuard) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        } else {
          // ...and carry the QRCode url + MyQRCode to the ticket screen.
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TicketScreen(
                invite: widget.invite,
                qrCodeUrl: qrCode,
                myQrCode: myQrCode,
              ),
            ),
          );
        }
      } else {
        // FAILED -> just show the api message.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gutter = AppSpacing.gutter(context);
    final guests = widget.invite.guests;

    // Tap anywhere on the screen (outside the note field) -> hide the keyboard.
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          titleSpacing: gutter,
          leadingWidth: gutter + 32,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          centerTitle: true, // title sits in the middle of the app bar
          title: const Text('Invite Guests'),
        ),
        body: SafeArea(
          bottom: false,
          child: CenteredFill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.md,
                gutter,
                AppSpacing.xxl,
              ),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                Text(
                  widget.invite.frequency == InviteFrequency.once
                      ? 'Allow single entry between'
                      : 'Allow repeated entry between',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _window,
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.xxl),

                Text('Add a Note', style: t.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _note,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Add note'),
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    // Flexible so a large text scale wraps instead of overflowing.
                    Flexible(
                      child: Text('Manage guest list', style: t.titleMedium),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('(${guests.length})', style: t.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                if (guests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: Text(
                      'No guests added yet.',
                      style: t.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...guests.map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _GuestListItem(
                        guest: g,
                        onEdit: () => _edit(g),
                        onRemove: () => _remove(g),
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 20,
                    color: AppColors.brand,
                  ),
                  label: Text(
                    'Add Guests',
                    style: t.titleSmall?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
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
                  label: 'Create Invite',
                  loading: _creating,
                  onPressed: guests.isEmpty ? null : _create,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestListItem extends StatelessWidget {
  const _GuestListItem({
    required this.guest,
    required this.onEdit,
    required this.onRemove,
  });

  final Guest guest;
  final VoidCallback onEdit;
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
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit',
            icon: const Icon(
              Icons.edit_outlined,
              size: 19,
              color: AppColors.brand,
            ),
            visualDensity: VisualDensity.compact,
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

class _EditGuestDialog extends StatefulWidget {
  const _EditGuestDialog({required this.guest});

  final Guest guest;

  @override
  State<_EditGuestDialog> createState() => _EditGuestDialogState();
}

class _EditGuestDialogState extends State<_EditGuestDialog> {
  late final _name = TextEditingController(text: widget.guest.name);
  late final _phone = TextEditingController(text: widget.guest.phone);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      title: Text('Edit guest', style: Theme.of(context).textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(Guest(name: _name.text.trim(), phone: _phone.text.trim())),
          child: const Text(
            'Save',
            style: TextStyle(
              color: AppColors.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
