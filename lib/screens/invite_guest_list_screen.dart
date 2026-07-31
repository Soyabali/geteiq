import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/guard_visitor.dart';
import '../models/guest_entry.dart';
import '../services/VisitorListRepo.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pill_search_field.dart';

/// Tablet breakpoint. Phones (< 600) always render the original, untouched
/// single-column mobile list.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;

/// Landscape / large tablets get a 3-column grid; portrait-ish tablets get 2.
bool _isWideTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

/// "Invite guest list" (management side) — the visits the logged-in manager
/// raised, via [VisitorListRepo].
///
/// The dashboard routes here when `iUserType != "1"`; guards get
/// [ExpectedGuestScreen] instead.
///
/// Note: this API returns no contact number, so the row shows the QR code
/// value where the mock had a phone — see [_GuestRow].
class InviteGuestListScreen extends StatefulWidget {
  const InviteGuestListScreen({super.key});

  @override
  State<InviteGuestListScreen> createState() => _InviteGuestListScreenState();
}

class _InviteGuestListScreenState extends State<InviteGuestListScreen> {
  final _search = TextEditingController();

  List<GuardVisitor> _all = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      // Routed here only for managers, but go through the dispatcher anyway
      // so every list screen resolves its endpoint the same way.
      final range = VisitorListRepo.today;
      final list = await VisitorListRepo().getVisitorList(
        context,
        fromDate: range.start,
        toDate: range.end,
      );
      if (!mounted) return;
      setState(() {
        _all = list;
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

  List<GuardVisitor> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((v) {
      return v.guestNames.toLowerCase().contains(q) ||
          v.userName.toLowerCase().contains(q) ||
          v.qrCodeVal.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.gutter(context);
    final rows = _filtered;
    final isTablet = _isTablet(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: gutter,
        leadingWidth: gutter + 32,
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: const Text('Invite Guest List'),
      ),
      body: SafeArea(
        bottom: false,
        child: isTablet
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          AppSpacing.md,
                          gutter,
                          AppSpacing.lg,
                        ),
                        child: PillSearchField(
                          controller: _search,
                          hint: 'Search invited guests',
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      Expanded(child: _body(rows, gutter)),
                    ],
                  ),
                ),
              )
            : CenteredFill(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        AppSpacing.xs,
                        gutter,
                        AppSpacing.md,
                      ),
                      child: PillSearchField(
                        controller: _search,
                        hint: 'Search invited guests',
                        onChanged: () => setState(() {}),
                      ),
                    ),
                    Expanded(child: _body(rows, gutter)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _body(List<GuardVisitor> rows, double gutter) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }
    if (_error) {
      return _ListMessage(
        icon: Icons.wifi_off_rounded,
        message: "Couldn't load the guest list.",
        onRetry: _load,
      );
    }
    if (rows.isEmpty) {
      return _ListMessage(
        icon: Icons.people_outline_rounded,
        message: _search.text.trim().isEmpty
            ? 'No Data'
            : 'No guests match "${_search.text.trim()}"',
      );
    }

    if (_isTablet(context)) {
      return _GuestGrid(rows: rows, gutter: gutter);
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.xs,
        gutter,
        AppSpacing.xxl,
      ),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) => _GuestCard(visitor: rows[i]),
    );
  }
}

/// Tablet grid — 2 columns on portrait/medium tablets, 3 on wide landscape,
/// so the list actually uses the extra width instead of floating a single
/// phone-width column in the middle of the screen.
class _GuestGrid extends StatelessWidget {
  const _GuestGrid({required this.rows, required this.gutter});

  final List<GuardVisitor> rows;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _isWideTablet(context) ? 3 : 2;
    const spacing = AppSpacing.md;

    // A Wrap of fixed-width cards — not a fixed-extent GridView — so each
    // card keeps its own natural height (some rows have an optional second
    // "+N other names" line, so heights genuinely vary). This trades
    // perfectly aligned row heights for zero risk of clipped/overflowing
    // card content.
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - gutter * 2;
        final cardWidth =
            (available - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.xs,
            gutter,
            AppSpacing.xxl,
          ),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final v in rows)
                SizedBox(width: cardWidth, child: _GuestCard(visitor: v)),
            ],
          ),
        );
      },
    );
  }
}

