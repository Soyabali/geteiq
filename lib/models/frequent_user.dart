import 'package:flutter/foundation.dart';

/// One row on the Frequent User screen — a person who visits the office often
/// enough to get a standing duty slot instead of a fresh invite every time.
///
/// Kept flat so it maps 1:1 onto a JSON object from the API. When the endpoint
/// lands, only [FrequentUser.fromJson] needs the real key names — the screen
/// itself already works off `List<FrequentUser>` and needs no other change.
@immutable
class FrequentUser {
  const FrequentUser({
    required this.id,
    required this.name,
    this.phone = '',
    this.department = '',
    this.visitCount = 0,
  });

  /// Server id — sent back when the duty is created.
  final String id;
  final String name;
  final String phone;
  final String department;

  /// How many times the person has visited. 0 hides it from [meta].
  final int visitCount;

  /// Tolerant of missing / renamed keys so a partial response never throws,
  /// and string-coerced because the VMS APIs send numbers as strings
  /// (same defensive style as `GateEntry.fromJson`).
  factory FrequentUser.fromJson(Map<String, dynamic> j) => FrequentUser(
    id: '${j['iUserId'] ?? j['id'] ?? ''}',
    name: '${j['sUserName'] ?? j['sName'] ?? j['name'] ?? ''}'.trim(),
    phone: '${j['sContactNo'] ?? j['phone'] ?? ''}'.trim(),
    department: '${j['sDepartment'] ?? j['department'] ?? ''}'.trim(),
    visitCount:
        int.tryParse('${j['iVisitCount'] ?? j['visitCount'] ?? ''}') ?? 0,
  );

  /// Everything the search bar matches against.
  String get searchText => '$name $phone $department'.toLowerCase();

  /// Supporting line under the name. Empty when the API sent neither field,
  /// in which case the row renders the name alone.
  String get meta {
    final parts = [
      if (department.isNotEmpty) department,
      if (visitCount > 0) '$visitCount visits',
    ];
    return parts.join(' · ');
  }
}
