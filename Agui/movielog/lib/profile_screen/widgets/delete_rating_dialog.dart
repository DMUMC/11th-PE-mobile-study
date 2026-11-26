import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/movielog_button.dart';

/// 삭제 요청까지 성공한 경우에만 true를 반환합니다.
class DeleteRatingDialog extends StatefulWidget {
  const DeleteRatingDialog({super.key, required this.onConfirm});
  final Future<void> Function() onConfirm;

  @override
  State<DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<DeleteRatingDialog> {
  bool _isDeleting = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isDeleting,
    child: Dialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 36, 18, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '평점을 삭제할까요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '삭제한 평점은 복구할 수 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.gray,
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.errorBorder,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 52),
              Row(
                children: [
                  Expanded(
                    child: MovieLogButton(
                      label: '취소',
                      backgroundColor: AppColors.primary100,
                      foregroundColor: AppColors.primary600,
                      borderRadius: 8,
                      onPressed: _isDeleting
                          ? null
                          : () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: MovieLogButton(
                      label: '삭제',
                      borderRadius: 8,
                      isLoading: _isDeleting,
                      onPressed: _isDeleting ? null : _delete,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _delete() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(error.toString())));
      setState(() {
        _isDeleting = false;
        _errorText = error.toString();
      });
    }
  }
}
