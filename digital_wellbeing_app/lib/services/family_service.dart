import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'gamification_service.dart';

class FamilyProfile {
  final int? id;
  final String name;
  final String avatarEmoji;
  final bool isActive;
  final bool isChildMode;
  final DateTime createdAt;

  const FamilyProfile({
    this.id,
    required this.name,
    required this.avatarEmoji,
    required this.isActive,
    required this.isChildMode,
    required this.createdAt,
  });

  static FamilyProfile fromMap(Map<String, dynamic> m) => FamilyProfile(
        id: m['id'] as int?,
        name: m['name'] as String,
        avatarEmoji: m['avatar_emoji'] as String,
        isActive: (m['is_active'] as int) == 1,
        isChildMode: (m['is_child_mode'] as int) == 1,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  static const List<String> availableAvatars = [
    '🧑', '👩', '👨', '🧒', '👧', '👦', '🧓', '👴', '👵',
    '🐱', '🐶', '🦊', '🐻', '🐼', '🐨', '🦁', '🐯', '🦄',
  ];
}

class FamilyService {
  final _db = DatabaseService.instance;

  Future<void> ensureDefaultProfile() async {
    final profiles = await _db.getAllFamilyProfiles();
    if (profiles.isEmpty) {
      final id = await _db.insertFamilyProfile({
        'name': 'You',
        'avatar_emoji': '🧑',
        'is_active': 1,
        'is_child_mode': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('active_profile_id', id);
    }
  }

  Future<List<FamilyProfile>> getProfiles() async {
    final rows = await _db.getAllFamilyProfiles();
    return rows.map(FamilyProfile.fromMap).toList();
  }

  Future<FamilyProfile?> getActiveProfile() async {
    final profiles = await getProfiles();
    if (profiles.isEmpty) return null;
    return profiles.firstWhere(
      (p) => p.isActive,
      orElse: () => profiles.first,
    );
  }

  Future<int> createProfile(String name, String emoji) async {
    final id = await _db.insertFamilyProfile({
      'name': name,
      'avatar_emoji': emoji,
      'is_active': 0,
      'is_child_mode': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return id;
  }

  Future<void> setActiveProfile(int id) async {
    final profiles = await getProfiles();
    for (final p in profiles) {
      await _db.updateFamilyProfile(
          p.id!, {'is_active': p.id == id ? 1 : 0});
    }
    await GamificationService.instance.setActiveProfileId(id);
  }

  Future<void> deleteProfile(int id) async {
    final profiles = await getProfiles();
    if (profiles.length <= 1) return; // keep at least one
    await _db.deleteFamilyProfile(id);
    // If deleted was active, switch to first remaining
    final wasActive = profiles.any((p) => p.id == id && p.isActive);
    if (wasActive) {
      final remaining = profiles.where((p) => p.id != id).toList();
      if (remaining.isNotEmpty) await setActiveProfile(remaining.first.id!);
    }
  }

  Future<void> toggleChildMode(int id, bool enabled) async {
    await _db.updateFamilyProfile(id, {'is_child_mode': enabled ? 1 : 0});
  }

  Future<Map<int, int>> getXpPerProfile() async {
    final profiles = await getProfiles();
    final result = <int, int>{};
    for (final p in profiles) {
      result[p.id!] =
          await GamificationService.instance.getTotalXP(profileId: p.id);
    }
    return result;
  }
}
