import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/password_provider.dart';
import '../widgets/password_dialog.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _name = '';
  String _email = '';

  static const _nameKey = 'profile_name';
  static const _emailKey = 'profile_email';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString(_nameKey) ?? '';
      _email = prefs.getString(_emailKey) ?? '';
    });
  }

  // -------------------------------------------------------------------------
  // Edit a single profile field via dialog
  // -------------------------------------------------------------------------

  Future<void> _editField({
    required String label,
    required String currentValue,
    required TextInputType keyboardType,
    required Future<void> Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: currentValue);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.of(context).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4FA0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final value = controller.text.trim();
    controller.dispose();
    if (saved != true || !mounted) return;
    await onSave(value);
  }

  Future<void> _editName() async {
    await _editField(
      label: 'Name',
      currentValue: _name,
      keyboardType: TextInputType.name,
      onSave: (value) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_nameKey, value);
        setState(() => _name = value);
      },
    );
  }

  Future<void> _editEmail() async {
    await _editField(
      label: 'Email address',
      currentValue: _email,
      keyboardType: TextInputType.emailAddress,
      onSave: (value) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_emailKey, value);
        setState(() => _email = value);
      },
    );
  }

  // -------------------------------------------------------------------------
  // Reset password
  // -------------------------------------------------------------------------

  Future<void> _resetPassword() async {
    final passwordService = ref.read(passwordServiceProvider);

    // If a password already exists, verify it before allowing a change
    final hasPassword = await passwordService.hasPassword();
    if (!mounted) return;

    if (hasPassword) {
      final verified = await PasswordDialog.showVerify(context, passwordService);
      if (!verified || !mounted) return;
    }

    // Set new password
    await PasswordDialog.showSetup(context, passwordService);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Reset app
  // -------------------------------------------------------------------------

  Future<void> _resetApp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset App'),
        content: const Text(
          'This will clear all your settings, profile data, and password. '
          'The app will return to the first-run state.\n\n'
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Verify password before wiping
    final passwordService = ref.read(passwordServiceProvider);
    final verified = await PasswordDialog.showVerify(context, passwordService);
    if (!verified || !mounted) return;

    // Wipe all SharedPreferences data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    // Navigate back to onboarding
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -- Profile section -------------------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your personal details (stored only on this device).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Name'),
                      subtitle: Text(
                        _name.isEmpty ? 'Not set' : _name,
                        style: TextStyle(
                          color: _name.isEmpty
                              ? Colors.grey.shade400
                              : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit name',
                        onPressed: _editName,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email address'),
                      subtitle: Text(
                        _email.isEmpty ? 'Not set' : _email,
                        style: TextStyle(
                          color: _email.isEmpty
                              ? Colors.grey.shade400
                              : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit email',
                        onPressed: _editEmail,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // -- Security section ------------------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: const Text('Reset Password'),
                      subtitle: const Text(
                        'Change the password used to protect settings',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _resetPassword,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // -- Danger zone -----------------------------------------------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Danger Zone',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.refresh,
                            color: Colors.red.shade700),
                      ),
                      title: const Text('Reset App'),
                      subtitle: const Text(
                        'Clear all data and return to first-run setup',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _resetApp,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // -- Ads placeholder ------------------------------------------
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              alignment: Alignment.center,
              child: Text(
                'Advertisement',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
