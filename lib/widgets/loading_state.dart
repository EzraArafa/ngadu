import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Skeleton loader beranimasi yang menyerupai proporsi ComplaintCard baru.
class LoadingState extends StatefulWidget {
  const LoadingState({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        return ListView.separated(
          itemCount: widget.itemCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, _) => Opacity(
            opacity: _opacity.value,
            child: const _SkeletonCard(),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder banner 16:9
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(color: AppColors.surfaceSubtle),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    _SkeletonBox(width: 120, height: 24, radius: 8),
                    Spacer(),
                    _SkeletonBox(width: 72, height: 14, radius: 6),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const _SkeletonBox(width: double.infinity, height: 18, radius: 6),
                const SizedBox(height: 6),
                const _SkeletonBox(width: 200, height: 18, radius: 6),
                const SizedBox(height: AppSpacing.md),
                const _SkeletonBox(width: 165, height: 14, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}