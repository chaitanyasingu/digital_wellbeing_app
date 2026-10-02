import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/device_admin_service.dart';

class DeviceAdminNotifier extends StateNotifier<bool> {
  final DeviceAdminService _svc = DeviceAdminService();

  DeviceAdminNotifier() : super(false) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _svc.isAdminActive();
  }

  /// Opens the system Device Admin activation screen.
  Future<void> activate() async {
    await _svc.activateAdmin();
    await refresh();
  }

  Future<void> deactivate() async {
    await _svc.deactivateAdmin();
    await refresh();
  }
}

final deviceAdminProvider =
    StateNotifierProvider<DeviceAdminNotifier, bool>(
  (_) => DeviceAdminNotifier(),
);
