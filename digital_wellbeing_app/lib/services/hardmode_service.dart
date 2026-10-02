import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class CommitmentContract {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;

  const CommitmentContract({
    this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  bool get isCurrentlyActive =>
      isActive &&
      DateTime.now().isAfter(startTime) &&
      DateTime.now().isBefore(endTime);

  Duration get remaining =>
      endTime.difference(DateTime.now()).isNegative
          ? Duration.zero
          : endTime.difference(DateTime.now());

  static CommitmentContract fromMap(Map<String, dynamic> m) =>
      CommitmentContract(
        id: m['id'] as int?,
        name: m['name'] as String,
        startTime:
            DateTime.fromMillisecondsSinceEpoch(m['start_time'] as int),
        endTime:
            DateTime.fromMillisecondsSinceEpoch(m['end_time'] as int),
        isActive: (m['is_active'] as int) == 1,
      );
}

class HardmodeService {
  final _db = DatabaseService.instance;

  static const _keyEnabled = 'hardmode_enabled';
  static const _keyPinHash = 'hardmode_pin_hash';

  // ── PIN management ─────────────────────────────────────────────────────────

  String _hashPin(String pin) =>
      base64.encode(utf8.encode('dm_hm_v1_$pin'));

  Future<bool> isHardmodeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPinHash) != null;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPinHash, _hashPin(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyPinHash);
    if (stored == null) return true; // no PIN set → allow
    return stored == _hashPin(pin);
  }

  Future<void> enableHardmode(String pin) async {
    await setPin(pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, true);
  }

  Future<void> disableHardmode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, false);
    await prefs.remove(_keyPinHash);
  }

  // ── Commitment contracts ───────────────────────────────────────────────────

  Future<List<CommitmentContract>> getContracts() async {
    final rows = await _db.getCommitmentContracts();
    return rows.map(CommitmentContract.fromMap).toList();
  }

  Future<CommitmentContract?> getActiveContract() async {
    final contracts = await getContracts();
    try {
      return contracts.firstWhere((c) => c.isCurrentlyActive);
    } catch (_) {
      return null;
    }
  }

  Future<int> addContract(String name, DateTime start, DateTime end) async {
    return _db.insertCommitmentContract({
      'name': name,
      'start_time': start.millisecondsSinceEpoch,
      'end_time': end.millisecondsSinceEpoch,
      'is_active': 1,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> cancelContract(int id) async {
    await _db.updateCommitmentContract(id, {'is_active': 0});
  }
}
