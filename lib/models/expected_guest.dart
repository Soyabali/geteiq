/// Where an expected guest currently sits in the gate flow (guard side).
enum GuestStage {
  expected('Expected'),
  checkin('Check-in'),
  meeting('Meeting'),
  checkout('Check-out');

  const GuestStage(this.label);

  /// Chip / status label shown in the UI.
  final String label;
}

/// A guard-side "expected guest" (or a small group under one host booking).
class ExpectedGuest {
  const ExpectedGuest({
    required this.name,
    required this.when,
    required this.stage,
    this.plus = 0,
    this.people = '',
    this.phone = '',
    this.duration = '—',
    this.note = '—',
    this.approval = 'APPROVED',
  });

  final String name;
  final int plus; // extra guests count, e.g. +3
  final String people; // "Ram, Shyam, Anil" — empty -> show [phone] instead
  final String phone;
  final String when; // "Today · 4:30 PM"
  final String duration; // "3 hrs"
  final String note;
  final String approval; // badge text
  final GuestStage stage;

  /// Returns a copy with a new stage (used when the guard taps an action).
  ExpectedGuest copyWith({GuestStage? stage}) => ExpectedGuest(
    name: name,
    plus: plus,
    people: people,
    phone: phone,
    when: when,
    duration: duration,
    note: note,
    approval: approval,
    stage: stage ?? this.stage,
  );

  String get searchText => '$name $people $phone $note'.toLowerCase();
}

/// Static sample data for the Expected Guests screen (guard view).
/// Swap this for a REST call later — the screen only needs a `List<ExpectedGuest>`.
const List<ExpectedGuest> kExpectedGuestsDemo = [
  ExpectedGuest(
    name: 'Ram Kumar',
    plus: 3,
    people: 'Ram, Shyam, Anil',
    when: 'Today · 4:30 PM',
    duration: '3 hrs',
    note: 'HR interview panel',
    stage: GuestStage.expected,
  ),
  ExpectedGuest(
    name: 'Priya Mehta',
    plus: 1,
    people: 'Priya, Kabir',
    when: 'Today · 11:10 AM',
    duration: '2 hrs',
    note: 'Sales demo',
    stage: GuestStage.checkin,
  ),
  ExpectedGuest(
    name: 'Amit Verma',
    phone: '+91 99001 11223',
    when: 'Today · 6:00 PM',
    duration: '1 hr',
    note: 'Vendor meeting',
    stage: GuestStage.meeting,
  ),
  ExpectedGuest(
    name: 'Neha Gupta',
    phone: '+91 98730 11294',
    when: 'Today · 9:30 AM',
    duration: '45 min',
    note: 'Document pickup',
    stage: GuestStage.checkout,
  ),
  ExpectedGuest(
    name: 'Rohit Verma',
    plus: 2,
    people: 'Rohit, Sana, Dev',
    when: 'Today · 2:00 PM',
    duration: '1 hr 30 min',
    note: 'Client visit',
    stage: GuestStage.expected,
  ),
];
