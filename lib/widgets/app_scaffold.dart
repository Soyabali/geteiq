import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Centres content horizontally and caps its width on tablets, while still
/// handing the child a *tight* height.
///
/// A plain `Center` passes loose constraints, which collapses any scroll view
/// or `Expanded` child to zero height. The `minHeight: infinity` is clamped by
/// the incoming constraints, which forces a full-height box instead.
class CenteredFill extends StatelessWidget {
  const CenteredFill({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minHeight: double.infinity,
        ),
        child: child,
      ),
    );
  }
}

/// Centres content horizontally and caps its width, while shrink-wrapping
/// its height.
///
/// Use this inside bottom bars. A plain `Center` expands to fill every pixel
/// of height offered, which makes a bottom bar swallow the whole screen and
/// leaves the body with zero height.
class CenteredBar extends StatelessWidget {
  const CenteredBar({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Shared page shell.
///
/// Handles the three things that otherwise cause layout bugs across devices:
///  * notches / home indicators, via [SafeArea];
///  * short screens, by always making the body scrollable;
///  * tablets, by capping content width and centring it.
///
/// A [bottomBar] is pinned above the safe area and lifts with the keyboard,
/// so the CTA is never hidden behind the home indicator or the IME.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.showBack = true,
    this.bottomBar,
    this.actions,
    this.backgroundColor,
    this.scrollable = true,
    this.padded = true,
  });

  final Widget child;
  final String? title;
  final bool showBack;
  final Widget? bottomBar;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool scrollable;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.gutter(context);

    Widget content = child;
    if (padded) {
      content = Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: content,
      );
    }

    // Keep the phone-shaped layout centred on wide screens.
    content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: content,
      ),
    );

    if (scrollable) {
      // SliverFillRemaining lets the body stretch to fill a tall screen (so
      // Spacer/Expanded behave) while still scrolling once the content — or a
      // large text scale — exceeds the viewport. This is what keeps every
      // screen overflow-free across device sizes.
      content = CustomScrollView(
        // Lets the user dismiss the keyboard by dragging the content.
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [SliverFillRemaining(hasScrollBody: false, child: content)],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.canvas,
      // We manage keyboard insets ourselves on the bottom bar.
      resizeToAvoidBottomInset: true,
      appBar: title == null
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: gutter,
              leading: showBack && Navigator.of(context).canPop()
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                    )
                  : null,
              leadingWidth: showBack ? gutter + 32 : 0,
              title: Text(title!),
              actions: actions,
            ),
      body: SafeArea(
        // The bottom bar owns the bottom inset when present.
        bottom: bottomBar == null,
        child: content,
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : _BottomBar(gutter: gutter, child: bottomBar!),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.gutter, required this.child});

  final double gutter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.md,
            gutter,
            AppSpacing.md,
          ),
          child: CenteredBar(child: child),
        ),
      ),
    );
  }
}
