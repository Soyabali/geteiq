/// Which side of the gate the signed-in user sits on.
///
/// Set once at login (see `LoginScreen`) and read from `AppSession` wherever
/// behavior needs to branch — e.g. the dashboard's "Add Guest" button opens a
/// different flow for a guard than for management.
enum UserRole {
  management('Management'),
  guard('Guard');

  const UserRole(this.label);

  /// Display label used on the role-select screen.
  final String label;
}
