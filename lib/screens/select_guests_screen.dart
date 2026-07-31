import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/demo_data.dart';
import '../models/invite.dart';
import '../services/contacts_service.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import 'invite_details_screen.dart';

/// Tablet breakpoint. Phones (< 600) always render the original,
/// untouched mobile layout.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;

/// Landscape / large tablets get a two-pane layout with a persistent
/// "Selected Guests" panel; portrait-ish tablets stay single-column.
bool _isWideTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

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

  // Real phone contacts loaded from the device.
  List<Guest> _contacts = const <Guest>[];
  bool _loadingContacts = true; // show a spinner while reading contacts
  bool _permissionDenied = false; // user said "Don't Allow"

  @override
  void initState() {
    super.initState();
    _loadContacts(); // pull the real contacts as soon as the screen opens
  }

  // Ask permission + read the phone contacts, then show them in the list.
  Future<void> _loadContacts() async {
    setState(() {
      _loadingContacts = true;
      _permissionDenied = false;
    });

    final result = await ContactsService.loadDeviceContacts();
    if (!mounted) return;

    setState(() {
      _loadingContacts = false;
      if (result.permissionGranted) {
        // Access allowed -> use real contacts.
        // (If the phone genuinely has none, fall back to the demo list so the
        //  screen is never blank while testing.)
        _contacts = result.guests.isNotEmpty
            ? result.guests
            : DemoData.contacts;
      } else {
        // Access denied -> keep the demo list and show a "grant access" hint.
        _permissionDenied = true;
        _contacts = DemoData.contacts;
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  List<Guest> get _filteredContacts {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _contacts;
    return _contacts
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
    final isTablet = _isTablet(context);
    final isWide = _isWideTablet(context);

    final contactsTab = _ContactsTab(
      search: _search,
      contacts: _filteredContacts,
      isSelected: _isSelected,
      onToggle: _toggle,
      onSearchChanged: () => setState(() {}),
      loading: _loadingContacts,
      permissionDenied: _permissionDenied,
      onRetry: _loadContacts,
      gutter: gutter,
    );
    final recentTab = _RecentTab(
      isSelected: _isSelected,
      onToggle: _toggle,
      gutter: gutter,
    );
    final manualTab = _ManualTab(onAdd: _addManual, gutter: gutter);

    // Tap anywhere on the screen (outside a text field) -> hide the keyboard.
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          toolbarHeight: isTablet ? 72 : kToolbarHeight,
          centerTitle: isTablet,
          titleSpacing: isTablet ? 0 : gutter,
          leadingWidth: isTablet ? gutter + 52 : gutter + 32,
          leading: isTablet
              ? Padding(
                  padding: EdgeInsets.only(left: gutter),
                  child: _TabletBackButton(
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
          title: Text(
            'Select Guests',
            style: isTablet
                ? Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontSize: 24)
                : null,
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(isTablet ? 56 : 48),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: isTablet
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: _buildTabBar(context, tablet: true),
                      ),
                    )
                  : _buildTabBar(context, tablet: false),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: isTablet
              ? _TabletBody(
                  isWide: isWide,
                  gutter: gutter,
                  selected: _selected,
                  onRemove: _toggle,
                  contactsTab: contactsTab,
                  recentTab: recentTab,
                  manualTab: manualTab,
                  tabController: _tabs,
                )
              : CenteredFill(
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
                          children: [contactsTab, recentTab, manualTab],
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
                maxWidth: isTablet ? 480 : AppSpacing.maxContentWidth,
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
      ),
    );
  }

  /// [tablet] adds an icon above each label and centers the bar instead of
  /// the mobile left-aligned strip. Labels are unchanged either way.
  ///
  /// Stays `isScrollable` on tablet too: the icons plus the longest label
  /// ("Add Manually") exceed the capped bar width at large OS text scales,
  /// and a fixed bar can't shrink, so it would overflow. Scrollable +
  /// [TabAlignment.center] still centres the tabs whenever they fit, and
  /// degrades to a scroll instead of an overflow when they don't.
  Widget _buildTabBar(BuildContext context, {required bool tablet}) {
    final baseStyle = Theme.of(context).textTheme.titleMedium;
    final labelStyle = tablet ? baseStyle?.copyWith(fontSize: 16) : baseStyle;

    return TabBar(
      controller: _tabs,
      isScrollable: true,
      tabAlignment: tablet ? TabAlignment.center : TabAlignment.start,
      indicatorColor: AppColors.brand,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: AppColors.ink,
      unselectedLabelColor: AppColors.faint,
      dividerColor: Colors.transparent,
      labelStyle: labelStyle,
      unselectedLabelStyle: labelStyle,
      tabs: tablet
          ? const [
              Tab(icon: Icon(Icons.contacts_rounded, size: 20), text: 'Contacts'),
              Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'Recent'),
              Tab(
                icon: Icon(Icons.person_add_alt_1_rounded, size: 20),
                text: 'Add Manually',
              ),
            ]
          : const [
              Tab(text: 'Contacts'),
              Tab(text: 'Recent'),
              Tab(text: 'Add Manually'),
            ],
    );
  }
}

/// Plain back button for the tablet app bar — same chevron as mobile, just
/// sized for the taller tablet toolbar. No circle/background decoration.
class _TabletBackButton extends StatelessWidget {
  const _TabletBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
      onPressed: onTap,
    );
  }
}

