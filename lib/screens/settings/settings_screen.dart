import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';

/// Settings — currently the Security section: PIN lock and biometric unlock.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();

  bool _loading = true;
  bool _hasPin = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasPin = await _auth.hasPin();
    final available = await _auth.canUseBiometrics();
    final enabled = await _auth.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggleLock(bool enable) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (enable) {
      final pin = await _showPinSetup();
      if (pin == null) return;
      await _auth.setPin(pin);
      messenger.showSnackBar(SnackBar(content: Text(l10n.pinSaved)));
    } else {
      await _auth.clearPin();
      messenger.showSnackBar(SnackBar(content: Text(l10n.lockDisabled)));
    }
    await _load();
  }

  Future<void> _changePin() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final pin = await _showPinSetup();
    if (pin == null) return;
    await _auth.setPin(pin);
    messenger.showSnackBar(SnackBar(content: Text(l10n.pinSaved)));
  }

  Future<void> _toggleBiometric(bool enabled) async {
    await _auth.setBiometricEnabled(enabled);
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<String?> _showPinSetup() {
    return showDialog<String>(
      context: context,
      builder: (_) => const _PinSetupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    l10n.security,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: Text(l10n.appLock),
                  subtitle: Text(l10n.appLockSubtitle),
                  value: _hasPin,
                  onChanged: _toggleLock,
                ),
                if (_hasPin)
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: Text(l10n.changePin),
                    onTap: _changePin,
                  ),
                if (_hasPin && _biometricAvailable)
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: Text(l10n.biometricUnlock),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
              ],
            ),
    );
  }
}

class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog();

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final pin = _pinController.text;
    if (pin.length < 6) {
      setState(() => _error = l10n.pinTooShort);
      return;
    }
    if (pin != _confirmController.text) {
      setState(() => _error = l10n.pinsDontMatch);
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.setPin),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.enterPin,
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.confirmPin,
              errorText: _error,
              counterText: '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
