import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/complaint.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/complaint_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/ngadu_components.dart';

/// S-05 Aduan Saya & Profil.
class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  late Future<List<Complaint>> _myFuture;
  ComplaintStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _myFuture = _load();
  }

  Future<List<Complaint>> _load() async {
    final user = context.read<AuthController>().user;
    if (user == null) return [];
    if (user.isAdmin) {
      return context.read<ComplaintProvider>().all;
    }
    return context.read<ComplaintProvider>().loadMine(user.id);
  }

  Future<void> _refresh() async {
    final future = _load();
    if (!mounted) return;
    setState(() => _myFuture = future);
    await future;
  }

  void _onCardTap(Complaint c) {
    context.read<ComplaintProvider>().selected = c;
    Navigator.pushNamed(context, '/detail');
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else if (index == 1) {
      Navigator.pushNamed(context, '/form');
    }
  }

  Future<void> _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text('Keluar dari Akun?'),
        content: const Text(
          'Anda perlu masuk kembali untuk mengirim atau memantau aduan fasilitas kampus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 40),
              backgroundColor: AppColors.dangerText,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    try {
      if (SupabaseService.isConfigured) await SupabaseService.signOut();
    } catch (_) {}
    if (!mounted) return;
    context.read<AuthController>().setUnauthenticated();
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatRelativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM', 'id_ID').format(createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final NgaduUser? user = context.watch<AuthController>().user;
    final isAdmin = user?.isAdmin ?? false;
    final authEmail = SupabaseService.isConfigured
        ? (Supabase.instance.client.auth.currentUser?.email ?? '')
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: user == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Sesi tidak ditemukan. Silakan masuk ulang.'),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/auth'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(160, 46),
                        ),
                        child: const Text('Ke Halaman Masuk'),
                      ),
                    ],
                  ),
                ),
              )
            : FutureBuilder<List<Complaint>>(
                future: _myFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SingleChildScrollView(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: LoadingState(),
                    );
                  }
                  if (snapshot.hasError) {
                    return ErrorState(
                      message: 'Gagal memuat riwayat aduan. Periksa koneksi.',
                      onRetry: _refresh,
                    );
                  }

                  final list = snapshot.data ?? [];
                  final total = list.length;
                  final diproses = list
                      .where((c) =>
                          c.status == ComplaintStatus.menunggu ||
                          c.status == ComplaintStatus.diproses)
                      .length;
                  final selesai = list
                      .where((c) => c.status == ComplaintStatus.selesai)
                      .length;

                  final filteredList = _statusFilter == null
                      ? list
                      : list.where((c) => c.status == _statusFilter).toList();

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 36),
                      children: [
                        // Header Profil + Dark Navy Gradient Card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isAdmin
                                        ? 'Profil Petugas'
                                        : 'Aduan Saya & Profil',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _confirmAndLogout,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.input,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.dangerBg,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.input,
                                        ),
                                        border: Border.all(
                                          color: AppColors.dangerBorder,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.logout_rounded,
                                            size: 14,
                                            color: AppColors.dangerText,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            'Keluar',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.dangerText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Kartu Profil Dark Navy Gradient
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF0F172A),
                                      Color(0xFF1E293B),
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.card),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A)
                                          .withValues(alpha: 0.18),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                AppColors.primary,
                                                AppColors.secondary,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.compactCard,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _getInitials(user.name),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              if (authEmail.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  authEmail,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFFCBD5E1),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AppRadius.pill,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isAdmin
                                                          ? Icons
                                                              .manage_accounts_outlined
                                                          : Icons
                                                              .person_outline_rounded,
                                                      size: 12,
                                                      color: const Color(
                                                        0xFFBAE6FD,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      isAdmin
                                                          ? 'Admin (Petugas Kampus)'
                                                          : 'Mahasiswa (Pelapor)',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFFBAE6FD,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.only(top: 14),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.white
                                                .withValues(alpha: 0.12),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _GlassStatBox(
                                              value: '$total',
                                              label: 'Total Aduan',
                                              valueColor: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _GlassStatBox(
                                              value: '$diproses',
                                              label: 'Diproses',
                                              valueColor:
                                                  const Color(0xFF7DD3FC),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _GlassStatBox(
                                              value: '$selesai',
                                              label: 'Selesai',
                                              valueColor:
                                                  const Color(0xFF6EE7B7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Riwayat Aduan Pengguna
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isAdmin
                                        ? 'Daftar Pantauan Kampus'
                                        : 'Riwayat Aduan Saya',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${filteredList.length} item',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Filter Status Khusus Riwayat
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _HistoryFilterPill(
                                      label: 'Semua',
                                      selected: _statusFilter == null,
                                      onTap: () =>
                                          setState(() => _statusFilter = null),
                                    ),
                                    ...ComplaintStatus.values.map(
                                      (s) => _HistoryFilterPill(
                                        label: s.label,
                                        selected: _statusFilter == s,
                                        onTap: () =>
                                            setState(() => _statusFilter = s),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              if (filteredList.isEmpty)
                                EmptyState(
                                  icon: Icons.description_outlined,
                                  title: 'Belum ada aduan',
                                  subtitle:
                                      'Belum ada riwayat aduan pada kategori status ini.',
                                  actionLabel: _statusFilter != null
                                      ? 'Tampilkan Semua'
                                      : 'Buat Aduan Baru',
                                  onAction: _statusFilter != null
                                      ? () =>
                                          setState(() => _statusFilter = null)
                                      : () =>
                                          Navigator.pushNamed(context, '/form'),
                                )
                              else
                                ...filteredList.map((item) {
                                  final loc = item.floorRoom.trim().isNotEmpty
                                      ? '${item.building} • ${item.floorRoom}'
                                      : item.building;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: InkWell(
                                      onTap: () => _onCardTap(item),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.compactCard,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.compactCard,
                                          ),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppRadius.input,
                                              ),
                                              child: Image.network(
                                                item.photoUrl,
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    Container(
                                                  width: 64,
                                                  height: 64,
                                                  color:
                                                      AppColors.surfaceSubtle,
                                                  child: const Icon(
                                                    Icons
                                                        .broken_image_outlined,
                                                    size: 20,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      ComplaintStatusBadge(
                                                        status: item.status,
                                                        compact: true,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _formatRelativeTime(
                                                          item.createdAt,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: AppColors
                                                              .textMuted,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    item.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    loc,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              size: 18,
                                              color: AppColors.borderStrong,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: NgaduBottomNav(
        currentIndex: 2,
        isAdmin: isAdmin,
        onTap: _onNavTap,
      ),
    );
  }
}

class _GlassStatBox extends StatelessWidget {
  const _GlassStatBox({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFilterPill extends StatelessWidget {
  const _HistoryFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}