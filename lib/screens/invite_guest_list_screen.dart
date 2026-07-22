import 'package:flutter/material.dart';

import '../data/guest_list_repository.dart';
import 'guest_list_screen.dart';

/// "Invite guest list" entry point.
///
/// A thin wrapper over [GuestListScreen] so this list can later diverge from
/// the others (its own endpoint, columns, row actions) without disturbing the
/// shared UI. To go live, edit [InviteGuestListRepository.fetchGuests].
class InviteGuestListScreen extends StatelessWidget {
  const InviteGuestListScreen({super.key});

  @override
  Widget build(BuildContext context) => const GuestListScreen(
    title: 'Invite guest list',
    repository: InviteGuestListRepository(),
    searchHint: 'Search invited guests',
    emptyMessage: 'No invited guests yet',
  );
}
