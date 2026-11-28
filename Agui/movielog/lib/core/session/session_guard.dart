import 'package:flutter/foundation.dart';

class SessionGuard extends ChangeNotifier {
  int _generation = 0;
  String? _accountId;

  int get generation => _generation;
  String? get accountId => _accountId;

  int startSession(String accountId) {
    _accountId = accountId;
    _generation++;
    notifyListeners();
    return _generation;
  }

  void invalidate() {
    _accountId = null;
    _generation++;
    notifyListeners();
  }

  bool isCurrent(int generation, String accountId) =>
      _generation == generation && _accountId == accountId;
}
