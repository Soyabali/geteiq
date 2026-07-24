import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// One promo slide.
class _CarouselSlide {
  const _CarouselSlide({
    required this.number,
    required this.tag,
    required this.title,
    required this.sub,
    required this.accent,
    required this.img,
  });

  final String number;
  final String tag;
  final String title;
  final String sub;
  final Color accent;
  final String img;
}

/// Slide data (ported 1:1 from COMPANY_SLIDES).
const List<_CarouselSlide> _slides = [
  _CarouselSlide(
    number: '01',
    tag: 'Smart Cities',
    title: 'Smart And Safe Cities',
    sub: 'Connected living for modern societies',
    accent: Color(0xFF00B4C8),
    img: 'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=900&q=80',
  ),
  _CarouselSlide(
    number: '02',
    tag: 'AI Security',
    title: 'AI-Powered Surveillance',
    sub: 'Smarter cameras. Faster alerts.',
    accent: Color(0xFFE11D48),
    img: 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=900&q=80',
  ),
  _CarouselSlide(
    number: '03',
    tag: 'Mobility',
    title: 'Intelligent Traffic Enforcement',
    sub: 'Safer roads around your campus',
    accent: Color(0xFF14B8A6),
    img: 'https://images.unsplash.com/photo-1493238792000-8113da705763?w=900&q=80',
  ),
  _CarouselSlide(
    number: '04',
    tag: 'Digital',
    title: 'Software & Transformation',
    sub: 'Apps that power gate-to-cloud ops',
    accent: Color(0xFF8B5CF6),
    img: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=900&q=80',
  ),
  _CarouselSlide(
    number: '05',
    tag: 'Cyber',
    title: 'Data Centres & Cybersecurity',
    sub: 'Secure infrastructure for societies',
    accent: Color(0xFFF97316),
    img: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=900&q=80',
  ),
  _CarouselSlide(
    number: '06',
    tag: 'IoT',
    title: 'Networking & IoT Solutions',
    sub: 'Devices that talk. Gates that listen.',
    accent: Color(0xFFD946EF),
    img: 'https://images.unsplash.com/photo-1544197150-b99a580b7e8f?w=900&q=80',
  ),
  _CarouselSlide(
    number: '07',
    tag: 'GIS',
    title: 'GIS Smart Mapping',
    sub: 'Map every zone of your community',
    accent: Color(0xFFF59E0B),
    img: 'https://images.unsplash.com/photo-1477959858617-67f85b3d74e5?w=900&q=80',
  ),
];

/// Auto-playing company carousel for the top of the dashboard.
///
/// Pure Flutter (PageView + Timer) so it behaves identically on Android & iOS
/// with no external plugin. Loops seamlessly and auto-advances every 4s;
/// the user can also swipe manually.
class CompanyCarousel extends StatefulWidget {
  const CompanyCarousel({super.key, this.height = 190});

  final double height;

  @override
  State<CompanyCarousel> createState() => _CompanyCarouselState();
}

class _CompanyCarouselState extends State<CompanyCarousel> {
  // Start far inside a virtual range (a multiple of the slide count so the
  // first visible page is slide 0) to allow endless looping both ways.
  static final int _initialPage = _slides.length * 1000;

  late final PageController _controller = PageController(
    initialPage: _initialPage,
  );
  int _page = _initialPage;
  Timer? _timer;

  int get _active => _page % _slides.length;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (p) {
              setState(() => _page = p);
              _startAutoPlay(); // reset the timer after any page change / swipe
            },
            itemBuilder: (context, index) {
              return _SlideCard(slide: _slides[index % _slides.length]);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Dots(
          count: _slides.length,
          active: _active,
          accent: _slides[_active].accent,
        ),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});

  final _CarouselSlide slide;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (falls back to the accent colour on error).
          CachedNetworkImage(
            imageUrl: slide.img,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 350),
            placeholder: (_, __) => ColoredBox(color: slide.accent),
            errorWidget: (_, __, ___) => ColoredBox(color: slide.accent),
          ),

          // Dark scrim so the glass card + text stay readable over any photo.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.10),
                  Colors.black.withValues(alpha: 0.70),
                ],
              ),
            ),
          ),

          // Big faint watermark number, top-right.
          Positioned(
            top: 6,
            right: 16,
            child: Text(
              slide.number,
              style: const TextStyle(
                fontSize: 74,
                fontWeight: FontWeight.w800,
                height: 1,
                color: Color(0x24FFFFFF),
              ),
            ),
          ),

          // Frosted "glass" info card near the bottom.
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _GlassCard(slide: slide),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.slide});

  final _CarouselSlide slide;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              // White number chip.
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  slide.number,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Tag + title + subtitle.
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.tag.toUpperCase(),
                      style: TextStyle(
                        color: slide.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      slide.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      slide.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Accent CTA circle.
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: slide.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active, required this.accent});

  final int count;
  final int active;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: on ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: on ? accent : AppColors.border,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        );
      }),
    );
  }
}
