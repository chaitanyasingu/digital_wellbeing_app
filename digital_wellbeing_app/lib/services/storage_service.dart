import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restriction_rules.dart';

class StorageService {
  static const String _rulesKey = 'restriction_rules';

  Future<void> saveRules(RestrictionRules rules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(rules.toJson());
    await prefs.setString(_rulesKey, jsonString);
  }

  Future<RestrictionRules> loadRules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_rulesKey);
    
    if (jsonString == null) {
      return RestrictionRules.defaultRules();
    }
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return RestrictionRules.fromJson(json);
    } catch (e) {
      return RestrictionRules.defaultRules();
    }
  }

  Future<void> clearRules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rulesKey);
  }
}
