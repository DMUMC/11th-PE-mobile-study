import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.agreedToTerms,
    required this.onChanged,
  });

  final bool agreedToTerms;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: Transform.scale(
            scale: 26 / 18,
            child: Checkbox(
              value: agreedToTerms,
              onChanged: (value) => onChanged(value ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x1),
        Flexible(
          child: Text(
            '필수 약관에 동의합니다',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
