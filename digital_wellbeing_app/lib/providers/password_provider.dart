import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/password_service.dart';

final passwordServiceProvider = Provider<PasswordService>((ref) {
  return PasswordService();
});
