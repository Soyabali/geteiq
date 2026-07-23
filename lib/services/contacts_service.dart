import 'package:flutter_contacts/flutter_contacts.dart';

import '../models/invite.dart';

/// Reads the REAL phone contacts (iOS + Android) and turns each one into a
/// [Guest] — the exact same shape as the old static `DemoData.contacts`.
///
/// Works on a test phone with no SIM: contacts live in the phone's address
/// book, not on the SIM.
class ContactsService {
  /// Result of a load attempt so the UI can tell "denied" apart from "empty".
  static Future<ContactsResult> loadDeviceContacts() async {
    // 1) Ask for permission -> this shows the system popup the first time.
    //    `readonly: true` means we only want to READ contacts, not edit them.
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      return const ContactsResult(guests: [], permissionGranted: false);
    }

    // 2) Read every contact WITH its details (name + phone numbers).
    final contacts = await FlutterContacts.getContacts(withProperties: true);

    // 3) Map each phone contact -> Guest(name, phone), same as static data.
    final guests = <Guest>[];
    for (final c in contacts) {
      if (c.phones.isEmpty) continue; // skip contacts that have no number
      final name = c.displayName.trim();
      final phone = c.phones.first.number.trim(); // take the first number
      if (name.isEmpty || phone.isEmpty) continue;
      guests.add(Guest(name: name, phone: phone));
    }

    // 4) Sort A -> Z like a normal phone book.
    guests.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return ContactsResult(guests: guests, permissionGranted: true);
  }
}

/// Small holder so the screen knows both the list and whether access was given.
class ContactsResult {
  const ContactsResult({
    required this.guests,
    required this.permissionGranted,
  });

  final List<Guest> guests;
  final bool permissionGranted;
}
