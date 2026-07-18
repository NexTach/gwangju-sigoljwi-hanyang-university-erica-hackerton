import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'companion_theme.dart';

class CompanionCard extends StatelessWidget {
  const CompanionCard({
    required this.child,
    this.border,
    this.color = CompanionColors.white,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.semanticLabel,
    this.selected,
    super.key,
  });

  final Color? border;
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final String? semanticLabel;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final content = Ink(
      decoration: BoxDecoration(
        border: border == null ? null : Border.all(color: border!, width: 2),
        borderRadius: BorderRadius.circular(radius),
        color: color,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: selected != null,
      label: semanticLabel,
      selected: selected,
      child: Material(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class CompanionPrimaryButton extends StatelessWidget {
  const CompanionPrimaryButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor = CompanionColors.coralAction,
    this.foregroundColor = CompanionColors.white,
    this.icon,
    this.loading = false,
    this.outlined = false,
    super.key,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    width: double.infinity,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: companionButtonStyle(
        FilledButton.styleFrom(
          backgroundColor: outlined ? Colors.transparent : backgroundColor,
          disabledBackgroundColor: CompanionColors.creamLine,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: StadiumBorder(
            side: outlined
                ? const BorderSide(color: CompanionColors.creamLine, width: 1.5)
                : BorderSide.none,
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      child: loading
          ? SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                color: foregroundColor,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    ),
  );
}

class CompanionIconButton extends StatelessWidget {
  const CompanionIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.backgroundColor = CompanionColors.white,
    this.foregroundColor = CompanionColors.ink,
    this.size = 44,
    super.key,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: SizedBox.square(
      dimension: size,
      child: IconButton.filled(
        icon: Icon(icon, size: size * 0.43),
        onPressed: onPressed,
        style: companionButtonStyle(
          IconButton.styleFrom(
            backgroundColor: backgroundColor,
            disabledBackgroundColor: CompanionColors.creamMuted,
            foregroundColor: foregroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(size * 0.33),
            ),
          ),
        ),
        tooltip: semanticLabel,
      ),
    ),
  );
}

class CompanionBackLink extends StatelessWidget {
  const CompanionBackLink({
    required this.onPressed,
    this.label = '돌아가기',
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      icon: const Icon(Icons.chevron_left_rounded, size: 20),
      label: Text(label),
      onPressed: onPressed,
      style: companionButtonStyle(
        TextButton.styleFrom(
          foregroundColor: CompanionColors.coralAction,
          minimumSize: const Size(44, 44),
          padding: EdgeInsets.zero,
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: CompanionColors.coralAction),
        ),
      ),
    ),
  );
}

class CompanionScreenHeader extends StatelessWidget {
  const CompanionScreenHeader({
    required this.title,
    this.eyebrow,
    this.onBack,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String? eyebrow;
  final VoidCallback? onBack;
  final String? subtitle;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (onBack != null) ...[
        CompanionIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: onBack,
          semanticLabel: '뒤로 가기',
        ),
        const SizedBox(width: 14),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow != null) ...[
              Text(
                eyebrow!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: CompanionColors.coralAction,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 7),
            ],
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: CompanionColors.muted),
              ),
            ],
          ],
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 12), trailing!],
    ],
  );
}

enum CompanionTab { nearby, community, home, reports, profile }

const companionTabTransitionDuration = Duration(milliseconds: 260);

class CompanionTabShell extends StatelessWidget {
  const CompanionTabShell({
    required this.branchNavigators,
    required this.navigationShell,
    super.key,
  });

  final List<Widget> branchNavigators;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _AnimatedBranchContainer(
      currentIndex: navigationShell.currentIndex,
      children: branchNavigators,
    ),
    bottomNavigationBar: CompanionBottomNav(
      currentIndex: navigationShell.currentIndex,
      onSelected: (index) {
        if (index == navigationShell.currentIndex) return;
        navigationShell.goBranch(index);
      },
    ),
  );
}

class _AnimatedBranchContainer extends StatefulWidget {
  const _AnimatedBranchContainer({
    required this.children,
    required this.currentIndex,
  });

  final List<Widget> children;
  final int currentIndex;

