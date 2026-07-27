import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/session.dart';
import '../models/user_role.dart';
import '../services/getOtp.dart';
import '../services/validateOtp.dart';
import '../services/vmsUpdateVisitorGsmid.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/failure_dialog.dart';
import 'dashboard_screen.dart';

/// Screen 3 — mobile number, then a 4-digit OTP.
///
/// Flow:
///   1) Enter a valid 10-digit number -> tap "Send OTP" -> FIRST api (getOtp),
///      spinner shows inside the Send OTP button.
///   2) On success the OTP box appears. Typing the 4 digits (test: 1982)
///      auto-fires the SECOND api (validateOtp) with otp + mobile.
///   3) Any api failure shows the reusable [FailureDialog].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.role = UserRole.management});

  final UserRole role;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _otpFocus = FocusNode();

  bool _otpSent = false;
  bool _sendingOtp = false; // first api in progress (Send OTP button spinner)
  bool _verifying = false; // second api in progress (bottom button spinner)
  int _resendIn = 0;
  Timer? _resendTimer;

  static const _otpLength = 4;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
    _otp.addListener(() => setState(() {}));
    _setupPushNotifications();
  }

  void _setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    final token = await fcm.getToken();
    print("Token : $token");
    //updateGsmid(token);
    if(token!=null){
      updateGsmid(token);
    }
  }
  // FirebaseTokenApi
  updateGsmid(token) async {
    if (token != null) {
      print("--------68----xxx----$token");
      var UpdateGsmid = await VmsUpdateVisitorgsmid().vmsUpdateVisitorGsmid(
        context,
        token,
      );
      print("-------Update Gsmid Visitor-------70-----$UpdateGsmid");
    } else {}
  }


  @override
  void dispose() {
    _resendTimer?.cancel();
    _phone.dispose();
    _otp.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  /// Indian mobile numbers: 10 digits, ignoring any spaces the user typed.
  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');
  bool get _phoneValid => _digits.length == 10;
  bool get _canLogin => _otpSent && _otp.text.length == _otpLength;
  bool get _isGuard => widget.role == UserRole.guard;

  // ===================== STEP 1 : send OTP (first api) =====================
  Future<void> _sendOtp() async {
    if (!_phoneValid || _sendingOtp) return;
    FocusScope.of(context).unfocus();
    setState(() => _sendingOtp = true);

    try {
      final res = await GetOtpRepo().getOtp(context, _digits);
      print("------getOtpResponse----------$res");
      if (!mounted) return;

      final result = "${res['Result']}";
      final msg = "${res['Msg']}";

      if (result == "1") {
        // Success -> reveal the OTP box + start the resend timer.
        setState(() => _otpSent = true);
        _startResendCountdown();
        Future<void>.delayed(const Duration(milliseconds: 220), () {
          if (mounted) _otpFocus.requestFocus();
        });
      } else {
        await FailureDialog.show(
          context,
          msg.isEmpty ? 'Could not send OTP. Please try again.' : msg,
        );
      }
    } catch (e) {
      print("------getOtp error----------$e");
      if (!mounted) return;
      await FailureDialog.show(
        context,
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  // =================== STEP 2 : verify OTP (second api) ===================
  Future<void> _verifyOtp() async {
    if (!_canLogin || _verifying) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);

    final otpNumber = _otp.text.trim(); // test OTP: 1982
    final phoneNumber = _digits;

    try {
      final res = await ValidateOtpRepo().validateOtp(
        context,
        otpNumber,
        phoneNumber,
      );
      print("------validateOtpResponse----------$res");
      if (!mounted) return;

      final result = "${res['Result']}";
      final msg = "${res['Msg']}";

      if (result == "1") {
        // Save the user detail and open the dashboard.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sUserName', "${res['sUserName']}");
        await prefs.setString('sContactNo', "${res['sContactNo']}");
        await prefs.setString('iUserType', "${res['iUserType']}");
        await prefs.setString('sEmailId', "${res['sEmailId']}");
        await prefs.setBool('isLoggedIn', true);
        if (!mounted) return;

        AppSession.signIn(widget.role);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        await FailureDialog.show(
          context,
          msg.isEmpty ? 'Invalid OTP. Please try again.' : msg,
        );
      }
    } catch (e) {
      print("------login error----------$e");
      if (!mounted) return;
      await FailureDialog.show(
        context,
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  static String _formatted(String digits) => digits.length == 10
      ? '${digits.substring(0, 5)} ${digits.substring(5)}'
      : digits;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header: back + SECURE ACCESS ----
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Padding(
                        padding: EdgeInsets.only(right: AppSpacing.md),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  Text(
                    'Secure access',
                    style: t.labelSmall?.copyWith(
                      color: AppColors.faint,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),

            // ---- Scrollable content ----
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(isGuard: _isGuard),
                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      _isGuard
                          ? 'Guard mobile number'
                          : 'Management mobile number',
                      style: t.bodyMedium?.copyWith(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Phone + Send OTP row.
                    SizedBox(
                      height: 52,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _phoneField(t)),
                          const SizedBox(width: AppSpacing.sm),
                          _DarkButton(
                            label: _resendIn > 0 ? '${_resendIn}s' : 'Send OTP',
                            loading: _sendingOtp,
                            enabled: _phoneValid && _resendIn == 0,
                            onTap: _sendOtp,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // OTP card (after send) OR the hint box (before send).
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _otpSent ? _otpCard(t) : _infoBox(t),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Bottom: primary button + policy line ----
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  PrimaryButton(
                    label: _isGuard ? 'Enter Guard Desk' : 'Enter Dashboard',
                    loading: _verifying,
                    onPressed: _canLogin ? _verifyOtp : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'By continuing you agree to society visitor policy',
                    textAlign: TextAlign.center,
                    style: t.labelSmall?.copyWith(color: AppColors.faint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- +91 phone field (bordered box) ----
  Widget _phoneField(TextTheme t) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border, width: 1.4),
      ),
      child: Row(
        children: [
          Text(
            '+91',
            style: t.titleSmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              textAlignVertical: TextAlignVertical.center,
              onSubmitted: (_) => _sendOtp(),
              style: t.titleMedium,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                _PhoneSpacer(),
              ],
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '98765 43210',
                hintStyle: t.titleMedium?.copyWith(color: AppColors.faint),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- OTP card ----
  Widget _otpCard(TextTheme t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: const Color(0xFFE4E2DB), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter 4-digit OTP',
            style: t.bodyMedium?.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: AppSpacing.md),
          _OtpField(
            controller: _otp,
            focusNode: _otpFocus,
            length: _otpLength,
            onCompleted: (_) => _verifyOtp(), // auto-fire the second api
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Flexible(
                child: Text(
                  'Code sent to +91 ${_formatted(_digits)}  ·  ',
                  style: t.bodySmall?.copyWith(color: AppColors.faint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _resendIn == 0 ? _sendOtp : null,
                child: Text(
                  _resendIn > 0 ? 'Resend in ${_resendIn}s' : 'Resend',
                  style: t.bodySmall?.copyWith(
                    color: _resendIn > 0 ? AppColors.faint : AppColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Hint box (before OTP is sent) ----
  Widget _infoBox(TextTheme t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.35)),
      ),
      child: Text.rich(
        TextSpan(
          style: t.bodySmall?.copyWith(
            color: const Color(0xFF9A5A38),
            height: 1.45,
          ),
          children: const [
            TextSpan(text: 'Enter your mobile number and tap '),
            TextSpan(
              text: 'Send OTP',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text:
                  ' to continue. One login keeps guest flow secure from lobby to flat.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient hero card at the top of the login screen.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isGuard});

  final bool isGuard;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6E3410), Color(0xFFD4470A), Color(0xFFEA530A)],
          ),
        ),
        child: Stack(
          children: [
            // Big faint "IQ" watermark.
            Positioned(
              right: -14,
              bottom: -34,
              child: Text(
                'IQ',
                style: TextStyle(
                  fontSize: 120,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'gateIQ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: 250,
                    child: Text(
                      isGuard
                          ? 'Open the gate desk'
                          : 'Sign in to manage guests',
                      style: t.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: 260,
                    child: Text(
                      isGuard
                          ? 'Verify QR, log walk-ins, and keep the lobby moving.'
                          : 'Approve visits, track check-ins, and stay in control.',
                      style: t.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark "Send OTP" button with an in-center spinner while the api runs.
class _DarkButton extends StatelessWidget {
  const _DarkButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    return AnimatedOpacity(
      opacity: active || loading ? 1 : 0.5,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: active ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            constraints: const BoxConstraints(minWidth: 104),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _OtpField extends StatelessWidget {
  const _OtpField({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final ValueChanged<String> onCompleted;

  @override
  Widget build(BuildContext context) {
    final base = PinTheme(
      width: 58,
      height: 58,
      textStyle: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontSize: 22, color: AppColors.ink),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: const Color(0xFFD8D6CE)),
      ),
    );

    return Pinput(
      length: length,
      controller: controller,
      focusNode: focusNode,
      onCompleted: onCompleted,
      keyboardType: TextInputType.number,
      defaultPinTheme: base,
      focusedPinTheme: base.copyWith(
        decoration: base.decoration!.copyWith(
          border: Border.all(color: AppColors.brand, width: 1.8),
          boxShadow: AppShadows.card,
        ),
      ),
      submittedPinTheme: base.copyWith(
        decoration: base.decoration!.copyWith(
          color: AppColors.brandTint,
          border: Border.all(color: AppColors.brand),
        ),
      ),
      separatorBuilder: (_) => const SizedBox(width: AppSpacing.md),
    );
  }
}

/// Renders the number as `98765 43210` while keeping the raw value digits-only.
class _PhoneSpacer extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 5) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
