import 'package:flutter/material.dart';

import '../rd_tokens.dart';

enum RdButtonTone { primary, secondary, danger, ghost }

enum RdButtonSize { small, medium, large }

class RdButton extends StatelessWidget {
  const RdButton({
    required this.label,
    required this.onPressed,
    this.fullWidth = false,
    this.leading,
    this.loading = false,
    this.semanticLabel,
    this.size = RdButtonSize.medium,
    this.tone = RdButtonTone.primary,
    super.key,
  });

  final bool fullWidth;
  final Widget? leading;
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final RdButtonSize size;
  final RdButtonTone tone;

  double get _height => switch (size) {
    RdButtonSize.small => RdSize.buttonSmall,
    RdButtonSize.medium => RdSize.buttonMedium,
    RdButtonSize.large => RdSize.buttonLarge,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    final (background, foreground) = switch (tone) {
      RdButtonTone.primary => (colors.actionPrimary, colors.contentInverse),
      RdButtonTone.secondary => (
        colors.actionSecondary,
        colors.actionSecondaryContent,
      ),
      RdButtonTone.danger => (colors.statusCritical, colors.contentInverse),
      RdButtonTone.ghost => (Colors.transparent, colors.contentSecondary),
    };
    final disabledBackground = tone == RdButtonTone.ghost
        ? Colors.transparent
        : colors.surfaceSubtle;
    final disabledForeground = colors.contentTertiary;
    final radius = size == RdButtonSize.large ? RdRadius.lg : RdRadius.md;

    final button = Semantics(
      button: true,
      enabled: onPressed != null && !loading,
      label: semanticLabel,
      child: SizedBox(
        height: _height,
        width: fullWidth ? double.infinity : null,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            disabledBackgroundColor: disabledBackground,
            disabledForegroundColor: disabledForeground,
            foregroundColor: foreground,
            padding: EdgeInsets.symmetric(
              horizontal: size == RdButtonSize.large
                  ? RdSpacing.x6
                  : RdSpacing.x5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    color: disabledForeground,
                    strokeWidth: 2,
                  ),
                )
              else
                ?leading,
              if (loading || leading != null)
                const SizedBox(width: RdSpacing.x2),
              Flexible(child: Text(label)),
            ],
          ),
        ),
      ),
    );

    return button;
  }
}

class RdIconButton extends StatelessWidget {
  const RdIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.color,
    super.key,
  });

  final Color? color;
  final Widget icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => IconButton(
    color: color ?? context.rdColors.contentSecondary,
    constraints: const BoxConstraints(
      minHeight: RdSize.touchTarget,
      minWidth: RdSize.touchTarget,
    ),
    onPressed: onPressed,
    icon: icon,
    tooltip: semanticLabel,
  );
}