  @override
  State<_AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<_AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          duration: companionTabTransitionDuration,
          value: 1,
          vsync: this,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && _previousIndex != null) {
            setState(() => _previousIndex = null);
          }
        });
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : companionTabTransitionDuration;
  }

  @override
  void didUpdateWidget(covariant _AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    _previousIndex = oldWidget.currentIndex;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previousIndex = _previousIndex;
    final direction = previousIndex == null
        ? 0.0
        : (widget.currentIndex - previousIndex).sign.toDouble();
    final branchOrder = [
      for (final index in Iterable<int>.generate(widget.children.length))
        if (index != widget.currentIndex) index,
      widget.currentIndex,
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final index in branchOrder)
          KeyedSubtree(
            key: ValueKey('companion-branch-$index'),
            child: Offstage(
              offstage: index != widget.currentIndex && index != previousIndex,
              child: SlideTransition(
                position: index == widget.currentIndex && previousIndex != null
                    ? Tween<Offset>(
                        begin: Offset(direction * 0.045, 0),
                        end: Offset.zero,
                      ).animate(_curved)
                    : index == previousIndex
                    ? Tween<Offset>(
                        begin: Offset.zero,
                        end: Offset(direction * -0.045, 0),
                      ).animate(_curved)
                    : const AlwaysStoppedAnimation(Offset.zero),
                child: FadeTransition(
                  alwaysIncludeSemantics: index == widget.currentIndex,
                  opacity: index == widget.currentIndex
                      ? previousIndex == null
                            ? const AlwaysStoppedAnimation(1)
                            : _curved
                      : index == previousIndex
                      ? ReverseAnimation(_curved)
                      : const AlwaysStoppedAnimation(0),
                  child: ExcludeSemantics(
                    excluding: index != widget.currentIndex,
                    child: IgnorePointer(
                      ignoring: index != widget.currentIndex,
                      child: TickerMode(
                        enabled:
                            index == widget.currentIndex ||
                            index == previousIndex,
                        child: RepaintBoundary(child: widget.children[index]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CompanionBottomNav extends StatelessWidget {
  const CompanionBottomNav({
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(20, 4, 20, 14),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: CompanionColors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / CompanionTab.values.length;
            final reduceMotion =
                MediaQuery.maybeOf(context)?.disableAnimations ?? false;
            return SizedBox(
              height: 64,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    key: const ValueKey('companion-nav-indicator'),
                    curve: Curves.easeOutCubic,
                    duration: reduceMotion
                        ? Duration.zero
                        : companionTabTransitionDuration,
                    height: 40,
                    left: itemWidth * currentIndex + (itemWidth - 46) / 2,
                    top: 1,
                    width: 46,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        color: CompanionColors.coral,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final (index, tab) in CompanionTab.values.indexed)
                        Expanded(
                          child: _CompanionNavItem(
                            active: currentIndex == index,
                            icon: tab.icon,
                            label: tab.label,
                            onTap: () => onSelected(index),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

extension on CompanionTab {
  IconData get icon => switch (this) {
    CompanionTab.nearby => Icons.auto_awesome_rounded,
    CompanionTab.community => Icons.groups_outlined,
    CompanionTab.home => Icons.home_rounded,
    CompanionTab.reports => Icons.show_chart_rounded,
    CompanionTab.profile => Icons.person_outline_rounded,
  };

  String get label => switch (this) {
    CompanionTab.nearby => '주변',
    CompanionTab.community => '커뮤니티',
    CompanionTab.home => '홈',
    CompanionTab.reports => '리포트',
    CompanionTab.profile => '프로필',
  };
}

class _CompanionNavItem extends StatelessWidget {
  const _CompanionNavItem({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final iconDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final labelDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      selected: active,
      label: '$label 탭',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 40,
                  width: 46,
                  child: Center(
                    child: AnimatedScale(
                      curve: Curves.easeOutBack,
                      duration: iconDuration,
                      scale: active ? 1.08 : 1,
                      child: AnimatedRotation(
                        curve: Curves.easeOutCubic,
                        duration: iconDuration,
                        turns: active ? 0 : -0.015,
                        child: Icon(
                          icon,
                          color: active
                              ? CompanionColors.white
                              : CompanionColors.muted,
                          size: active ? 20 : 19,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  curve: Curves.easeOutCubic,
                  duration: labelDuration,
                  style:
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: active
                            ? CompanionColors.ink
                            : CompanionColors.muted,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      ) ??
                      const TextStyle(),
                  child: Text(label, maxLines: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CompanionTag extends StatelessWidget {
  const CompanionTag({
    required this.label,
    this.backgroundColor = CompanionColors.creamMuted,
    this.foregroundColor = CompanionColors.muted,
    this.icon,
    super.key,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: backgroundColor,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: foregroundColor, size: 13),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class CompanionScoreRing extends StatelessWidget {
  const CompanionScoreRing({
    required this.score,
    this.color = CompanionColors.greenBright,
    this.size = 84,
    this.strokeWidth = 8,
    super.key,
  });

  final Color color;
  final int score;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Road DNA 점수 $score점',
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ScoreRingPainter(
          color: color,
          progress: score.clamp(0, 100) / 100,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Text(
            '$score',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: size * 0.27),
          ),
        ),
      ),
    ),
  );
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({
    required this.color,
    required this.progress,
    required this.strokeWidth,
  });

  final Color color;
  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track = Paint()
      ..color = CompanionColors.creamMuted
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final value = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas
      ..drawCircle(center, radius, track)
      ..drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        value,
      );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.progress != progress ||
      oldDelegate.strokeWidth != strokeWidth;
}

void showCompanionMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
