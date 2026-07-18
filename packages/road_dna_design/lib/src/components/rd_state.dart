import 'package:flutter/material.dart';

import '../rd_tokens.dart';

class RdEmptyState extends StatelessWidget {
  const RdEmptyState({
    required this.description,
    required this.title,
    this.action,
    this.icon,
    super.key,
  });

  final Widget? action;
  final String description;
  final IconData? icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RdSpacing.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 64,
                  child: Icon(icon, color: colors.contentTertiary),
                ),
              ),
            const SizedBox(height: RdSpacing.x4),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RdSpacing.x2),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.contentSecondary),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: RdSpacing.x5),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class RdSkeleton extends StatefulWidget {
  const RdSkeleton({
    required this.height,
    this.borderRadius = RdRadius.sm,
    this.width = double.infinity,
    super.key,
  });

  final double borderRadius;
  final double height;
  final double width;

  @override
  State<RdSkeleton> createState() => _RdSkeletonState();
}

class _RdSkeletonState extends State<RdSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.45,
      upperBound: 1,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FadeTransition(
      opacity: _controller,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: context.rdColors.border,
        ),
        child: SizedBox(height: widget.height, width: widget.width),
      ),
    ),
  );
}
