import 'package:flutter/foundation.dart';

/// 요청 헤더/응답 본문/원본 예외는 기록하지 않습니다.
/// 알려진 비밀값과 민감한 쿼리는 추가로 제거합니다.
class NetworkLogger {
  const NetworkLogger({
    this.enabled = true,
    this.sink,
    this.secrets = const [],
  });
  final bool enabled;
  final ValueChanged<String>? sink;
  final List<String> secrets;

  void failure(Uri uri, String safeMessage) {
    if (!kDebugMode || !enabled) return;
    final query = <String, String>{
      for (final entry in uri.queryParameters.entries)
        entry.key:
            RegExp(
              'token|key|authorization|secret',
              caseSensitive: false,
            ).hasMatch(entry.key)
            ? '[REDACTED]'
            : entry.value,
    };
    var line =
        '[network] GET ${uri.replace(userInfo: '', queryParameters: query)} ERROR $safeMessage';
    for (final secret in secrets.where((s) => s.isNotEmpty)) {
      line = line
          .replaceAll(secret, '[REDACTED]')
          .replaceAll(Uri.encodeComponent(secret), '[REDACTED]');
    }
    (sink ?? debugPrint)(line);
  }
}
