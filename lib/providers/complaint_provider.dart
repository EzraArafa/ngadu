import 'package:flutter/foundation.dart';

import '../models/complaint.dart';
import '../services/supabase_service.dart';

/// Stream of complaints + state managed by provider.
class ComplaintProvider extends ChangeNotifier {
  ComplaintProvider() {
    _loadAll();
  }

  List<Complaint> _all = [];
  List<Complaint> get all => _all;
  int get count => _all.length;

  Complaint? _selected;
  Complaint? get selected => _selected;
  set selected(Complaint? c) {
    _selected = c;
    notifyListeners();
  }

  /// Memuat seluruh aduan dari backend.
  Future<void> _loadAll() async {
    try {
      final list = await SupabaseService.fetchAllComplaints();
      _all = list;
    } catch (e) {
      if (kDebugMode) print('Gagal load complaints: $e');
    }
    notifyListeners();
  }

  Future<Complaint> create(Complaint c) async {
    final newC = await SupabaseService.insertComplaint(c);
    _all.insert(0, newC);
    notifyListeners();
    return newC;
  }

  Future<void> updateStatus({
    required String id,
    required ComplaintStatus status,
    String? adminNote,
    String? proofPhotoUrl,
  }) async {
    final updated = await SupabaseService.updateStatus(
      id: id,
      status: status,
      adminNote: adminNote,
      proofPhotoUrl: proofPhotoUrl,
    );
    final idx =
        _all.indexWhere((c) => c.id == id);
    if (idx >= 0) _all[idx] = updated;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await SupabaseService.deleteComplaint(id);
    _all.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void refresh() => _loadAll();

  /// Muat aduan milik satu pelapor (untuk layar Aduan Saya).
  Future<List<Complaint>> loadMine(String userId) async {
    final list = await SupabaseService.fetchMyComplaints(userId);
    return list;
  }

  /// Alias Future<`List<Complaint>`> untuk dipakai di FutureBuilder.
  Future<List<Complaint>> loadMineFuture(String userId) => loadMine(userId);
}