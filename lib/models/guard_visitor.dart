/// One row from the guard's visitor request list API
/// (VMSGaurdVisitorRequestList). Maps the raw JSON 1:1.
class GuardVisitor {
  const GuardVisitor({
    required this.qrCodeVal,
    required this.date,
    required this.time,
    required this.validHours,
    required this.note,
    required this.userName,
    required this.requiredAt,
    required this.status,
    required this.guestNames,
    this.checkedIn = '',
    this.checkedOut = '',
  });

  final String qrCodeVal; // sQRCodeVal  e.g. "911309"
  final String date; // dDate        e.g. "2026-07-24"
  final String time; // dTime        e.g. "18:00:00"
  final String validHours; // iValidHours  e.g. "4 Hour(s)"
  final String note; // sNote
  final String userName; // sUserName    (shown as the card name)
  final String requiredAt; // dRequiredAt  e.g. "24/Jul/2026 12:02"
  final String status; // sStatus      e.g. "Pending"
  final String guestNames; // sGuestNames  e.g. "Samsung Helpline"

  /// dCheckedIn — when the guard checked the guest in. The API sends `null`
  /// until it happens, which maps to '' here so the UI can show nothing.
  final String checkedIn;

  /// dCheckedOut — when the guard checked the guest out. `null` -> ''.
  final String checkedOut;

  factory GuardVisitor.fromJson(Map<String, dynamic> j) => GuardVisitor(
    qrCodeVal: '${j['sQRCodeVal'] ?? ''}',
    date: '${j['dDate'] ?? ''}',
    time: '${j['dTime'] ?? ''}',
    validHours: '${j['iValidHours'] ?? ''}',
    note: '${j['sNote'] ?? ''}',
    userName: '${j['sUserName'] ?? ''}',
    requiredAt: '${j['dRequiredAt'] ?? ''}',
    status: '${j['sStatus'] ?? ''}',
    guestNames: '${j['sGuestNames'] ?? ''}',
    checkedIn: _str(j['dCheckedIn']),
    checkedOut: _str(j['dCheckedOut']),
  );

  /// Null-safe string read for the check-in / check-out timestamps. Also
  /// swallows a literal "null" string, which some rows come back with, so the
  /// card shows nothing instead of the word "null".
  static String _str(Object? v) {
    final s = '${v ?? ''}'.trim();
    return s.toLowerCase() == 'null' ? '' : s;
  }
}
