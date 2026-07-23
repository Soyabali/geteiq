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
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import 'dashboard_screen.dart';

/// Screen 3 — mobile number, then a 4-digit OTP.
///
/// The OTP block only appears once a code has been "sent", which keeps the
/// first view as simple as the mockup.
class LoginScreen extends StatefulWidget {
  /// Defaults to [UserRole.management] so screens that reach this one
  /// directly (e.g. the splash screen currently skips role selection) keep
  /// today's behavior. [RoleSelectScreen] passes the picked role explicitly.
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
  bool _verifying = false;
  int _resendIn = 0;
  Timer? _resendTimer;

  static const _otpLength = 4;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
    _otp.addListener(() => setState(() {}));
    setupPushNotifications();
  }

  void setupPushNotifications() async{
    // Implement push notification setup logic here
   final fcm = FirebaseMessaging.instance;
   final token = await fcm.getToken();
   //final token = await fcm.getAPNSToken();
   print("Token : $token");
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

  // STEP 1 : user typed the mobile no and pressed "Send OTP".
  void _sendOtp() {
    if (!_phoneValid) return;
    FocusScope.of(context).unfocus();
    setState(() => _otpSent = true); // show the OTP box
    _startResendCountdown();

    // Give the box a beat to appear before pulling focus into it.
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _otpFocus.requestFocus();
    });

    // call the FIRST api -> send otp on this number
    getOtpResponse();
  }

  // FIRST API : VmsApiManagementGetOtp  (only sends the OTP)
  void getOtpResponse() async {
    // _digits = clean 10-digit number (no spaces)
    var getOtp = await GetOtpRepo().getOtp(context, _digits);
    print("------getOtpResponse----------$getOtp");
    if (!mounted) return;

    var result = "${getOtp['Result']}";
    var msg = "${getOtp['Msg']}";

    if (result == "1") {
      // OTP sent -> the OTP box is already visible, just tell the user.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('OTP sent to +91 ${_formatted(_digits)}')),
        );
    } else {
      // something went wrong -> show the api message
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$msg')));
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


  // STEP 2 : user filled the OTP and pressed "Login".
  // SECOND API : VmsApiManagementValidateOtp (mobileNo + otp -> verify).
  Future<void> _login() async {
    if (!_canLogin) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);

    // ================= CHANGE HERE (OTP value) =================
    // This sends whatever the user typed in the OTP box to the api.
    // While testing, the backend accepts the fixed OTP "1982",
    // so just type 1982 in the box and login will work.
    //
    // NOTE: if you ever want to FORCE a fixed test otp (ignore the box),
    // replace the line below with:  var otpNumber = "1982";
    var otpNumber = _otp.text.trim(); // otp from the box (type 1982 for now)
    // ===========================================================
    var phoneNumber = _digits;        // clean 10-digit number

    // call the SECOND api -> validate the otp
    var response = await ValidateOtpRepo().validateOtp(
      context,
      otpNumber,
      phoneNumber,
    );
    print("------validateOtpResponse----------$response");
    if (!mounted) return;
    setState(() => _verifying = false);

    var result = "${response['Result']}";
    var msg = "${response['Msg']}";

    if (result == "1") {
      // success -> save the user detail in sharedPreference
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('sUserName', "${response['sUserName']}");
      await prefs.setString('sContactNo', "${response['sContactNo']}");
      await prefs.setString('iUserType', "${response['iUserType']}");
      await prefs.setString('sEmailId', "${response['sEmailId']}");
      await prefs.setBool('isLoggedIn', true);
      if (!mounted) return;

      // go to the Dashboard
      AppSession.signIn(widget.role);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } else {
      // wrong otp / failed -> stay on screen and show the message
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$msg')));
    }
  }

  static String _formatted(String digits) => digits.length == 10
      ? '${digits.substring(0, 5)} ${digits.substring(5)}'
      : digits;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Login',
      bottomBar: PrimaryButton(
        label: 'Login',
        loading: _verifying,
        onPressed: _canLogin ? _login : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text('Enter Mobile No.', style: t.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _phone,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendOtp(),
                  style: t.titleLarge?.copyWith(letterSpacing: 0.4),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                    _PhoneSpacer(),
                  ],
                  decoration: const InputDecoration(
                    hintText: '98765 43210',
                    prefixText: '+91  ',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Send Otp button
              _SendOtpButton(
                enabled: _phoneValid && _resendIn == 0,
                label: _resendIn > 0 ? '${_resendIn}s' : 'Send OTP',
                onPressed: _sendOtp,
              ),
            ],
          ),
          // OTP block animates in only after a code has been sent.
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _otpSent
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter $_otpLength-digit code',
                          style: t.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _OtpField(
                          controller: _otp,
                          focusNode: _otpFocus,
                          length: _otpLength,
                          onCompleted: (_) => _login(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Text("Didn't get it?", style: t.bodySmall),
                            const SizedBox(width: AppSpacing.xs),
                            GestureDetector(
                              onTap: _resendIn == 0 ? _sendOtp : null,
                              child: Text(
                                _resendIn > 0
                                    ? 'Resend in ${_resendIn}s'
                                    : 'Resend',
                                style: t.bodySmall?.copyWith(
                                  color: _resendIn > 0
                                      ? AppColors.faint
                                      : AppColors.brand,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// Outlined pill matching the "Send OTP" control in the design.
class _SendOtpButton extends StatelessWidget {
  const _SendOtpButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          side: const BorderSide(color: AppColors.brand, width: 1.4),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Container(
            height: 46,
            constraints: const BoxConstraints(minWidth: 104),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.brand,
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
      height: 62,
      textStyle: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontSize: 24, color: AppColors.ink),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Pinput(
      length: length,
      controller: controller,
      focusNode: focusNode,
      onCompleted: onCompleted,
      keyboardType: TextInputType.number,
      // iOS surfaces the incoming code as a keyboard suggestion out of the box.
      // For Android auto-fill, pass a `smsRetriever` implementation here.
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
