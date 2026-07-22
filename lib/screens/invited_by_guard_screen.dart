import 'package:flutter/material.dart';

import '../data/guest_list_repository.dart';
import 'guest_list_screen.dart';

/// "Invited by Guard" entry point.
///
/// Same UI as the other lists, but its own widget + data source. To go live,
/// edit [InvitedByGuardRepository.fetchGuests].
class InvitedByGuardScreen extends StatelessWidget {
  const InvitedByGuardScreen({super.key});

  @override
  Widget build(BuildContext context) => const GuestListScreen(
    title: 'Invited by Guard',
    repository: InvitedByGuardRepository(),
    searchHint: 'Search guard entries',
    emptyMessage: 'No guard entries yet',
  );
}
