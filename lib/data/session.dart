import '../models/user_role.dart';

/// Minimal in-memory record of who is signed in right now.
///
/// Deliberately static and simple: `LoginScreen` calls [signIn] once the OTP
/// is verified, and anything that needs to branch by role — e.g. the
/// dashboard's "Add Guest" button — reads [currentRole] from here. When a
/// real auth/session API lands, swap the body of [signIn] (and add
/// persistence / hydration on app start) — every call site that reads
/// [currentRole] stays the same.
class AppSession {
  const AppSession._();

  static UserRole _role = UserRole.management;

  /// Defaults to [UserRole.management] so any screen reached without going
  /// through login (tests, direct navigation during development) keeps the
  /// original, pre-role-aware behavior.
  static UserRole get currentRole => _role;

  static void signIn(UserRole role) => _role = role;
}
