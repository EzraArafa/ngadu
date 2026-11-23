import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/complaint.dart';
import '../models/user.dart';

/// Wrapper seluruh panggilan Supabase (auth, database, storage).
///
/// Konfigurasi URL & anon key dibaca dari `--dart-define`:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseService {
  SupabaseService._();
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static SupabaseClient get client => Supabase.instance.client;

  // ------------------------------------------------------------- Auth ----

  /// Login email + password. Melempar [AuthException] bila gagal.
  static Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  /// Registrasi akun baru; role default "pelapor" diisi lewat trigger DB.
  /// Baris profil dibuat manual di sini sebagai cadangan bila trigger belum
  /// terpasang (upsert aman dijalankan dua kali).
  static Future<void> signUp(String name, String email, String password) async {
    final res = await client.auth.signUp(email: email, password: password);
    final userId = res.user?.id;
    if (userId != null) {
      await client.from('profiles').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'role': 'pelapor',
      });
    }
  }

  static Future<void> signOut() => client.auth.signOut();

  /// Profil user yang sedang login, atau null bila belum login.
  static Future<NgaduUser?> fetchCurrentUser() async {
    final sessionUser = client.auth.currentUser;
    if (sessionUser == null) return null;
    final row = await client
        .from('profiles')
        .select()
        .eq('id', sessionUser.id)
        .maybeSingle();
    if (row == null) return null;
    return NgaduUser.fromJson(row);
  }

  // -------------------------------------------------------- Complaints ----

  /// Seluruh aduan, terbaru lebih dulu.
  static Future<List<Complaint>> fetchAllComplaints() async {
    final rows = await client
        .from('complaints')
        .select()
        .order('created_at', ascending: false);
    return rows.map<Complaint>(Complaint.fromJson).toList();
  }

  /// Aduan milik satu pelapor.
  static Future<List<Complaint>> fetchMyComplaints(String userId) async {
    final rows = await client
        .from('complaints')
        .select()
        .eq('reporter_id', userId)
        .order('created_at', ascending: false);
    return rows.map<Complaint>(Complaint.fromJson).toList();
  }

  /// Buat aduan baru.
  static Future<Complaint> insertComplaint(Complaint c) async {
    final row =
        await client.from('complaints').insert(c.toInsertJson()).select().single();
    return Complaint.fromJson(row);
  }

  /// Update status + catatan + foto bukti (dipakai panel admin).
  static Future<Complaint> updateStatus({
    required String id,
    required ComplaintStatus status,
    String? adminNote,
    String? proofPhotoUrl,
  }) async {
    final patch = <String, dynamic>{
      'status': status.label,
      'admin_note': adminNote,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (proofPhotoUrl != null) patch['proof_photo_url'] = proofPhotoUrl;
    final row =
        await client.from('complaints').update(patch).eq('id', id).select().single();
    return Complaint.fromJson(row);
  }

  /// Hapus aduan (hanya dipanggil untuk milik sendiri, status Menunggu).
  static Future<void> deleteComplaint(String id) async {
    await client.from('complaints').delete().eq('id', id);
  }

  // --------------------------------------------------------- Storage ----

  /// Upload file foto ke bucket `complaint_photos`, kembalikan URL publik.
  static Future<String> uploadPhoto(File file, String userId) async {
    final ext = file.path.split('.').last.toLowerCase();
    final safeExt = (ext.length == 3 || ext.length == 4) ? ext : 'jpg';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    await client.storage.from('complaint_photos').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return client.storage.from('complaint_photos').getPublicUrl(path);
  }
}
