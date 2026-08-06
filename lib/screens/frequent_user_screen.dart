import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/frequent_user.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/pill_search_field.dart';

/// Tablet breakpoint — same rule the notifications screen uses. Phones
/// (< 600) render the flat white list.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;

/// Frequent User screen — management-only entry point from the dashboard.
///
/// People who come to the office regularly get a standing duty slot instead of
/// a fresh invite each time: pick the person, pick a date + time, tap
/// **Duty Done**.
///
/// **UI only for now.** Every place an API call belongs is marked with a
/// `TODO(api)` comment and the surrounding code already works off
/// `List<FrequentUser>`, so wiring the REST calls later touches:
///   * [_FrequentUserScreenState._load]  — the list, and the drop-down filter
///   * [_DutyDialogState._onDutyDone]    — creating the duty
/// and nothing else.
class FrequentUserScreen extends StatefulWidget {
  const FrequentUserScreen({super.key});

  /// Same slow fade + gentle upward slide the notifications screen opens with.
  static Route<void> route() {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => const FrequentUserScreen(),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<FrequentUserScreen> createState() => _FrequentUserScreenState();
}

class _FrequentUserScreenState extends State<FrequentUserScreen> {
  final _search = TextEditingController();

  /// Where the app-bar drop-down always returns to. Change this one line to
  /// start the screen on a different value.
  static const int _kDefaultCount = 1;

  /// App-bar drop-down, 1..10. Drives the list reload. Never sticky — see
  /// [_resetCount].
  int _count = _kDefaultCount;

  List<FrequentUser> _all = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    // Opening the screen always starts from the default value.
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ==========================================================================
  //  DATA
  // ==========================================================================

