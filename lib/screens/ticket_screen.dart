import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/demo_data.dart';
import '../models/invite.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/brand_mark.dart';

/// Screen 8 — the shareable gate pass.
///
/// Uses the warmer ticket palette from the design so it reads as a distinct
/// artefact rather than another app screen.
class TicketScreen extends StatefulWidget {
  const TicketScreen({
    super.key,
    required this.invite,
    this.qrCodeUrl,
    this.myQrCode,
  });

  final Invite invite;

  /// QR image url returned by the create-invite API. When present we show this
  /// real image; otherwise we fall back to the locally generated QR.
  final String? qrCodeUrl;

  /// The MyQRCode value from the API, shown below the "OR" divider.
  /// Falls back to the invite's local code if not provided.
  final String? myQrCode;

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  // Wraps the ticket card so we can capture it as an image to share.
  final _shareKey = GlobalKey();
  bool _sharing = false;

  // Name of the person who is inviting -> read from SharedPreferences
  // (saved at login time as 'sUserName'). Falls back to the demo host
  // if, for some reason, nothing was saved yet.
  String _hostName = DemoData.host;

  @override
  void initState() {
    super.initState();
    _loadHostName();
  }

  Future<void> _loadHostName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('sUserName');
    if (!mounted) return;
    if (savedName != null && savedName.trim().isNotEmpty) {
      setState(() => _hostName = savedName.trim());
    }
  }

  bool get _hasQrUrl =>
      widget.qrCodeUrl != null &&
      widget.qrCodeUrl!.isNotEmpty &&
      widget.qrCodeUrl != 'null';

  /// Code shown below the OR divider: MyQRCode from the API when present,
  /// otherwise the invite's local code.
  String get _passCode {
    final v = widget.myQrCode;
    if (v != null && v.isNotEmpty && v != 'null') return v;
    return widget.invite.code;
  }

  /// Payload the guard's scanner reads.
  String get _qrPayload =>
      'gateiq://invite?code=${widget.invite.code}&flat=${Uri.encodeComponent(DemoData.flat)}';

  String get _window {
    final day = DateFormat('d MMMM yyyy').format(widget.invite.startsAt);
    final f = DateFormat('hh:mm a');
    return '$day, ${f.format(widget.invite.startsAt)} - ${f.format(widget.invite.endsAt)}';
  }

  /// Caption that travels with the image, so the pass is still readable even
  /// if the receiving app strips the attachment (or the guest reads it in a
  /// notification preview). All real data — no placeholders.
  String get _shareMessage =>
      '$_hostName has invited you.\n\n'
      'Gate code: $_passCode\n'
      'Valid: $_window\n'
      'Address: ${DemoData.address}\n\n'
      'Show the QR code or this gate code to the guard at the gate.';

  /// Turns the whole ticket card (QR + code + time + address) into a PNG and
  /// opens the **native** share sheet. That sheet is what lists WhatsApp,
  /// Mail, Messages, AirDrop, etc. — the OS only shows the apps that are
  /// actually installed, so if WhatsApp is missing the user still gets Mail
  /// and the rest. We deliberately don't hand-roll our own app picker.
  Future<void> _shareTicket() async {
    if (_sharing) return;
    // Read the anchor rect NOW, before any await — reading `context` after an
    // async gap is unsafe, and iPad needs this rect to place the popover.
    final origin = _shareOrigin();
    setState(() => _sharing = true);
    try {
      // Let the in-flight frame finish painting first. Without this the
      // snapshot can catch the QR's loading spinner instead of the QR.
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _shareKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('The pass is not on screen yet.');
      }

      // pixelRatio: 3 -> a sharp image, not a blurry screenshot.
      final image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        image.dispose(); // free the native buffer even if encoding throws
      }
      if (byteData == null) {
        throw StateError('Could not encode the pass image.');
      }

      final dir = await getTemporaryDirectory();
      final fileName = 'gate-pass-$_passCode.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      // Share the IMAGE ONLY — deliberately no `text`.
      //
      // This is what makes the pass show up as a picture instead of a
      // "download me" attachment. Hand a mail composer both a body and a file
      // and it writes the text into the body and demotes the image to an
      // attachment; give it only an image and Mail/Messages embed the picture
      // inline, while WhatsApp sends it as a photo in the chat.
      //
      // Nothing is lost by dropping the text: the card itself already carries
      // the host, QR, gate code, time window and address.
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png', name: fileName)],
          fileNameOverrides: [fileName],
          subject: '$_hostName has invited you', // email subject line only
          sharePositionOrigin: origin,
        ),
      );
    } catch (e, st) {
      // Full detail in the console; short, actionable line for the user.
      debugPrint('❌ Share failed: $e\n$st');
      if (!mounted) return;
      // Last resort: at least let them send the details as plain text.
      final sentAsText = await _shareTextOnly(origin);
      if (!mounted || sentAsText) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not share the pass: $e')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// The rect the iOS/iPad share sheet is anchored to. On iPad the sheet is a
  /// *popover* and a missing origin makes it throw — the usual cause of a
  /// silent "could not share" on Apple devices. Ignored on Android.
  Rect _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    return (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 1, 1);
  }

  /// Fallback when the image can't be captured or attached: share the pass
  /// details as text. Returns true if the sheet opened.
  Future<bool> _shareTextOnly(Rect origin) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: _shareMessage,
          subject: '$_hostName has invited you',
          sharePositionOrigin: origin,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('❌ Text share also failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gutter = AppSpacing.gutter(context);
    final width = MediaQuery.sizeOf(context).width;
    // QR scales with the device but stays scannable and never overflows.
    final qrSize = (width * 0.46).clamp(150.0, 220.0);

    return Scaffold(
      backgroundColor: AppColors.ticketBg,
      appBar: AppBar(
        backgroundColor: AppColors.ticketBg,
        titleSpacing: gutter,
        leadingWidth: gutter + 32,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Invite Pass',
          style: t.headlineSmall?.copyWith(color: AppColors.ticketInk),
        ),
        actions: [
          // Tap -> capture the ticket as an image and open the native share
          // sheet (WhatsApp, mail, Bluetooth, etc.), same as sharing a photo.
          IconButton(
            tooltip: 'Share',
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.ticketInk,
                    ),
                  )
                : const Icon(
                    Icons.ios_share_rounded,
                    size: 21,
                    color: AppColors.ticketInk,
                  ),
            onPressed: _sharing ? null : _shareTicket,
          ),
          SizedBox(width: gutter - AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CenteredFill(
                // The scroll view is OUTSIDE the boundary on purpose. If the
                // boundary wrapped the scrollable, toImage() would only capture
                // the visible viewport and the shared PNG would be cut off.
                // Wrapping the full-height Column instead means the snapshot
                // always contains the whole pass, however tall it is.
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  // Everything inside this boundary is what gets captured and shared.
                  child: RepaintBoundary(
                    key: _shareKey,
                    child: Container(
                      color: AppColors.ticketBg,
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        AppSpacing.lg,
                        gutter,
                        AppSpacing.xxl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '$_hostName has invited you.',
                            textAlign: TextAlign.center,
                            style: t.headlineSmall?.copyWith(
                              color: AppColors.ticketInk,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Show this QR code or OTP to the guard at gate',
                            textAlign: TextAlign.center,
                            style: t.bodySmall?.copyWith(
                              color: AppColors.ticketMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.xl,
                                ),
                                boxShadow: AppShadows.card,
                              ),
                              // Show the QR image from the API if we have it, otherwise
                              // fall back to the locally generated QR code.
                              child: _hasQrUrl
                                  ? CachedNetworkImage(
                                      imageUrl: widget.qrCodeUrl!,
                                      width: qrSize,
                                      height: qrSize,
                                      fit: BoxFit.contain,
                                      placeholder: (_, __) => SizedBox(
                                        width: qrSize,
                                        height: qrSize,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.ticketInk,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => SizedBox(
                                        width: qrSize,
                                        height: qrSize,
                                        child: const Icon(
                                          Icons.qr_code_2_rounded,
                                          size: 80,
                                          color: AppColors.ticketInk,
                                        ),
                                      ),
                                    )
                                  : QrImageView(
                                      data: _qrPayload,
                                      version: QrVersions.auto,
                                      size: qrSize,
                                      backgroundColor: Colors.white,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: AppColors.ticketInk,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape:
                                            QrDataModuleShape.square,
                                        color: AppColors.ticketInk,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),
                          const _OrDivider(),
                          const SizedBox(height: AppSpacing.xl),

                          Center(child: _CodeChip(code: _passCode)),

                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            _window,
                            textAlign: TextAlign.center,
                            style: t.titleSmall?.copyWith(
                              color: AppColors.ticketInk,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            DemoData.address,
                            textAlign: TextAlign.center,
                            style: t.bodySmall?.copyWith(
                              color: AppColors.ticketMuted,
                              height: 1.5,
                            ),
                          ),

                          // to give a share contenter card
                          const SizedBox(height: AppSpacing.xxl),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const BrandMark(size: 26),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'gateIQ',
                                style: t.titleMedium?.copyWith(
                                  color: AppColors.ticketInk,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ), // Column
                    ), // Container
                  ), // RepaintBoundary
                ), // SingleChildScrollView
              ), // CenteredFill
            ), // Expanded
            // Share button — same look & feel as the "Done" button below.
            // Kept outside the RepaintBoundary so it never appears in the shot.
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, AppSpacing.sm, gutter, 0),
              child: CenteredBar(
                child: PrimaryButton(
                  label: 'Share Invite',
                  loading: _sharing,
                  trailing: Icons.ios_share_rounded,
                  onPressed: _sharing ? null : _shareTicket,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.ticketBg,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.md,
              gutter,
              AppSpacing.md,
            ),
            child: CenteredBar(
              child: PrimaryButton(
                label: 'Done',
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark plate holding the fallback entry code, tappable to copy.
class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Code copied')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1F3A36),
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.card,
        ),
        child: Text(
          code,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            letterSpacing: 6,
            fontSize: 32,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.ticketMuted)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'OR',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.ticketMuted),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.ticketMuted)),
      ],
    );
  }
}
