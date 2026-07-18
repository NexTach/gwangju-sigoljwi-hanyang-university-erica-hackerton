import 'package:flutter/material.dart';

import '../rd_tokens.dart';

class RdTextField extends StatelessWidget {
  const RdTextField({
    required this.label,
    this.controller,
    this.enabled = true,
    this.errorText,
    this.helpText,
    this.keyboardType,
    this.onChanged,
    this.placeholder,
    this.suffix,
    super.key,
  });

  final TextEditingController? controller;
  final bool enabled;
  final String? errorText;
  final String? helpText;
  final TextInputType? keyboardType;
  final String label;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final String? suffix;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: InputDecoration(
      errorText: errorText,
      helperText: helpText,
      hintText: placeholder,
      labelText: label,
      suffixText: suffix,
    ),
    enabled: enabled,
    keyboardType: keyboardType,
    onChanged: onChanged,
  );
}

class RdSwitch extends StatelessWidget {
  const RdSwitch({
    required this.label,
    required this.onChanged,
    required this.value,
    this.description,
    this.enabled = true,
    super.key,
  });

  final String? description;
  final bool enabled;
  final String label;
  final ValueChanged<bool> onChanged;
  final bool value;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: value,
    enabled: enabled,
    label: label,
    toggled: value,
    child: InkWell(
      borderRadius: BorderRadius.circular(RdRadius.md),
      onTap: enabled ? () => onChanged(!value) : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: RdSize.touchTarget),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyLarge),
                  if (description case final description?)
                    Text(
                      description,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.rdColors.contentSecondary,
                      ),
                    ),
                ],
              ),
            ),
            ExcludeSemantics(
              child: Switch(
                onChanged: enabled ? onChanged : null,
                value: value,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

@immutable
class RdTabItem<T> {
  const RdTabItem({required this.label, required this.value, this.badge});

  final String? badge;
  final String label;
  final T value;
}

class RdTabs<T> extends StatelessWidget {
  const RdTabs({
    required this.items,
    required this.onChanged,
    required this.value,
    super.key,
  });

  final List<RdTabItem<T>> items;
  final ValueChanged<T> onChanged;
  final T value;

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    return Semantics(
      container: true,
      label: '탭',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) {
            final selected = item.value == value;
            return Semantics(
              button: true,
              selected: selected,
              child: InkWell(
                onTap: () => onChanged(item.value),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: RdSize.touchTarget,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected
                            ? colors.actionPrimary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: RdSpacing.x3),
                  child: Row(
                    children: [
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: selected
                                  ? colors.contentPrimary
                                  : colors.contentTertiary,
                            ),
                      ),
                      if (item.badge case final badge?) ...[
                        const SizedBox(width: RdSpacing.x1),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(RdRadius.pill),
                            color: colors.surfaceSubtle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text(
                              badge,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

@immutable
class RdFloatingTabItem<T> {
  const RdFloatingTabItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final T value;
}

class RdFloatingTabBar<T> extends StatelessWidget {
  const RdFloatingTabBar({
    required this.items,
    required this.onChanged,
    required this.value,
    super.key,
  }) : assert(items.length >= 2 && items.length <= 5);

  final List<RdFloatingTabItem<T>> items;
  final ValueChanged<T> onChanged;
  final T value;

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    return SafeArea(
      minimum: const EdgeInsets.all(RdSpacing.x3),
      child: Material(
        borderRadius: BorderRadius.circular(RdRadius.xl),
        color: colors.surfaceElevated,
        elevation: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            children: items
                .map(
                  (item) => Expanded(
                    child: Semantics(
                      button: true,
                      label: item.label,
                      selected: item.value == value,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(RdRadius.lg),
                        onTap: () => onChanged(item.value),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              color: item.value == value
                                  ? colors.actionPrimary
                                  : colors.contentTertiary,
                            ),
                            Text(
                              item.label,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: item.value == value
                                        ? colors.actionPrimary
                                        : colors.contentTertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
