import 'package:flutter/foundation.dart';
import '../app/data/services/auth_service.dart';
import '../app/data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService authService;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider({required this.authService});

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await authService.login(email, password);
      _user = result['user'] as UserModel;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    try {
      _user = await authService.getProfile();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