  /// The single seam between this screen and the backend.
  ///
  /// [silent] keeps the current rows on screen (drop-down change / pull to
  /// refresh) instead of swapping them for the full-screen spinner — the same
  /// pattern `notification_screen.dart` uses.
  Future<void> _load({bool silent = false}) async {
    setState(() {
      _loading = !silent;
      _error = false;
    });

    try {
      // TODO(api): replace the static list below with the real endpoint, e.g.
      //   final rows = await FrequentUserRepo()
      //       .getFrequentUsers(context, iTop: _count);
      // Keep the same `List<FrequentUser>` return type and nothing else on
      // this screen has to change. `_count` is the drop-down value to send.
      final rows = _demoRows;

      if (!mounted) return;
      setState(() {
        _all = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  /// Placeholder rows so the layout is reviewable before the API exists.
  /// Delete this getter once [_load] calls the real endpoint.
  List<FrequentUser> get _demoRows => const [
    FrequentUser(
      id: '1',
      name: 'Pramod Kumar',
      phone: '9876543210',
      department: 'HR',
      visitCount: 24,
    ),
    FrequentUser(
      id: '2',
      name: 'Ali Hassan',
      phone: '9812345670',
      department: 'Accounts',
      visitCount: 18,
    ),
    FrequentUser(
      id: '3',
      name: 'Sunita Sharma',
      phone: '9899001122',
      department: 'Admin',
      visitCount: 15,
    ),
    FrequentUser(
      id: '4',
      name: 'Rakesh Verma',
      phone: '9765432180',
      department: 'Maintenance',
      visitCount: 12,
    ),
    FrequentUser(
      id: '5',
      name: 'Neha Gupta',
      phone: '9711223344',
      department: 'IT Support',
      visitCount: 9,
    ),
  ];

  /// Client-side filter by name, phone or department. When the API starts
  /// searching server-side, forward `_search.text` from [_load] instead.
  List<FrequentUser> get _rows {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((u) => u.searchText.contains(q)).toList();
  }

  /// App-bar drop-down changed.
  void _onCountChanged(int? value) {
    if (value == null || value == _count) return;

    print('==================== FREQUENT USER ====================');
    print('---- Selected value (dropdown) ----> $value');
    print('=======================================================');

    // TODO(api): this is the hook for the list API — send `value` as the
    // count/top-N parameter and rebuild the list from the response.
    // `_load()` already carries `_count`, so calling it is enough.
    setState(() => _count = value);
    _load(silent: true);
  }

  /// Puts the drop-down back to [_kDefaultCount] and reloads with it.
  ///
  /// The selection is deliberately not sticky: it is a per-visit filter, so
  /// coming back to a screen still showing an old "7" — with a list that may
  /// have changed underneath it — would be misleading. No-ops when the value
  /// is already the default, so returning from the dialog doesn't fire a
  /// pointless reload.
  void _resetCount() {
    if (_count == _kDefaultCount) return;

    print('==================== FREQUENT USER ====================');
    print('---- Dropdown reset to default ----> $_kDefaultCount');
    print('=======================================================');

    setState(() => _count = _kDefaultCount);
    // TODO(api): same list call as _onCountChanged — reload with the default.
    _load(silent: true);
  }

  /// Forward chevron tapped on a row -> date/time + "Duty Done" dialog.
  ///
  /// Whatever closed the dialog — "Duty Done", the ✕, or a tap outside — the
  /// drop-down goes back to its default afterwards.
  Future<void> _openDutyDialog(FrequentUser user) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.ink.withValues(alpha: 0.45),
      builder: (_) => _DutyDialog(user: user),
    );
    if (!mounted) return;
    _resetCount();
  }

  // ==========================================================================
  //  UI
  // ==========================================================================

  /// Caps the reading width on tablets and centres it, exactly like the
  /// notifications screen, so a wide screen doesn't stretch a two-column row
  /// across 1000px of empty space. Phones get 0 and keep the flat full-bleed
  /// list. Shared by the search field and the list so they stay aligned.
  double _horizontalInset(BuildContext context) {
    if (!_isTablet(context)) return 0;
    final width = MediaQuery.sizeOf(context).width;
    const maxContentWidth = 720.0;
    final gutter = AppSpacing.gutter(context);
    return width > maxContentWidth + gutter * 2
        ? (width - maxContentWidth) / 2
        : gutter;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isTablet = _isTablet(context);
    final surface = isTablet ? AppColors.canvas : Colors.white;

    return Scaffold(
      backgroundColor: surface,
      // Same app bar as `notification_screen.dart` — only the trailing action
      // differs (drop-down instead of the refresh icon).
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        toolbarHeight: isTablet ? 72 : kToolbarHeight,
        titleSpacing: 0,
        centerTitle: true,
        // iOS-style back chevron.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.ink,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Frequent User',
          style: t.titleLarge?.copyWith(fontSize: isTablet ? 24 : 20),
        ),
        actions: [
          _CountDropdown(value: _count, onChanged: _onCountChanged),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                _horizontalInset(context) + AppSpacing.lg,
                AppSpacing.sm,
                _horizontalInset(context) + AppSpacing.lg,
                AppSpacing.md,
              ),
              child: PillSearchField(
                controller: _search,
                hint: 'Search frequent users',
                onChanged: () => setState(() {}),
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }
    if (_error) {
      return _ListMessage(
        icon: Icons.wifi_off_rounded,
        message: "Couldn't load frequent users.",
        onRetry: _load,
      );
    }

    final rows = _rows;
    if (rows.isEmpty) {
      return _ListMessage(
        icon: Icons.people_outline_rounded,
        message: _search.text.trim().isEmpty
            ? 'No Data'
            : 'No user matches "${_search.text.trim()}"',
      );
    }

    final horizontalInset = _horizontalInset(context);

    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () => _load(silent: true),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          0,
          horizontalInset,
          AppSpacing.xxl,
        ),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Divider(height: 1),
        ),
        itemBuilder: (context, i) => _FrequentUserTile(
          user: rows[i],
          onForwardTap: () => _openDutyDialog(rows[i]),
        ),
      ),
    );
  }
}

