import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_idea.dart';

class ActivitiesNotifier
    extends StateNotifier<AsyncValue<List<ActivityIdea>>> {
  ActivitiesNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  void _load() {
    final all = List<ActivityIdea>.from(kAllActivities)..shuffle(Random());
    state = AsyncValue.data(all.take(5).toList());
  }

  /// Pick a fresh random set of activities.
  void shuffle() => _load();
}

final activitiesProvider =
    StateNotifierProvider<ActivitiesNotifier, AsyncValue<List<ActivityIdea>>>(
  (ref) => ActivitiesNotifier(),
);
