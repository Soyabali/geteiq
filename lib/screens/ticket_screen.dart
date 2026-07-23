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
  const TicketScreen({super.key, required this.invite, this.qrCodeUrl});

  final Invite invite;

  /// QR image url returned by the create-invite API. When present we show this
  /// real image; otherwise we fall back to the locally generated QR.
  final String? qrCodeUrl;

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

  /// Payload the guard's scanner reads.
  String get _qrPayload =>
      'gateiq://invite?code=${widget.invite.code}&flat=${Uri.encodeComponent(DemoData.flat)}';

  String get _window {
    final day = DateFormat('d MMMM yyyy').format(widget.invite.startsAt);
    final f = DateFormat('hh:mm a');
    return '$day, ${f.format(widget.invite.startsAt)} - ${f.format(widget.invite.endsAt)}';
  }

  // Turns the whole ticket card (QR + code + address, everything the guest
  // needs) into a PNG and opens the system share sheet — WhatsApp, mail,
  // Bluetooth, whatever the user picks — same as sharing a screenshot.
  Future<void> _shareTicket() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _shareKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      // pixelRatio: 3 -> a sharp image, not a blurry screenshot.
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/invite_${widget.invite.code}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'You are invited! Gate code: ${widget.invite.code}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not share right now')),
        );
    } finally {
      if (mounted) setState(() => _sharing = false);
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
        child: CenteredFill(
          // Everything inside this boundary is what gets captured and shared.
          child: RepaintBoundary(
            key: _shareKey,
            child: Container(
              color: AppColors.ticketBg,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.lg,
                  gutter,
                  AppSpacing.xxl,
                ),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  Text(
                    '$_hostName has invited you.',
                    textAlign: TextAlign.center,
                    style: t.headlineSmall?.copyWith(
                      color: AppColors.ticketInk,
                      height: 1.3,
                    ),
                  ),
                  if (widget.invite.note.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '"${widget.invite.note}"',
                      textAlign: TextAlign.center,
                      style: t.bodyLarge?.copyWith(
                        color: AppColors.ticketMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Show this QR code or OTP to the guard at gate',
                    textAlign: TextAlign.center,
                    style: t.bodySmall?.copyWith(color: AppColors.ticketMuted),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
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
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.ticketInk,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const _OrDivider(),
                  const SizedBox(height: AppSpacing.xl),

                  Center(child: _CodeChip(code: widget.invite.code)),

                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    _window,
                    textAlign: TextAlign.center,
                    style: t.titleSmall?.copyWith(color: AppColors.ticketInk),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${DemoData.flat}, ${DemoData.society}',
                    textAlign: TextAlign.center,
                    style: t.titleSmall?.copyWith(color: AppColors.ticketInk),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    DemoData.address,
                    textAlign: TextAlign.center,
                    style: t.bodySmall?.copyWith(
                      color: AppColors.ticketMuted,
                      height: 1.5,
                    ),
                  ),

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
              ), // ListView
            ), // Container
          ), // RepaintBoundary
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
