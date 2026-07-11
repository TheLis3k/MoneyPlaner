import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/planner_repository.dart';
import 'crypto_service.dart';
import 'github_sync_service.dart';

/// Non-secret sync configuration, for display in Settings.
class SyncSettings {
  final String owner;
  final String repo;
  final String path;
  final DateTime? lastSync;

  const SyncSettings({
    required this.owner,
    required this.repo,
    required this.path,
    this.lastSync,
  });

  String get repoLabel => '$owner/$repo';
}

/// Orchestrates encrypted sync: export → encrypt → push, and pull → decrypt →
/// import. Credentials (GitHub token + passphrase) live in secure storage and
/// never touch the database or git history.
class SyncManager {
  static const _kToken = 'gh_token';
  static const _kOwner = 'gh_owner';
  static const _kRepo = 'gh_repo';
  static const _kPath = 'gh_path';
  static const _kPassphrase = 'gh_passphrase';
  static const _kLastSync = 'gh_last_sync';

  final PlannerRepository _repo;
  final CryptoService _crypto;
  final GitHubSyncService _github;
  final FlutterSecureStorage _storage;

  SyncManager({
    PlannerRepository? repository,
    CryptoService? crypto,
    GitHubSyncService? github,
    FlutterSecureStorage? storage,
  }) : _repo = repository ?? PlannerRepository(),
       _crypto = crypto ?? CryptoService(),
       _github = github ?? GitHubSyncService(),
       _storage = storage ?? const FlutterSecureStorage();

  Future<bool> isConfigured() async =>
      (await _storage.read(key: _kToken)) != null;

  Future<void> saveConfig({
    required String token,
    required String owner,
    required String repo,
    required String path,
    required String passphrase,
  }) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kOwner, value: owner);
    await _storage.write(key: _kRepo, value: repo);
    await _storage.write(key: _kPath, value: path.isEmpty ? 'data.enc' : path);
    await _storage.write(key: _kPassphrase, value: passphrase);
  }

  Future<void> disconnect() async {
    for (final key in [
      _kToken,
      _kOwner,
      _kRepo,
      _kPath,
      _kPassphrase,
      _kLastSync,
    ]) {
      await _storage.delete(key: key);
    }
  }

  Future<SyncSettings?> loadSettings() async {
    if (!await isConfigured()) return null;
    final lastSyncRaw = await _storage.read(key: _kLastSync);
    return SyncSettings(
      owner: await _storage.read(key: _kOwner) ?? '',
      repo: await _storage.read(key: _kRepo) ?? '',
      path: await _storage.read(key: _kPath) ?? 'data.enc',
      lastSync: lastSyncRaw == null ? null : DateTime.tryParse(lastSyncRaw),
    );
  }

  Future<({GitHubConfig config, String passphrase})> _load() async {
    return (
      config: GitHubConfig(
        token: (await _storage.read(key: _kToken))!,
        owner: (await _storage.read(key: _kOwner))!,
        repo: (await _storage.read(key: _kRepo))!,
        path: await _storage.read(key: _kPath) ?? 'data.enc',
      ),
      passphrase: (await _storage.read(key: _kPassphrase))!,
    );
  }

  /// Exports the database, encrypts it, and pushes it to GitHub
  /// (last-write-wins: overwrites the remote copy).
  Future<void> push() async {
    final creds = await _load();
    final plaintext = jsonEncode(await _repo.exportData());
    final envelope = _crypto.encryptToEnvelope(plaintext, creds.passphrase);

    final existing = await _github.getFile(creds.config);
    await _github.putFile(creds.config, envelope, sha: existing?.sha);

    await _stampLastSync();
  }

  /// Pulls the remote blob, decrypts it, and replaces local data with it.
  /// Returns false if there's nothing on the remote yet.
  Future<bool> pull() async {
    final creds = await _load();
    final remote = await _github.getFile(creds.config);
    if (remote == null) return false;

    final plaintext = _crypto.decryptFromEnvelope(
      remote.content,
      creds.passphrase,
    );
    final export = jsonDecode(plaintext) as Map<String, Object?>;
    await _repo.importData(export);

    await _stampLastSync();
    return true;
  }

  Future<void> _stampLastSync() =>
      _storage.write(key: _kLastSync, value: DateTime.now().toIso8601String());
}
