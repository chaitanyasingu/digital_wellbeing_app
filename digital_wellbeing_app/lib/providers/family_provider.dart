import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/family_service.dart';

class FamilyState {
  final List<FamilyProfile> profiles;
  final Map<int, int> xpPerProfile;
  final bool isLoading;

  const FamilyState({
    this.profiles = const [],
    this.xpPerProfile = const {},
    this.isLoading = false,
  });

  FamilyProfile? get activeProfile =>
      profiles.isEmpty ? null : profiles.firstWhere(
        (p) => p.isActive,
        orElse: () => profiles.first,
      );

  List<FamilyProfile> get sortedByXP {
    final sorted = [...profiles];
    sorted.sort((a, b) =>
        (xpPerProfile[b.id] ?? 0).compareTo(xpPerProfile[a.id] ?? 0));
    return sorted;
  }

  FamilyState copyWith({
    List<FamilyProfile>? profiles,
    Map<int, int>? xpPerProfile,
    bool? isLoading,
  }) =>
      FamilyState(
        profiles: profiles ?? this.profiles,
        xpPerProfile: xpPerProfile ?? this.xpPerProfile,
        isLoading: isLoading ?? this.isLoading,
      );
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  FamilyNotifier(this._service) : super(const FamilyState()) {
    _init();
  }

  final FamilyService _service;

  Future<void> _init() async {
    await _service.ensureDefaultProfile();
    await load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final profiles = await _service.getProfiles();
    final xpMap = await _service.getXpPerProfile();
    state = FamilyState(profiles: profiles, xpPerProfile: xpMap, isLoading: false);
  }

  Future<void> addProfile(String name, String emoji) async {
    await _service.createProfile(name, emoji);
    await load();
  }

  Future<void> switchProfile(int id) async {
    await _service.setActiveProfile(id);
    await load();
  }

  Future<void> removeProfile(int id) async {
    await _service.deleteProfile(id);
    await load();
  }

  Future<void> toggleChildMode(int id, bool enabled) async {
    await _service.toggleChildMode(id, enabled);
    await load();
  }
}

final familyServiceProvider = Provider<FamilyService>(
  (_) => FamilyService(),
);

final familyProvider =
    StateNotifierProvider<FamilyNotifier, FamilyState>(
  (ref) => FamilyNotifier(ref.read(familyServiceProvider)),
);
