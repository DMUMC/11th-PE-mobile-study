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
        Checkbox(
          value: agreedToTerms,
          onChanged: (value) => onChanged(value ?? false),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: AppSpacing.x1),
        Text(
          '필수 약관에 동의합니다',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
