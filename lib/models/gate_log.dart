/// One "Gate Log" entry — a guest the guard logged/invited at the gate.
class GateLogEntry {
  const GateLogEntry({
    required this.name,
    required this.when,
    required this.meetWith,
    this.plus = 0,
    this.duration = '—',
    this.note = '',
    this.approved = false,
  });

  final String name;
  final int plus; // extra guests, e.g. +1
  final String when; // "Today · 9:40 AM"
  final String duration; // "20 min"
  final String meetWith; // "T 1 304 · Jitender"
  final String note; // management note added on this screen
  final bool approved;

  GateLogEntry copyWith({String? note, bool? approved}) => GateLogEntry(
    name: name,
    plus: plus,
    when: when,
    duration: duration,
    meetWith: meetWith,
    note: note ?? this.note,
    approved: approved ?? this.approved,
  );

  String get searchText => '$name $meetWith $note'.toLowerCase();
}

/// Static sample data. Swap for an API list later — the screen only needs a
/// `List<GateLogEntry>`.
const List<GateLogEntry> kGateLogDemo = [
  GateLogEntry(
    name: 'BlueDart Delivery',
    when: 'Today · 9:40 AM',
    duration: '20 min',
    meetWith: 'T 1 304 · Jitender',
    approved: true,
  ),
  GateLogEntry(
    name: 'Courier Boy',
    when: 'Today · 8:15 AM',
    duration: '10 min',
    meetWith: 'Reception',
    approved: true,
  ),
  GateLogEntry(
    name: 'AC Service Vendor',
    plus: 1,
    when: 'Today · 2:00 PM',
    duration: '2 hrs',
    meetWith: 'Facilities · Floor 2',
  ),
  GateLogEntry(
    name: 'Walk-in Visitor',
    when: 'Today · 11:30 AM',
    duration: '30 min',
    meetWith: 'Gate 2',
  ),
  GateLogEntry(
    name: 'Plumber',
    when: 'Today · 4:00 PM',
    duration: '45 min',
    meetWith: 'B 2 210 · Sneha',
  ),
];
