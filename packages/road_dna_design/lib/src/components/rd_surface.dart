import 'package:flutter/material.dart';

import '../rd_tokens.dart';

enum RdSurfaceTone { standard, subtle, elevated }

class RdSurface extends StatelessWidget {
  const RdSurface({
    required this.child,
    this.padding = const EdgeInsets.all(RdSpacing.x5),
    this.tone = RdSurfaceTone.standard,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final RdSurfaceTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    final color = switch (tone) {
      RdSurfaceTone.standard => colors.surface,
      RdSurfaceTone.subtle => colors.surfaceSubtle,
      RdSurfaceTone.elevated => colors.surfaceElevated,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RdRadius.lg),
        boxShadow: tone == RdSurfaceTone.elevated
            ? const [
                BoxShadow(
                  blurRadius: 24,
                  color: Color(0x142E2A26),
                  offset: Offset(0, 8),
                ),
              ]
            : null,
        color: color,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
