import 'package:flutter/material.dart';

import '../rd_tokens.dart';
import 'rd_button.dart';

class RdNavigation extends StatelessWidget implements PreferredSizeWidget {
  const RdNavigation({
    required this.title,
    this.actions = const [],
    this.onBack,
    this.subtitle,
    super.key,
  });

  final List<Widget> actions;
  final VoidCallback? onBack;
  final String? subtitle;
  final String title;

  @override
  Size get preferredSize => Size.fromHeight(
    subtitle == null ? RdSize.navigation : RdSize.navigation + RdSpacing.x3,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    return Material(
      color: colors.canvas,
      child: SafeArea(
        bottom: false,
        child: Container(
          constraints: BoxConstraints(minHeight: preferredSize.height),
          padding: const EdgeInsets.symmetric(horizontal: RdSpacing.x3),
          child: Row(
            children: [
              if (onBack != null)
                RdIconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBack,
                  semanticLabel: '뒤로 가기',
                ),
              const SizedBox(width: RdSpacing.x1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.contentTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
