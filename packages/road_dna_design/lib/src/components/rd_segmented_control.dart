import 'package:flutter/material.dart';

import '../rd_tokens.dart';

@immutable
class RdSegment<T> {
  const RdSegment({
    required this.label,
    required this.value,
    this.description,
    this.icon,
  });

  final String? description;
  final IconData? icon;
  final String label;
  final T value;
}

class RdSegmentedControl<T> extends StatelessWidget {
  const RdSegmentedControl({
    required this.onChanged,
    required this.segments,
    required this.value,
    super.key,
  });

  final ValueChanged<T> onChanged;
  final List<RdSegment<T>> segments;
  final T value;

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RdRadius.lg),
        color: colors.surfaceSubtle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(RdSpacing.x1),
        child: Row(
          children: segments
              .map(
                (segment) => Expanded(
                  child: Semantics(
                    checked: segment.value == value,
                    inMutuallyExclusiveGroup: true,
                    label: segment.label,
                    selected: segment.value == value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RdSpacing.x1 / 2,
                      ),
                      child: Material(
                        borderRadius: BorderRadius.circular(RdRadius.md),
                        color: segment.value == value
                            ? colors.surface
                            : Colors.transparent,
                        elevation: segment.value == value ? 1 : 0,
                        shadowColor: const Color(0x142E2A26),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(RdRadius.md),
                          onTap: () => onChanged(segment.value),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: RdSize.buttonLarge,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(RdSpacing.x2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (segment.icon != null)
                                    Icon(
                                      segment.icon,
                                      color: segment.value == value
                                          ? colors.actionPrimary
                                          : colors.contentSecondary,
                                      size: 20,
                                    ),
                                  Text(
                                    segment.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: segment.value == value
                                              ? colors.actionPrimary
                                              : colors.contentSecondary,
                                        ),
                                  ),
                                  if (segment.description != null)
                                    Text(
                                      segment.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colors.contentTertiary,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
