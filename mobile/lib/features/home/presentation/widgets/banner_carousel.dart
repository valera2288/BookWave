import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/banner.dart';

/// Карусель баннеров: автопрокрутка каждые 5 секунд + ручное пролистывание
/// свайпом (ТЗ).
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({required this.banners, required this.onTap, super.key});

  final List<HomeBanner> banners;
  final ValueChanged<HomeBanner> onTap;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_controller.hasClients) return;
        _page = (_page + 1) % widget.banners.length;
        _controller.animateToPage(
          _page,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => _page = index,
        itemCount: widget.banners.length,
        itemBuilder: (context, index) {
          final banner = widget.banners[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTap: () => widget.onTap(banner),
                child: Image.network(
                  banner.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
