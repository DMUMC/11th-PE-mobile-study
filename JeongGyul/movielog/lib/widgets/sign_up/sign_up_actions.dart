import 'package:flutter/material.dart';

class SignUpActions extends StatelessWidget {
  const SignUpActions({
    super.key,
    required this.agreedToTerms,
    required this.onAgreementChanged,
    required this.onSubmit,
  });

  final bool agreedToTerms;
  final ValueChanged<bool> onAgreementChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: agreedToTerms,
                  activeColor: colors.primary,
                  side: BorderSide(color: colors.outlineVariant),
                  onChanged: (value) => onAgreementChanged(value ?? false),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onAgreementChanged(!agreedToTerms),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('필수 약관에 동의합니다', style: textTheme.bodyLarge),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 56),
            disabledBackgroundColor: colors.outlineVariant,
            disabledForegroundColor: colors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onSubmit,
          child: const Text('가입하기'),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('이미 계정이 있나요?', style: textTheme.bodyMedium),
            TextButton(
              onPressed: () {},
              child: Text(
                '로그인',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.primary,
                  decorationColor: colors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
