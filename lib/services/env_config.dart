import 'dart:io';

/// Membaca konfigurasi dari file `.env` di root proyek,
/// atau dari --dart-define bila .env tidak tersedia.
///
/// Prioritas: --dart-define > .env > default kosong.
class EnvConfig {
  static const _defineUrl = String.fromEnvironment('SUPABASE_URL');
  static const _defineKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String? get supabaseUrl =>
      _defineUrl.isNotEmpty ? _defineUrl : _readEnv('SUPABASE_URL');

  static String? get supabaseAnonKey =>
      _defineKey.isNotEmpty ? _defineKey : _readEnv('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      (supabaseUrl?.isNotEmpty ?? false) &&
      (supabaseAnonKey?.isNotEmpty ?? false);

  /// Cari `.env` dari direktori kerja hingga ke root proyek.
  static Map<String, String>? _envCache;
  static Map<String, String> _readEnvFile() {
    if (_envCache != null) return _envCache!;

    final cwd = Directory.current;
    var dir = cwd;
    File? envFile;
    while (true) {
      final candidate = File('${dir.path}${Platform.pathSeparator}.env');
      if (candidate.existsSync()) {
        envFile = candidate;
        break;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }

    final map = <String, String>{};
    if (envFile != null) {
      for (final line in envFile.readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final idx = trimmed.indexOf('=');
        if (idx <= 0) continue;
        map[trimmed.substring(0, idx).trim()] =
            trimmed.substring(idx + 1).trim();
      }
    }
    _envCache = map;
    return map;
  }

  static String? _readEnv(String key) => _readEnvFile()[key];
}
