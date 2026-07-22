import 'package:flutter/material.dart';

import '../data/guest_list_repository.dart';
import '../models/guest_entry.dart';
import '../theme/tokens.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pill_search_field.dart';

/// Reusable "guest list with a search bar" screen (see the invite-guest-list
/// mock). It renders whatever [repository] returns, so the dashboard entry
/// points (Invite / Guard / Yesterday) share one UI while each keeps its own
/// data source. Loading / empty / error are all handled here.
class GuestListScreen extends StatefulWidget {
  const GuestListScreen({
    super.key,
    required this.title,
    required this.repository,
    this.searchHint = 'Search guests',
    this.emptyMessage = 'No guests to show',
  });

  final String title;
  final GuestListRepository repository;
  final String searchHint;
  final String emptyMessage;

  @override
  State<GuestListScreen> createState() => _GuestListScreenState();
}

class _GuestListScreenState extends State<GuestListScreen> {
  final _search = TextEditingController();
  late Future<List<GuestEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchGuests();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() =>
      setState(() => _future = widget.repository.fetchGuests());

  /// Client-side filter by name or phone. When the API paginates/searches
  /// server-side, forward `_search.text` to the repository instead.
  List<GuestEntry> _filter(List<GuestEntry> all) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return all.where((g) {
      final nameHit = g.name.toLowerCase().contains(q);
      final phoneHit = digits.isNotEmpty &&
          g.phone.replaceAll(RegExp(r'\D'), '').contains(digits);
      return nameHit || phoneHit;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.gutter(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: gutter,
        leadingWidth: gutter + 32,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(widget.title),
      ),
      body: SafeArea(
        bottom: false,
        child: CenteredFill(
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
                  hint: widget.searchHint,
                  onChanged: () => setState(() {}),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<GuestEntry>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brand,
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return _ListMessage(
                        icon: Icons.wifi_off_rounded,
                        message: "Couldn't load guests.",
                        onRetry: _reload,
                      );
                    }
                    final rows = _filter(snap.data ?? const []);
                    if (rows.isEmpty) {
                      return _ListMessage(
                        icon: Icons.people_outline_rounded,
                        message: _search.text.trim().isEmpty
                            ? widget.emptyMessage
                            : 'No guests match "${_search.text.trim()}"',
                      );
                    }
                    return _GuestList(rows: rows, gutter: gutter);
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

/// White surface holding the rows, separated by hairline dividers.
class _GuestList extends StatelessWidget {
  const _GuestList({required this.rows, required this.gutter});

  final List<GuestEntry> rows;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: AppSpacing.xxl),
        itemCount: rows.length,
        separatorBuilder: (_, __) => Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: const Divider(height: 1),
        ),
        itemBuilder: (context, i) =>
            _GuestEntryTile(entry: rows[i], gutter: gutter),
      ),
    );
  }
}

class _GuestEntryTile extends StatelessWidget {
  const _GuestEntryTile({required this.entry, required this.gutter});

  final GuestEntry entry;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter, vertical: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.name,
                  style: t.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  entry.phone,
                  style: t.bodySmall?.copyWith(color: AppColors.faint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.meta,
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _StatusChip(status: entry.status),
        ],
      ),
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
