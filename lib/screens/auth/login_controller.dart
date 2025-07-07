import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/auth_services.dart';

class LoginController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<bool> login() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final success = await _authService.login(
      usernameController.text,
      passwordController.text,
    );

    isLoading = false;
    if (!success) {
      errorMessage = "Identifiants incorrects. Réessayez.";
    }
    notifyListeners();
    return success;
  }

  void clear() {
    usernameController.clear();
    passwordController.clear();
    errorMessage = null;
    notifyListeners();
  }
}
