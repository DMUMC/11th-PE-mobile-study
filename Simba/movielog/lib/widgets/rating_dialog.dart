import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

/// 평점 등록·수정 Dialog. 저장 로직은 [onSubmit]으로 받아 Dialog 안에서 실행한다.
/// - onSubmit이 예외 없이 끝나면 true를 반환하며 닫힌다.
/// - 취소하면 onSubmit을 호출하지 않고 false를 반환한다.
/// - 실패하면 닫히지 않고 입력을 유지한 채 오류 문구를 보여준다.
///
/// 저장 중 이탈을 완전히 막으려면 호출하는 쪽에서 `barrierDismissible: false`도 함께 쓴다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.title = '평점을 남겨주세요',
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });

  final String title;
  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  static const _maxCommentLength = 500;

  late int _score = widget.initialScore;
  // build()마다 새로 만들면 setState 때 입력이 초기화되므로 State에서 한 번만 만든다.
  late final _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting, // 저장 중 뒤로가기로 닫히지 않게 한다.
      child: AlertDialog(
        title: Text(widget.title, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MovieRatingInput(
                rating: _score.toDouble(),
                enabled: !_isSubmitting,
                onChanged: (value) =>
                    setState(() => _score = validateServerScore(value)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: _maxCommentLength,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  hintText: '코멘트를 남겨보세요 (선택)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFD32F2F)),
                ),
              ],
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          MovieLogButton(
            label: '취소',
            onPressed: _isSubmitting
                ? null
                : () => Navigator.pop(context, false),
          ),
          MovieLogButton(
            label: '확인',
            isLoading: _isSubmitting,
            // 별점을 고르기 전에는 코멘트만 있어도 누를 수 없다.
            onPressed: _score > 0 && !_isSubmitting ? _onConfirm : null,
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    final trimmed = _commentController.text.trim();
    if (trimmed.length > _maxCommentLength) {
      setState(() => _errorText = '코멘트는 500자 이하로 입력해 주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      // 빈 코멘트는 null로 바꿔 보낸다.
      await widget.onSubmit(_score, trimmed.isEmpty ? null : trimmed);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      // 실패해도 별점·코멘트 입력은 그대로 두고 다시 시도할 수 있게 한다.
      setState(() {
        _isSubmitting = false;
        _errorText = describeSubmitError(error);
      });
    }
  }
}

/// 쓰기 실패를 사용자에게 보여줄 문구로 바꾼다.
/// 서버 오류(400/403/404/409)는 서버 message를 그대로 쓴다.
String describeSubmitError(Object error) {
  if (error is DioException) return writeErrorMessage(error);
  if (error is SubmitFailure) return error.message;
  return '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

/// ViewModel이 실패 이유를 문구로 들고 있을 때 Dialog에 전달하는 예외
class SubmitFailure implements Exception {
  const SubmitFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
