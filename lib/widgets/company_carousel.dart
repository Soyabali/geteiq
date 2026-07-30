import 'dart:async';

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
    img: 'https://upegov.in/VistorManagementSystemApis/BannerImages/Image-1.jpeg',
  ),
  _CarouselSlide(
    number: '02',
    tag: 'AI Security',
    title: 'AI-Powered Surveillance',
    sub: 'Smarter cameras. Faster alerts.',
    accent: Color(0xFFE11D48),
    img: 'https://upegov.in/VistorManagementSystemApis/BannerImages/Image-2.jpeg',
  ),
  _CarouselSlide(
    number: '03',
    tag: 'Mobility',
    title: 'Intelligent Traffic Enforcement',
    sub: 'Safer roads around your campus',
    accent: Color(0xFF14B8A6),
    img: 'https://upegov.in/VistorManagementSystemApis/BannerImages/Image-3.jpeg',
  ),
  _CarouselSlide(
    number: '04',
    tag: 'Digital',
    title: 'Software & Transformation',
    sub: 'Apps that power gate-to-cloud ops',
    accent: Color(0xFF8B5CF6),
    img: 'https://upegov.in/VistorManagementSystemApis/BannerImages/Image-4.jpeg',
  ),
  _CarouselSlide(
    number: '05',
    tag: 'Cyber',
    title: 'Data Centres & Cybersecurity',
    sub: 'Secure infrastructure for societies',
    accent: Color(0xFFF97316),
    img: 'https://upegov.in/VistorManagementSystemApis/BannerImages/Image-5.jpeg',
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
      // Just the rotating background photo — no info card on top of it.
      child: CachedNetworkImage(
        imageUrl: slide.img,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 350),
        placeholder: (_, __) => ColoredBox(color: slide.accent),
        errorWidget: (_, __, ___) => ColoredBox(color: slide.accent),
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
