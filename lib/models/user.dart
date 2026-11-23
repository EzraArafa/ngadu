/// Profil pengguna Ngadu (berdasarkan Supabase Auth + tabel public.profiles).
class NgaduUser {
  const NgaduUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final String role;

  bool get isAdmin => role == 'admin';

  factory NgaduUser.fromJson(Map<String, dynamic> json) {
    return NgaduUser(
      id: (json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      role: (json['role'] ?? 'pelapor') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
      };
}