/// Tablet body shell. Portrait / medium tablets get a single, wider column
/// (chips strip kept, just roomier). Wide landscape tablets get a two-pane
/// layout: tabs on the left, a persistent Selected Guests panel on the right
/// instead of a horizontal chip strip.
class _TabletBody extends StatelessWidget {
  const _TabletBody({
    required this.isWide,
    required this.gutter,
    required this.selected,
    required this.onRemove,
    required this.contactsTab,
    required this.recentTab,
    required this.manualTab,
    required this.tabController,
  });

  final bool isWide;
  final double gutter;
  final List<Guest> selected;
  final ValueChanged<Guest> onRemove;
  final Widget contactsTab;
  final Widget recentTab;
  final Widget manualTab;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final tabView = TabBarView(
      controller: tabController,
      children: [contactsTab, recentTab, manualTab],
    );

    if (isWide) {
      return Padding(
        padding: EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, 0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: tabView),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(
                  flex: 2,
                  child: _SelectedGuestsPanel(
                    guests: selected,
                    onRemove: onRemove,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            if (selected.isNotEmpty)
              _SelectedChips(
                guests: selected,
                gutter: gutter,
                onRemove: onRemove,
                tablet: true,
              ),
            Expanded(child: tabView),
          ],
        ),
      ),
    );
  }
}

/// Persistent selected-guests list for wide tablets — replaces the mobile
/// horizontal chip strip with a proper scrollable panel now that there's
/// room for one. Same [selected] state and [onRemove] callback as mobile.
class _SelectedGuestsPanel extends StatelessWidget {
  const _SelectedGuestsPanel({required this.guests, required this.onRemove});

  final List<Guest> guests;
  final ValueChanged<Guest> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardShape,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Selected Guests', style: t.titleMedium)),
              if (guests.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    '${guests.length}',
                    style: t.labelMedium?.copyWith(color: AppColors.brand),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: guests.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'No guests selected yet.\nPick from Contacts, Recent, or add manually.',
                        textAlign: TextAlign.center,
                        style: t.bodySmall,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: guests.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final g = guests[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Row(
                          children: [
                            _Avatar(initials: g.initials, active: true),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    g.name,
                                    style: t.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    g.phone,
                                    style: t.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.faint,
                              ),
                              onPressed: () => onRemove(g),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Remove',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
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
    this.tablet = false,
  });

  final List<Guest> guests;
  final double gutter;
  final ValueChanged<Guest> onRemove;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: tablet ? 68 : 56,
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
            labelStyle: tablet
                ? Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontSize: 15)
                : Theme.of(context).textTheme.titleSmall,
            labelPadding: tablet
                ? const EdgeInsets.symmetric(horizontal: 4)
                : null,
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            deleteIcon: Icon(Icons.close_rounded, size: tablet ? 19 : 17),
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
    required this.loading,
    required this.permissionDenied,
    required this.onRetry,
    required this.gutter,
  });

  final TextEditingController search;
  final List<Guest> contacts;
  final bool Function(Guest) isSelected;
  final ValueChanged<Guest> onToggle;
  final VoidCallback onSearchChanged;
  final bool loading;
  final bool permissionDenied;
  final VoidCallback onRetry;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTablet(context);

    // Still reading the phone contacts -> show a spinner.
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }

    return Column(
      children: [
        // Small banner if the user blocked contact access.
        if (permissionDenied)
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, AppSpacing.md, gutter, 0),
            child: _PermissionBanner(onRetry: onRetry),
          ),
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
            decoration: InputDecoration(
              hintText: 'Search from contacts',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.faint,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: isTablet ? 18 : 14,
              ),
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

  Widget _nameField() => TextFormField(
    controller: _name,
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.next,
    decoration: const InputDecoration(labelText: 'Guest Name'),
    validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
  );

  Widget _phoneField() => TextFormField(
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
    validator: (v) =>
        (v == null || v.trim().length != 10) ? 'Enter a 10-digit number' : null,
  );

  @override
  Widget build(BuildContext context) {
    if (!_isTablet(context)) {
      // Original mobile layout — untouched.
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
              _nameField(),
              const SizedBox(height: AppSpacing.lg),
              _phoneField(),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(label: 'Add Guest', onPressed: _submit),
            ],
          ),
        ),
      );
    }

    // Tablet: fields side-by-side inside a centred, framed card.
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        widget.gutter,
        AppSpacing.xxl,
        widget.gutter,
        AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.cardShape,
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Guest Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "Add someone who isn't in your contacts.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _nameField()),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: _phoneField()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(label: 'Add Guest', onPressed: _submit),
                ],
              ),
            ),
          ),
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
    final isTablet = _isTablet(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: isTablet ? AppSpacing.lg : AppSpacing.md,
        ),
        radius: AppRadii.lg,
        child: Row(
          children: [
            _Avatar(
              initials: guest.initials,
              active: selected,
              size: isTablet ? 50 : 42,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    guest.name,
                    style: isTablet
                        ? t.titleMedium?.copyWith(fontSize: 17)
                        : t.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    guest.phone,
                    style: isTablet
                        ? t.bodySmall?.copyWith(fontSize: 14)
                        : t.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isTablet ? 28 : 24,
              height: isTablet ? 28 : 24,
              decoration: BoxDecoration(
                color: selected ? AppColors.brand : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.brand : AppColors.border,
                  width: 1.8,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: isTablet ? 18 : 16,
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
  const _Avatar({required this.initials, this.active = false, this.size = 42});

  final String initials;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? AppColors.brand : AppColors.brandTint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: active ? Colors.white : AppColors.brand,
          fontSize: size >= 48 ? 15 : 14,
        ),
      ),
    );
  }
}

/// Shown at the top of the Contacts tab when contact access was denied.
class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.brand,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Contacts access is off — showing sample list.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Allow')),
        ],
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
