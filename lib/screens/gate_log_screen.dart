import 'package:flutter/material.dart';

import '../models/gate_log.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pill_search_field.dart';

/// "Gate Log" — guests invited by the guard. Search, approve, and add a note.
///
/// Static data for now ([kGateLogDemo]); swap for an API list later.
class GateLogScreen extends StatefulWidget {
  const GateLogScreen({super.key});

  @override
  State<GateLogScreen> createState() => _GateLogScreenState();
}

class _GateLogScreenState extends State<GateLogScreen> {
  final _search = TextEditingController();
  final _note = TextEditingController();

  // Mutable copy so approve/note edits stick.
  late final List<GateLogEntry> _all = List.of(kGateLogDemo);

  // Which card's note is being edited (index into _all), or null.
  int? _editing;

  @override
  void dispose() {
    _search.dispose();
    _note.dispose();
    super.dispose();
  }

  List<GateLogEntry> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((g) => g.searchText.contains(q)).toList();
  }

  void _toggleApprove(int i) {
    setState(() => _all[i] = _all[i].copyWith(approved: !_all[i].approved));
  }

  void _startNote(int i) {
    setState(() {
      _editing = i;
      _note.text = _all[i].note;
    });
  }

  void _cancelNote() => setState(() => _editing = null);

  void _saveNote(int i) {
    FocusScope.of(context).unfocus();
    setState(() {
      _all[i] = _all[i].copyWith(note: _note.text.trim());
      _editing = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gutter = AppSpacing.gutter(context);
    final rows = _filtered;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: gutter,
        leadingWidth: gutter + 32,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Gate Log'),
      ),
      body: SafeArea(
        bottom: false,
        child: CenteredFill(
          child: Column(
            children: [
              // Search + subtitle.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.xs,
                  gutter,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PillSearchField(
                      controller: _search,
                      hint: 'Search guard guests',
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Guests invited by guard · approve or add a note',
                      style: t.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // List.
              Expanded(
                child: rows.isEmpty
                    ? const _Empty()
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          AppSpacing.sm,
                          gutter,
                          AppSpacing.xxl,
                        ),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) {
                          final g = rows[i];
                          final realIdx = _all.indexOf(g);
                          return _GateLogCard(
                            entry: g,
                            editing: _editing == realIdx,
                            noteController: _note,
                            onApprove: () => _toggleApprove(realIdx),
                            onAddNote: () => _startNote(realIdx),
                            onCancel: _cancelNote,
                            onSave: () => _saveNote(realIdx),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateLogCard extends StatelessWidget {
  const _GateLogCard({
    required this.entry,
    required this.editing,
    required this.noteController,
    required this.onApprove,
    required this.onAddNote,
    required this.onCancel,
    required this.onSave,
  });

  final GateLogEntry entry;
  final bool editing;
  final TextEditingController noteController;
  final VoidCallback onApprove;
  final VoidCallback onAddNote;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final hasNote = entry.note.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LogRow(
            label: 'Guest Name :',
            value: entry.plus > 0 ? '${entry.name}  +${entry.plus}' : entry.name,
          ),
          const _RowDivider(),
          _LogRow(label: 'Date / Time :', value: entry.when),
          const _RowDivider(),
          _LogRow(label: 'Duration :', value: entry.duration),
          const _RowDivider(),
          _LogRow(label: 'Meet with :', value: entry.meetWith),

          // Saved note — same "Label : value" alignment as the rows above.
          if (hasNote) ...[
            const _RowDivider(),
            _LogRow(label: 'Note :', value: entry.note),
          ],

          const SizedBox(height: AppSpacing.md),

          // Approve + note area.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ApproveChip(approved: entry.approved, onTap: onApprove),
              const SizedBox(width: AppSpacing.md),
              // Swap the "Add note" button <-> the input with a fade.
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: editing
                      ? _NoteInput(key: const ValueKey('input'), controller: noteController)
                      : _AddNoteButton(
                          key: const ValueKey('button'),
                          label: hasNote ? 'Edit note' : 'Add note.',
                          onTap: onAddNote,
                        ),
                ),
              ),
            ],
          ),

          // Cancel / Save row animates in while editing.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: editing
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: onCancel,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.muted,
                            textStyle: Theme.of(context).textTheme.titleSmall,
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: onSave,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// A "Label : value" row inside a card.
class _LogRow extends StatelessWidget {
  const _LogRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: t.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: t.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.borderSoft);
}

/// Green "Approved" / amber "Approve" pill (tap to toggle).
class _ApproveChip extends StatelessWidget {
  const _ApproveChip({required this.approved, required this.onTap});

  final bool approved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = approved
        ? AppColors.success.withValues(alpha: 0.12)
        : AppColors.brandTint;
    final fg = approved ? AppColors.success : AppColors.brandDeep;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 9,
          ),
          child: Text(
            approved ? 'Approved' : 'Approve',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// The grey "Add note." / "Edit note" pill that opens the input.
class _AddNoteButton extends StatelessWidget {
  const _AddNoteButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fieldFill,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          height: 48,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.faint,
            ),
          ),
        ),
      ),
    );
  }
}

/// The note text field shown while editing.
class _NoteInput extends StatelessWidget {
  const _NoteInput({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    // Proper field height (48) with centered text.
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        textAlignVertical: TextAlignVertical.center,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Type note…',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.faint,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: const BorderSide(color: AppColors.brand),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: const BorderSide(color: AppColors.brand),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 44,
              color: AppColors.faint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No guard guests yet',
              style: t.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
