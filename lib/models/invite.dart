import 'dart:math';
import 'package:flutter/foundation.dart';

/// A person being invited through the gate.
@immutable
class Guest {
  const Guest({required this.name, required this.phone});

  final String name;
  final String phone;

  /// Initials for the avatar circle, e.g. "Ravi Yadav" -> "RY".
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Guest copyWith({String? name, String? phone}) =>
      Guest(name: name ?? this.name, phone: phone ?? this.phone);

  @override
  bool operator ==(Object other) =>
      other is Guest && other.name == name && other.phone == phone;

  @override
  int get hashCode => Object.hash(name, phone);
}

/// How often the invite may be used.
enum InviteFrequency { once, frequently }

/// The invite being composed across the Invite Setup → Select Guests →
/// Invite Details → Ticket flow.
class Invite {
  Invite({
    this.frequency = InviteFrequency.once,
    this.isPrivate = false,
    DateTime? date,
    this.startTime,
    this.validForHours = 8,
    List<Guest>? guests,
    this.note = '',
    String? code,
  }) : date = date ?? DateTime.now(),
       guests = guests ?? <Guest>[],
       code = code ?? _generateCode();

  InviteFrequency frequency;
  bool isPrivate;
  DateTime date;
  TimeOfDayValue? startTime;
  int validForHours;
  List<Guest> guests;
  String note;

  /// The 6-digit gate code shown on the pass.
  final String code;

  DateTime get startsAt {
    final t = startTime ?? TimeOfDayValue.fromDateTime(DateTime.now());
    return DateTime(date.year, date.month, date.day, t.hour, t.minute);
  }

  DateTime get endsAt => startsAt.add(Duration(hours: validForHours));

  static String _generateCode() {
    final r = Random();
    return List.generate(6, (_) => r.nextInt(10)).join();
  }
}

/// Minimal time holder so models stay free of Flutter widget imports
/// where possible, while still converting cleanly to `TimeOfDay`.
@immutable
class TimeOfDayValue {
  const TimeOfDayValue({required this.hour, required this.minute});

  factory TimeOfDayValue.fromDateTime(DateTime d) =>
      TimeOfDayValue(hour: d.hour, minute: d.minute);

  final int hour;
  final int minute;
}
