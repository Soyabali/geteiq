import '../models/guest_entry.dart';
import 'demo_data.dart';

/// Source of rows for a [GuestListScreen].
///
/// Today each implementation returns static [DemoData]; tomorrow swap the body
/// for a REST call. The screens depend only on this interface, so switching
/// from dummy to live data touches **nothing else**.
abstract interface class GuestListRepository {
  Future<List<GuestEntry>> fetchGuests();
}

/// "Invite guest list" — people the resident invited.
class InviteGuestListRepository implements GuestListRepository {
  const InviteGuestListRepository();

  @override
  Future<List<GuestEntry>> fetchGuests() async {
    // TODO(api): replace with the real endpoint, e.g.
    //   final res = await dio.get('/guests/invited');
    //   return (res.data as List)
    //       .map((e) => GuestEntry.fromJson(e as Map<String, dynamic>))
    //       .toList();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return DemoData.invitedGuests;
  }
}

/// "Invited by Guard" — walk-ins the guard registered.
class InvitedByGuardRepository implements GuestListRepository {
  const InvitedByGuardRepository();

  @override
  Future<List<GuestEntry>> fetchGuests() async {
    // TODO(api): GET /guests/by-guard  →  map with GuestEntry.fromJson
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return DemoData.guardEntries;
  }
}

/// "Yesterday guest list" — everyone from the previous day.
class YesterdayGuestListRepository implements GuestListRepository {
  const YesterdayGuestListRepository();

  @override
  Future<List<GuestEntry>> fetchGuests() async {
    // TODO(api): GET /guests?day=yesterday  →  map with GuestEntry.fromJson
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return DemoData.yesterdayGuests;
  }
}