/// Compact 1..10 drop-down that sits where the notifications screen keeps its
/// refresh icon. Styled as a brand-tinted pill so it reads as an app-bar
/// action rather than a form field.
class _CountDropdown extends StatelessWidget {
  const _CountDropdown({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(AppRadii.md),
          dropdownColor: AppColors.surface,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.brand,
            size: 20,
          ),
          style: t.titleSmall?.copyWith(color: AppColors.brandDeep),
          items: [
            for (var i = 1; i <= 10; i++)
              DropdownMenuItem<int>(value: i, child: Text('$i')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// One list row: name (plus its supporting line) on the left, an iOS-style
/// forward chevron on the right. Tapping the chevron opens the duty dialog.
class _FrequentUserTile extends StatelessWidget {
  const _FrequentUserTile({required this.user, required this.onForwardTap});

  final FrequentUser user;
  final VoidCallback onForwardTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  style: t.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    user.meta,
                    style: t.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Apple-style forward chevron in a soft tinted circle, so the tap
          // target reads as a real control and clears 44pt.
          Material(
            color: AppColors.brandTint,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onForwardTap,
              splashColor: AppColors.brand.withValues(alpha: 0.18),
              highlightColor: AppColors.brand.withValues(alpha: 0.08),
              child: const Padding(
                padding: EdgeInsets.all(11),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.brand,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
//  DUTY DIALOG
// ============================================================================

/// Pick a date + time for a frequent visitor, then confirm with **Duty Done**.
class _DutyDialog extends StatefulWidget {
  const _DutyDialog({required this.user});

  final FrequentUser user;

  @override
  State<_DutyDialog> createState() => _DutyDialogState();
}

class _DutyDialogState extends State<_DutyDialog> {
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  /// "Today" / "Tomorrow" / "12 Aug 2026" — same wording as the invite sheet.
  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(_date.year, _date.month, _date.day);
    return switch (day.difference(today).inDays) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => DateFormat('d MMM yyyy').format(_date),
    };
  }

  void _onDutyDone() {
    // The API's own formats, matching what `invite_setup_sheet.dart` sends.
    final dDate = DateFormat('dd/MMM/yyyy').format(_date); // 12/Aug/2026
    final dTime =
        '${_time.hour.toString().padLeft(2, '0')}:'
        '${_time.minute.toString().padLeft(2, '0')}'; // 18:00

    print('==================== DUTY DONE ====================');
    print('---- iUserId ----> ${widget.user.id}');
    print('---- Name    ----> ${widget.user.name}');
    print('---- dDate   ----> $dDate');
    print('---- dTime   ----> $dTime');
    print('===================================================');

    // TODO(api): POST the duty here, e.g.
    //   final res = await FrequentUserDutyRepo().createDuty(
    //     context, iUserId: widget.user.id, dDate: dDate, dTime: dTime,
    //   );
    // then show SuccessDialog / FailureDialog on the Result flag, the way
    // the invite flow does, before popping.

    // Grab both before popping — this context is torn down with the dialog
    // route, same as the invite sheet does.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final summary = '${widget.user.name} · $_dateLabel, $dTime';

    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(summary)));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.user.name,
                        style: t.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('Assign duty', style: t.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  color: AppColors.muted,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _PickerField(
              label: 'Select Date',
              value: _dateLabel,
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.lg),
            _PickerField(
              label: 'Select Time',
              value: _time.format(context),
              icon: Icons.schedule_rounded,
              onTap: _pickTime,
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(label: 'Duty Done', onPressed: _onDutyDone),
          ],
        ),
      ),
    );
  }
}

/// Label above a tappable value with a trailing affordance icon — the same
/// field the invite setup sheet uses, so both flows feel identical.
class _PickerField extends StatelessWidget {
  const _PickerField({
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

/// Full-height placeholder for the empty / error states.
class _ListMessage extends StatelessWidget {
  const _ListMessage({required this.icon, required this.message, this.onRetry});

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.faint),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: AppColors.brand),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
