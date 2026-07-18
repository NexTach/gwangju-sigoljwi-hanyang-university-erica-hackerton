import 'package:flutter/material.dart';

import '../rd_tokens.dart';

class RdListHeader extends StatelessWidget {
  const RdListHeader({
    required this.title,
    this.action,
    this.description,
    super.key,
  });

  final Widget? action;
  final String? description;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      RdSpacing.x5,
      RdSpacing.x6,
      RdSpacing.x5,
      RdSpacing.x2,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (description != null)
                Text(
                  description!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.rdColors.contentTertiary,
                  ),
                ),
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class RdListRow extends StatelessWidget {
  const RdListRow({
    required this.title,
    this.description,
    this.leading,
    this.onTap,
    this.trailing,
    super.key,
  });

  final String? description;
  final Widget? leading;
  final VoidCallback? onTap;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    return Semantics(
      button: onTap != null,
      child: InkWell(
        borderRadius: BorderRadius.circular(RdRadius.md),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RdSpacing.x5,
              vertical: RdSpacing.x3,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(color: colors.actionPrimary, size: 24),
                    child: leading!,
                  ),
                  const SizedBox(width: RdSpacing.x3),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null)
                        Text(
                          description!,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.contentSecondary),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.contentTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
