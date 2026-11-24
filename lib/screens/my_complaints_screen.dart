import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

/// S-05 Aduan Saya & Profil: riwayat aduan + profil + logout.
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

  Future<void> _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
              minimumSize: const Size(96, 42),
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

  @override
  Widget build(BuildContext context) {
    final NgaduUser? user = context.watch<AuthController>().user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aduan Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.dangerText),
            tooltip: 'Keluar',
            onPressed: _confirmAndLogout,
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sesi tidak ditemukan. Silakan masuk ulang.',
                      style: textTheme.bodyMedium,
                    ),
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
                final berjalan = list
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
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      // Kartu Profil & Ringkasan Statistik
                      _ProfileSummaryCard(
                        initials: _getInitials(user.name),
                        name: user.name,
                        role: user.role,
                        total: total,
                        inProgress: berjalan,
                        completed: selesai,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      if (list.isEmpty)
                        EmptyState(
                          title: 'Belum ada aduan yang dikirim',
                          subtitle:
                              'Laporan kerusakan fasilitas kampus yang Anda buat akan muncul dan dapat dipantau di sini.',
                          onAction: () => Navigator.pushNamed(context, '/form'),
                        )
                      else ...[
                        // Header Riwayat + Filter Status
                        Text(
                          'Riwayat Laporan',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _MyFilterChip(
                                label: 'Semua (${list.length})',
                                selected: _statusFilter == null,
                                onTap: () =>
                                    setState(() => _statusFilter = null),
                              ),
                              ...ComplaintStatus.values.map((s) {
                                final count =
                                    list.where((c) => c.status == s).length;
                                return _MyFilterChip(
                                  label: '${s.label} ($count)',
                                  selected: _statusFilter == s,
                                  onTap: () =>
                                      setState(() => _statusFilter = s),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        if (filteredList.isEmpty)
                          EmptyState(
                            icon: Icons.filter_list_off_rounded,
                            title: 'Tidak ada laporan di status ini',
                            subtitle:
                                'Belum ada laporan Anda dengan status ${_statusFilter?.label ?? ''}.',
                            actionLabel: 'Tampilkan Semua',
                            onAction: () =>
                                setState(() => _statusFilter = null),
                          )
                        else
                          ...filteredList.map(
                            (c) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: ComplaintCard(
                                complaint: c,
                                onTap: () => _onCardTap(c),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.initials,
    required this.name,
    required this.role,
    required this.total,
    required this.inProgress,
    required this.completed,
  });

  final String initials;
  final String name;
  final String role;
  final int total;
  final int inProgress;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryBorder, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total Aduan',
                  value: '$total',
                  valueColor: AppColors.textPrimary,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              Expanded(
                child: _StatItem(
                  label: 'Diproses',
                  value: '$inProgress',
                  valueColor: AppColors.infoText,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              Expanded(
                child: _StatItem(
                  label: 'Selesai',
                  value: '$completed',
                  valueColor: AppColors.successText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MyFilterChip extends StatelessWidget {
  const _MyFilterChip({
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
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
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
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}