import 'package:flutter/foundation.dart';

import '../models/user.dart';

/// Status sesi autentikasi.
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

/// Snapshot state autentikasi.
class AuthStateData {
  const AuthStateData({
    required this.status,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final NgaduUser? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends ChangeNotifier {
  AuthStateData _state = const AuthStateData(status: AuthStatus.initial);

  AuthStatus get status => _state.status;
  NgaduUser? get user => _state.user;
  String? get errorMessage => _state.errorMessage;
  bool get isAuthenticated => _state.isAuthenticated;

  void setUser(NgaduUser u) {
    _state = AuthStateData(status: AuthStatus.authenticated, user: u);
    notifyListeners();
  }

  void setUnauthenticated() {
    _state = AuthStateData(status: AuthStatus.unauthenticated);
    notifyListeners();
  }

  void setLoading() {
    _state = const AuthStateData(status: AuthStatus.loading);
    notifyListeners();
  }

  void reset() {
    _state = const AuthStateData(status: AuthStatus.initial);
    notifyListeners();
  }
}