/// One list row.
///
/// Field mapping — the API has no contact number, so the second line carries
/// the QR code value instead:
///   sGuestNames  -> "Amit Sharma  +1"  (+ the rest in brackets)
///   sQRCodeVal   -> "QR Code : 493893"
///   dDate/dTime  -> "Today · 3:58 PM"
///   iValidHours  -> "· 8 Hour(s)"
///   sStatus      -> the coloured chip on the right
class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.visitor});

  final GuardVisitor visitor;

  /// "Amit Sharma, Priya Nair" -> ["Amit Sharma", "Priya Nair"]
  List<String> get _names => visitor.guestNames
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// "Today · 3:58 PM · 8 Hour(s)" — falls back to the raw strings if the
  /// backend ever sends a date this can't parse.
  String get _meta {
    final duration = visitor.validHours.trim();
    String when;
    try {
      final dt = DateTime.parse('${visitor.date} ${visitor.time}');
      final day = DateTime(dt.year, dt.month, dt.day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final label = switch (day.difference(today).inDays) {
        0 => 'Today',
        1 => 'Tomorrow',
        -1 => 'Yesterday',
        _ => DateFormat('d MMM yyyy').format(dt),
      };
      when = '$label · ${DateFormat('h:mm a').format(dt)}';
    } catch (_) {
      when = '${visitor.date} ${visitor.time}'.trim();
    }
    return duration.isEmpty ? when : '$when · $duration';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final names = _names;
    final first = names.isEmpty ? '—' : names.first;
    final extra = names.length > 1 ? names.length - 1 : 0;
    final rest = names.length > 1 ? names.sublist(1).join(', ') : '';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: guest name +N ............................ status chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            first,
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (extra > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '+$extra',
                            style: t.titleSmall?.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (rest.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '($rest)',
                        style: t.bodySmall?.copyWith(color: AppColors.faint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(status: GuestStatus.fromApi(visitor.status)),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: AppSpacing.md),

          // Labels are passed WITHOUT the ":" — _MetaLine draws it in its own
          // fixed column so every colon lines up vertically down the card.
          _MetaLine(
            icon: Icons.qr_code_rounded,
            label: 'QR Code',
            value: visitor.qrCodeVal.isEmpty ? '—' : visitor.qrCodeVal,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetaLine(
            icon: Icons.schedule_rounded,
            label: 'Date / Time',
            value: _meta,
          ),
          const SizedBox(height: AppSpacing.sm),
          // dCheckedIn / dCheckedOut — null until the guard acts on the pass,
          // which the model maps to '', so the value reads blank.
          _MetaLine(
            icon: Icons.login_rounded,
            label: 'Checked In',
            value: visitor.checkedIn,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetaLine(
            icon: Icons.logout_rounded,
            label: 'Checked Out',
            value: visitor.checkedOut,
          ),
        ],
      ),
    );
  }
}

/// A small "icon  Label : value" line inside the card.
///
/// [label] is passed WITHOUT its colon. The label sits in a fixed-width box
/// and the ":" is drawn as its own widget right after it, so the colons of
/// every row land on the same vertical line no matter how long the label is.
class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Width of the label column — sized for the longest label on this card
  /// ("Checked Out" / "Date / Time"), which is what fixes the colon's x
  /// position. Scaled down from the 96 the Yesterday/Month cards use, since
  /// those label rows are bodyMedium and these are the smaller bodySmall.
  static const double _labelWidth = 88;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final labelStyle = t.bodySmall?.copyWith(color: AppColors.faint);

    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.faint),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: _labelWidth,
          child: Text(
            label,
            style: labelStyle,
            maxLines: 1,
            // Degrades gracefully instead of overflowing if a future label is
            // longer than the column, or at a large OS text scale.
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // The shared colon column.
        Text(':', style: labelStyle),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            value,
            style: t.bodySmall?.copyWith(color: AppColors.inkSoft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final GuestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 12.5,
          color: status.foreground,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// Full-height centred message for the empty / error states.
class _ListMessage extends StatelessWidget {
  const _ListMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.faint),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: t.bodyMedium),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  textStyle: t.titleSmall,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
