import 'package:flutter/material.dart';

BoxDecoration studyCommunityCardDecoration(
  ThemeData theme, {
  bool highlighted = false,
}) {
  return BoxDecoration(
    color: highlighted
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
        : theme.colorScheme.surfaceContainerLow,
    border: Border.all(
      color: highlighted
          ? theme.colorScheme.primary
          : theme.colorScheme.outlineVariant,
    ),
    borderRadius: BorderRadius.circular(14),
  );
}
