import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/sync_manager.dart';
import '../../state/planner_state.dart';
import 'sync_setup_screen.dart';

/// Settings — currently the Security section: PIN lock and biometric unlock.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  final SyncManager _sync = SyncManager();

  bool _loading = true;
  bool _hasPin = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  SyncSettings? _syncSettings;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasPin = await _auth.hasPin();
    final available = await _auth.canUseBiometrics();
    final enabled = await _auth.isBiometricEnabled();
    final syncSettings = await _sync.loadSettings();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _syncSettings = syncSettings;
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

  // ---- cloud sync -----------------------------------------------------------

  Future<void> _setUpSync() async {
    final configured = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SyncSetupScreen(sync: _sync)),
    );
    if (configured == true) await _load();
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _syncing = true);
    try {
      await _sync.push();
      await _load();
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncComplete)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncFailed('$e'))));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final planner = context.read<PlannerState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreWarningTitle),
        content: Text(l10n.restoreWarningBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _syncing = true);
    try {
      final restored = await _sync.pull();
      if (restored) await planner.load();
      await _load();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            restored ? l10n.restoreComplete : l10n.nothingToRestore,
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncFailed('$e'))));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _disconnect() async {
    await _sync.disconnect();
    await _load();
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
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    l10n.cloudSync,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ..._buildSyncSection(l10n),
              ],
            ),
    );
  }

  List<Widget> _buildSyncSection(AppLocalizations l10n) {
    final settings = _syncSettings;
    if (settings == null) {
      return [
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined),
          title: Text(l10n.setUpSync),
          subtitle: Text(l10n.syncSubtitle),
          onTap: _setUpSync,
        ),
      ];
    }

    final lastSync = settings.lastSync == null
        ? l10n.neverSynced
        : l10n.lastSynced(
            DateFormat.yMMMd('pl').add_Hm().format(settings.lastSync!),
          );

    return [
      ListTile(
        leading: const Icon(Icons.cloud_done_outlined),
        title: Text(settings.repoLabel),
        subtitle: Text('${settings.path} · $lastSync'),
      ),
      if (_syncing)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: CircularProgressIndicator()),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _syncNow,
                  icon: const Icon(Icons.sync),
                  label: Text(l10n.syncNow),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _restore,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: Text(l10n.restoreFromCloud),
                ),
              ),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _disconnect,
          icon: const Icon(Icons.link_off),
          label: Text(l10n.disconnect),
        ),
      ),
    ];
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
