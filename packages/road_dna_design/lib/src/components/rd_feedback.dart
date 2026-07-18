import 'package:flutter/material.dart';

import '../rd_tokens.dart';

enum RdFeedbackTone { info, success, warning, critical }

class RdAlert extends StatelessWidget {
  const RdAlert({
    required this.message,
    required this.title,
    this.action,
    this.tone = RdFeedbackTone.info,
    super.key,
  });

  final Widget? action;
  final String message;
  final String title;
  final RdFeedbackTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    final (background, foreground, icon) = switch (tone) {
      RdFeedbackTone.info => (
        colors.statusInfoSubtle,
        colors.statusInfo,
        Icons.info_outline_rounded,
      ),
      RdFeedbackTone.success => (
        colors.statusSuccessSubtle,
        colors.statusSuccess,
        Icons.check_circle_outline_rounded,
      ),
      RdFeedbackTone.warning => (
        colors.statusWarningSubtle,
        colors.statusWarning,
        Icons.warning_amber_rounded,
      ),
      RdFeedbackTone.critical => (
        colors.statusCriticalSubtle,
        colors.statusCritical,
        Icons.error_outline_rounded,
      ),
    };

    return Semantics(
      liveRegion: tone == RdFeedbackTone.critical,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RdRadius.md),
          color: background,
        ),
        child: Padding(
          padding: const EdgeInsets.all(RdSpacing.x4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: RdSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: foreground),
                    ),
                    const SizedBox(height: RdSpacing.x1),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.contentSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}

void showRdToast(
  BuildContext context, {
  required String message,
  RdFeedbackTone tone = RdFeedbackTone.info,
}) {
  final colors = context.rdColors;
  final color = switch (tone) {
    RdFeedbackTone.info => colors.contentPrimary,
    RdFeedbackTone.success => colors.statusSuccess,
    RdFeedbackTone.warning => colors.statusWarning,
    RdFeedbackTone.critical => colors.statusCritical,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Row(
          children: [
            Icon(
              tone == RdFeedbackTone.warning
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline_rounded,
              color: colors.contentInverse,
              size: 20,
            ),
            const SizedBox(width: RdSpacing.x2),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

Future<T?> showRdBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required String semanticLabel,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: semanticLabel,
    namesRoute: true,
    child: SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: builder(context),
        ),
      ),
    ),
  ),
);
