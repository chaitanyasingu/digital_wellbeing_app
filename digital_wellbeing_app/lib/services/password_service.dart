import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordService {
  static const String _passwordHashKey = 'settings_password_hash';
  static const String _passwordSaltKey = 'settings_password_salt';

  /// Returns true if a password has already been set.
  Future<bool> hasPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_passwordHashKey);
  }

  /// Hashes and stores a new password, replacing any existing one.
  Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    await prefs.setString(_passwordSaltKey, salt);
    await prefs.setString(_passwordHashKey, hash);
  }

  /// Returns true if [password] matches the stored hash.
  Future<bool> verifyPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_passwordHashKey);
    final salt = prefs.getString(_passwordSaltKey);
    if (storedHash == null || salt == null) return false;
    return _hashPassword(password, salt) == storedHash;
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }
}
