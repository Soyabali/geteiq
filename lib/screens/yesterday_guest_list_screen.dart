import 'package:flutter/material.dart';

import '../data/guest_list_repository.dart';
import 'guest_list_screen.dart';

/// "Yesterday guest list" entry point.
///
/// Same UI as the other lists, but its own widget + data source. To go live,
/// edit [YesterdayGuestListRepository.fetchGuests].
class YesterdayGuestListScreen extends StatelessWidget {
  const YesterdayGuestListScreen({super.key});

  @override
  Widget build(BuildContext context) => const GuestListScreen(
    title: 'Yesterday guest list',
    repository: YesterdayGuestListRepository(),
    searchHint: "Search yesterday's guests",
    emptyMessage: 'No guests from yesterday',
  );
}
