import 'package:flutter/material.dart';

import '../rd_tokens.dart';

enum RdBadgeTone { neutral, info, success, warning, critical }

class RdBadge extends StatelessWidget {
  const RdBadge({
    required this.label,
    this.dot = false,
    this.tone = RdBadgeTone.neutral,
    super.key,
  });

  final bool dot;
  final String label;
  final RdBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    final (background, foreground) = switch (tone) {
      RdBadgeTone.neutral => (colors.surfaceSubtle, colors.contentSecondary),
      RdBadgeTone.info => (colors.statusInfoSubtle, colors.statusInfo),
      RdBadgeTone.success => (colors.statusSuccessSubtle, colors.statusSuccess),
      RdBadgeTone.warning => (colors.statusWarningSubtle, colors.statusWarning),
      RdBadgeTone.critical => (
        colors.statusCriticalSubtle,
        colors.statusCritical,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RdRadius.pill),
        color: background,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RdSpacing.x2,
          vertical: RdSpacing.x1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: foreground,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 6),
              ),
              const SizedBox(width: RdSpacing.x1),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
