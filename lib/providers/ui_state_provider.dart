import 'package:flutter/foundation.dart';

/// Status UI (loading / error / empty) yang disertakan di setiap layar.
enum UiStateType {
  loading,
  error,
  empty,
}

/// Provider state UI.
class UiStateProvider extends ChangeNotifier {
  UiStateProvider() {
    _state = UiStateType.empty;
  }

  UiStateType get state => _state;
  late UiStateType _state = UiStateType.empty;

  String? get errorMessage => _errorMessage;
  String? _errorMessage;

  void setLoading() {
    _state = UiStateType.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _state = UiStateType.error;
    _errorMessage = message;
    notifyListeners();
  }

  void setEmpty() {
    _state = UiStateType.empty;
    _errorMessage = null;
    notifyListeners();
  }
}