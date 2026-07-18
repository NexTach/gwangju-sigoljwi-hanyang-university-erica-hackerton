import 'package:flutter/material.dart';

import '../rd_tokens.dart';

class RdBottomCta extends StatelessWidget {
  const RdBottomCta({
    required this.primary,
    this.description,
    this.secondary,
    super.key,
  });

  final String? description;
  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          RdSpacing.x5,
          RdSpacing.x3,
          RdSpacing.x5,
          RdSpacing.x3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (description != null) ...[
              Text(
                description!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.contentSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: RdSpacing.x2),
            ],
            Row(
              children: [
                if (secondary != null) ...[
                  secondary!,
                  const SizedBox(width: RdSpacing.x2),
                ],
                Expanded(child: primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
