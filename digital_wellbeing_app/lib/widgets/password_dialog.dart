import 'package:flutter/material.dart';
import '../services/password_service.dart';

class PasswordDialog {
  /// Shows a dialog to create a new password.
  /// [barrierDismissible] is false so the user must complete it.
  /// Returns `true` when the password has been successfully saved.
  static Future<bool> showSetup(
    BuildContext context,
    PasswordService passwordService,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SetPasswordDialog(passwordService: passwordService),
        ) ??
        false;
  }

  /// Shows a dialog to verify the existing password before a protected action.
  /// Returns `true` if the entered password is correct.
  static Future<bool> showVerify(
    BuildContext context,
    PasswordService passwordService,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => _VerifyPasswordDialog(passwordService: passwordService),
        ) ??
        false;
  }
}

// ---------------------------------------------------------------------------
// Set-password dialog
// ---------------------------------------------------------------------------

class _SetPasswordDialog extends StatefulWidget {
  final PasswordService passwordService;
  const _SetPasswordDialog({required this.passwordService});

  @override
  State<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<_SetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await widget.passwordService.setPassword(_passwordController.text.trim());
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Your Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4FA0).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6B4FA0).withAlpha(60),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: Color(0xFF6B4FA0), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ask someone you trust to set this password for you. '
                      'A guided restriction is always more effective than an '
                      'unguided, unmonitored journey to digital mindfulness.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A3570),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This password will be required whenever you save settings changes.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a password';
                }
                if (value.trim().length < 4) {
                  return 'Must be at least 4 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please confirm your password';
                }
                if (value.trim() != _passwordController.text.trim()) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B4FA0),
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Set Password'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Verify-password dialog
// ---------------------------------------------------------------------------

class _VerifyPasswordDialog extends StatefulWidget {
  final PasswordService passwordService;
  const _VerifyPasswordDialog({required this.passwordService});

  @override
  State<_VerifyPasswordDialog> createState() => _VerifyPasswordDialogState();
}

class _VerifyPasswordDialogState extends State<_VerifyPasswordDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _isWrong = false;
  bool _isVerifying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _isVerifying = true;
      _isWrong = false;
    });
    final isCorrect =
        await widget.passwordService.verifyPassword(_controller.text);
    if (!mounted) return;
    if (isCorrect) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isWrong = true;
        _isVerifying = false;
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your password to save changes.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verify(),
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              errorText: _isWrong ? 'Incorrect password' : null,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B4FA0),
            foregroundColor: Colors.white,
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }
}
