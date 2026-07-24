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
  );
}
