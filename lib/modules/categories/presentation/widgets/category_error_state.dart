import 'package:flutter/material.dart';

class CategoryErrorState extends StatelessWidget {
  final String? message;
  final Color accentColor;
  final VoidCallback onRetry;

  const CategoryErrorState({
    super.key,
    this.message,
    required this.accentColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 56, color: accentColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Could not load services',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor.withOpacity(0.1),
              foregroundColor: accentColor,
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
