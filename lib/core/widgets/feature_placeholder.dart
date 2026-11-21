import 'package:flutter/material.dart';

/// Temporary module boundary, replaced by each member's real screens.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    required this.title,
    required this.owner,
    required this.description,
    super.key,
  });

  final String title;
  final String owner;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(owner, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(description, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const Text('Khung dự án · Chức năng chưa triển khai'),
            ],
          ),
        ),
      ),
    );
  }
}
