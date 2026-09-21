import 'package:flutter/material.dart';

class StatItem extends StatelessWidget {
  const StatItem({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Color(0xFFF5F3F0),
        border: Border.all(color: Color(0xFFE9DDFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.bodyMedium
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: textTheme.titleLarge?.copyWith(
              color: Color(0xFF4F378A)
            )
          ),    
        ],
      ),
    );
  }
}