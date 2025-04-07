import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../models/user.dart';

class AuthService with ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<bool> register(String name, String address, String password) async {
    try {
      final user = User(
        name: name,
        address: address,
        password: password,
      );

      final userId = await DatabaseHelper.instance.createUser(user);

      if (userId > 0) {
        _currentUser = user;
        await _saveUserSession(userId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<bool> login(String name, String password) async {
    try {
      final user =
          await DatabaseHelper.instance.getUserByCredentials(name, password);

      if (user != null) {
        _currentUser = user;
        await _saveUserSession(user.id!);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }

  Future<void> _saveUserSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
  }

  Future<void> checkUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId != null) {
      _currentUser = await DatabaseHelper.instance.getUser(userId);
      notifyListeners();
    }
  }
}
