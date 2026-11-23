/// Kategori kerusakan fasilitas yang tersedia pada aplikasi Ngadu.
enum ComplaintCategory {
  listrikAc('Listrik & AC'),
  bangunan('Bangunan & Furnitur'),
  jalanLuar('Jalan & Area Luar'),
  kebersihan('Kebersihan'),
  lainnya('Lainnya');

  const ComplaintCategory(this.label);
  final String label;

  static ComplaintCategory fromLabel(String label) => values.firstWhere(
        (c) => c.label == label,
        orElse: () => ComplaintCategory.lainnya,
      );
}

/// Status penanganan aduan sesuai alur baku PRD.
enum ComplaintStatus {
  menunggu('Menunggu Verifikasi'),
  diproses('Sedang Diproses'),
  selesai('Selesai'),
  ditolak('Ditolak');

  const ComplaintStatus(this.label);
  final String label;

  static ComplaintStatus fromLabel(String label) => values.firstWhere(
        (s) => s.label == label,
        orElse: () => ComplaintStatus.menunggu,
      );
}

/// Satu entri aduan fasilitas kampus.
class Complaint {
  const Complaint({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.title,
    required this.description,
    required this.category,
    required this.building,
    required this.floorRoom,
    required this.latitude,
    required this.longitude,
    required this.photoUrl,
    required this.status,
    this.adminNote,
    this.proofPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String reporterId;
  final String reporterName;
  final String title;
  final String description;
  final ComplaintCategory category;
  final String building;
  final String floorRoom;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final ComplaintStatus status;
  final String? adminNote;
  final String? proofPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Hanya pemilik dengan status masih Menunggu Verifikasi boleh menghapus
  /// aduan (aturan bisnis #2 PRD).
  bool canDelete(String currentUserId) =>
      reporterId == currentUserId && status == ComplaintStatus.menunggu;

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as String,
      reporterId: (json['reporter_id'] ?? '') as String,
      reporterName: (json['reporter_name'] ?? 'Anonim') as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: ComplaintCategory.fromLabel(json['category'] as String? ?? ''),
      building: (json['building'] ?? '') as String,
      floorRoom: (json['floor_room'] ?? '') as String,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      photoUrl: json['photo_url'] as String,
      status: ComplaintStatus.fromLabel(
        json['status'] as String? ?? ComplaintStatus.menunggu.label,
      ),
      adminNote: json['admin_note'] as String?,
      proofPhotoUrl: json['proof_photo_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'title': title,
      'description': description,
      'category': category.label,
      'building': building,
      'floor_room': floorRoom,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'status': status.label,
      'admin_note': adminNote,
      'proof_photo_url': proofPhotoUrl,
    };
  }

  Complaint copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? title,
    String? description,
    ComplaintCategory? category,
    String? building,
    String? floorRoom,
    double? latitude,
    double? longitude,
    String? photoUrl,
    ComplaintStatus? status,
    String? adminNote,
    String? proofPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      building: building ?? this.building,
      floorRoom: floorRoom ?? this.floorRoom,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      proofPhotoUrl: proofPhotoUrl ?? this.proofPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Daftar gedung/zona kampus. Nama gedung bersifat contoh; sesuaikan dengan
/// kampus asal saat deploy.
const kDaftarGedung = <String>[
  'Gedung Teknik',
  'Gedung Fakultas Ekonomi',
  'Gedung Rektorat',
  'Perpustakaan',
  'Area Parkir Utara',
  'Area Parkir Selatan',
  'Masjid Kampus',
  'Kantin',
  'Lapangan',
  'Lainnya',
];
