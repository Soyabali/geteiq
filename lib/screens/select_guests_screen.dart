import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/demo_data.dart';
import '../models/invite.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import 'invite_details_screen.dart';

/// Screen 6 — build the guest list from contacts, recents, or manual entry.
class SelectGuestsScreen extends StatefulWidget {
  const SelectGuestsScreen({super.key, required this.invite});

  final Invite invite;

  @override
  State<SelectGuestsScreen> createState() => _SelectGuestsScreenState();
}

class _SelectGuestsScreenState extends State<SelectGuestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _search = TextEditingController();
  late final List<Guest> _selected = List.of(widget.invite.guests);

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  List<Guest> get _filteredContacts {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return DemoData.contacts;
    return DemoData.contacts
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.phone.replaceAll(' ', '').contains(q.replaceAll(' ', '')),
        )
        .toList();
  }

  bool _isSelected(Guest g) => _selected.any((s) => s.phone == g.phone);

  void _toggle(Guest g) {
    setState(() {
      final i = _selected.indexWhere((s) => s.phone == g.phone);
      if (i >= 0) {
        _selected.removeAt(i);
      } else {
        _selected.add(g);
      }
    });
  }

  void _addManual(Guest g) {
    if (_isSelected(g)) return;
    setState(() => _selected.add(g));
  }

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
        title: const Text('Select Guests'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.brand,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppColors.ink,
              unselectedLabelColor: AppColors.faint,
              dividerColor: Colors.transparent,
              labelStyle: Theme.of(context).textTheme.titleMedium,
              unselectedLabelStyle: Theme.of(context).textTheme.titleMedium,
              tabs: const [
                Tab(text: 'Contacts'),
                Tab(text: 'Recent'),
                Tab(text: 'Add Manually'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: CenteredFill(
          child: Column(
            children: [
              if (_selected.isNotEmpty)
                _SelectedChips(
                  guests: _selected,
                  gutter: gutter,
                  onRemove: _toggle,
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _ContactsTab(
                      search: _search,
                      contacts: _filteredContacts,
                      isSelected: _isSelected,
                      onToggle: _toggle,
                      onSearchChanged: () => setState(() {}),
                      gutter: gutter,
                    ),
                    _RecentTab(
                      isSelected: _isSelected,
                      onToggle: _toggle,
                      gutter: gutter,
                    ),
                    _ManualTab(onAdd: _addManual, gutter: gutter),
                  ],
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
                    : 'Next  ·  ${_selected.length} selected',
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

/// Horizontal strip of chosen guests, each removable.
class _SelectedChips extends StatelessWidget {
  const _SelectedChips({
    required this.guests,
    required this.gutter,
    required this.onRemove,
  });

  final List<Guest> guests;
  final double gutter;
  final ValueChanged<Guest> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: gutter),
        itemCount: guests.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final g = guests[i];
          return Chip(
            label: Text(g.name, overflow: TextOverflow.ellipsis),
            labelStyle: Theme.of(context).textTheme.titleSmall,
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            deleteIcon: const Icon(Icons.close_rounded, size: 17),
            onDeleted: () => onRemove(g),
          );
        },
      ),
    );
  }
}

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({
    required this.search,
    required this.contacts,
    required this.isSelected,
    required this.onToggle,
    required this.onSearchChanged,
    required this.gutter,
  });

  final TextEditingController search;
  final List<Guest> contacts;
  final bool Function(Guest) isSelected;
  final ValueChanged<Guest> onToggle;
  final VoidCallback onSearchChanged;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.md,
            gutter,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: search,
            onChanged: (_) => onSearchChanged(),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search from contacts',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.faint),
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        Expanded(
          child: contacts.isEmpty
              ? const _Empty(message: 'No contacts match your search')
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.sm,
                    gutter,
                    AppSpacing.xxl,
                  ),
                  itemCount: contacts.length,
                  itemBuilder: (context, i) {
                    final g = contacts[i];
                    return _GuestRow(
                      guest: g,
                      selected: isSelected(g),
                      onTap: () => onToggle(g),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RecentTab extends StatelessWidget {
  const _RecentTab({
    required this.isSelected,
    required this.onToggle,
    required this.gutter,
  });

  final bool Function(Guest) isSelected;
  final ValueChanged<Guest> onToggle;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    if (DemoData.recent.isEmpty) {
      return const _Empty(message: 'No recent guests yet');
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.lg,
        gutter,
        AppSpacing.xxl,
      ),
      itemCount: DemoData.recent.length,
      itemBuilder: (context, i) {
        final g = DemoData.recent[i];
        return _GuestRow(
          guest: g,
          selected: isSelected(g),
          onTap: () => onToggle(g),
        );
      },
    );
  }
}

/// Manual entry — name plus mobile number.
class _ManualTab extends StatefulWidget {
  const _ManualTab({required this.onAdd, required this.gutter});

  final ValueChanged<Guest> onAdd;
  final double gutter;

  @override
  State<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends State<_ManualTab> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onAdd(
      Guest(name: _name.text.trim(), phone: '+91 ${_phone.text.trim()}'),
    );
    _name.clear();
    _phone.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Guest added')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        widget.gutter,
        AppSpacing.xl,
        widget.gutter,
        AppSpacing.xxl,
      ),
      child: Form(
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
              onFieldSubmitted: (_) => _submit(),
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
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(label: 'Add Guest', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _GuestRow extends StatelessWidget {
  const _GuestRow({
    required this.guest,
    required this.selected,
    required this.onTap,
  });

  final Guest guest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        radius: AppRadii.lg,
        child: Row(
          children: [
            _Avatar(initials: guest.initials, active: selected),
            const SizedBox(width: AppSpacing.md),
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
            const SizedBox(width: AppSpacing.sm),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? AppColors.brand : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.brand : AppColors.border,
                  width: 1.8,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.active = false});

  final String initials;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: active ? AppColors.brand : AppColors.brandTint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: active ? Colors.white : AppColors.brand,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 44,
              color: AppColors.faint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
