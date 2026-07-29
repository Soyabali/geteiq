/// One row from the VMSUsers list API (VMSUsers/VMSUsers).
///
/// Despite the department dropdown label, each option returned by this API is
/// really a user record — `sUserName` already bakes the department into the
/// display text, e.g. "Sakshi Begmal (Business Development (BD) )".
class VmsUser {
  const VmsUser({required this.userId, required this.userName});

  final int userId; // iUserId   e.g. 8
  final String userName; // sUserName e.g. "Sakshi Begmal (Business Development (BD) )"

  factory VmsUser.fromJson(Map<String, dynamic> j) => VmsUser(
    userId: int.tryParse('${j['iUserId'] ?? ''}') ?? 0,
    userName: '${j['sUserName'] ?? ''}',
  );

  // Equality by id so a previously-selected value still matches after the
  // list is re-fetched (a fresh fetch returns new VmsUser instances).
  @override
  bool operator ==(Object other) => other is VmsUser && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;
}
