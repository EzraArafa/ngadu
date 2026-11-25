import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/complaint_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/ngadu_components.dart';

/// S-03 Beranda / Feed Aduan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ComplaintStatus? _statusFilter;
  ComplaintCategory? _categoryFilter;
  bool _showCategoryDrawer = false;
  final _searchController = TextEditingController();
  bool _initialLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _initialLoading = true;
      _errorMsg = null;
    });
    try {
      context.read<ComplaintProvider>().refresh();
      await Future.delayed(const Duration(milliseconds: 350));
    } catch (_) {
      _errorMsg = 'Gagal memuat data. Periksa koneksi jaringan.';
    }
    if (mounted) setState(() => _initialLoading = false);
  }

  List<Complaint> _applyFilters(List<Complaint> all) {
    var list = all;
    if (_statusFilter != null) {
      list = list.where((c) => c.status == _statusFilter).toList();
    }
    if (_categoryFilter != null) {
      list = list.where((c) => c.category == _categoryFilter).toList();
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where((c) =>
              c.title.toLowerCase().contains(query) ||
              c.building.toLowerCase().contains(query) ||
              c.floorRoom.toLowerCase().contains(query) ||
              c.description.toLowerCase().contains(query))
          .toList();
    }
    return list;
  }

  bool get _hasActiveFilters =>
      _statusFilter != null ||
      _categoryFilter != null ||
      _searchController.text.trim().isNotEmpty;

  void _resetFilters() {
    setState(() {
      _statusFilter = null;
      _categoryFilter = null;
      _searchController.clear();
    });
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, '/form');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/my');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final allComplaints = context.watch<ComplaintProvider>().all;

    final firstName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim().split(' ').first
        : 'Warga Kampus';
    final isAdmin = user?.isAdmin ?? false;

    final activeCount = allComplaints
        .where((c) =>
            c.status == ComplaintStatus.menunggu ||
            c.status == ComplaintStatus.diproses)
        .length;
    final doneCount = allComplaints
        .where((c) => c.status == ComplaintStatus.selesai)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Sticky Header Ringkas
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                14,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const NgaduLogo(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: 'Halo, ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$firstName 👋',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAdmin ? 'MODE ADMIN SARPRAS' : 'MAHASISWA',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Aduan Aktif',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                text: '$activeCount ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.1,
                                ),
                                children: [
                                  TextSpan(
                                    text: '($doneCount selesai)',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.successText,
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
                  const SizedBox(height: AppSpacing.md),

                  // Kolom Pencarian + Tombol Filter Kategori
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.background,
                            hintText: 'Cari judul atau nama gedung...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 15,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _CategoryToggleButton(
                        isActive:
                            _categoryFilter != null || _showCategoryDrawer,
                        hasSelection: _categoryFilter != null,
                        onTap: () => setState(
                          () => _showCategoryDrawer = !_showCategoryDrawer,
                        ),
                      ),
                    ],
                  ),

                  // Panel Filter Kategori (Collapsible)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _showCategoryDrawer
                        ? Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.only(top: 10),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.surfaceSubtle,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Filter Kategori',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (_categoryFilter != null)
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _categoryFilter = null,
                                        ),
                                        child: const Text(
                                          'Reset',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _CategoryChip(
                                      label: 'Semua',
                                      selected: _categoryFilter == null,
                                      onTap: () => setState(
                                        () => _categoryFilter = null,
                                      ),
                                    ),
                                    ...ComplaintCategory.values.map(
                                      (cat) => _CategoryChip(
                                        label: cat.label,
                                        selected: _categoryFilter == cat,
                                        onTap: () => setState(
                                          () => _categoryFilter = cat,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Filter Horizontal Pill Status
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StatusPill(
                          label: 'Semua',
                          selected: _statusFilter == null,
                          onTap: () => setState(() => _statusFilter = null),
                        ),
                        ...ComplaintStatus.values.map(
                          (s) => _StatusPill(
                            label: s.label,
                            selected: _statusFilter == s,
                            onTap: () => setState(() => _statusFilter = s),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Daftar Kartu Aduan Visual-First
            Expanded(
              child: _buildList(allComplaints),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NgaduBottomNav(
        currentIndex: 0,
        isAdmin: isAdmin,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildList(List<Complaint> complaints) {
    if (_initialLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingState(),
      );
    }
    if (_errorMsg != null) {
      return ErrorState(message: _errorMsg!, onRetry: _loadComplaints);
    }

    final filtered = _applyFilters(complaints);

    if (filtered.isEmpty) {
      if (_hasActiveFilters && complaints.isNotEmpty) {
        return EmptyState(
          icon: Icons.filter_alt_off_rounded,
          title: 'Tidak Ada Aduan Ditemukan',
          subtitle:
              'Coba ubah kata kunci pencarian atau filter status/kategori.',
          actionLabel: 'Reset Filter',
          onAction: _resetFilters,
        );
      }
      return EmptyState(
        onAction: () => Navigator.pushNamed(context, '/form'),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadComplaints,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.cardGap,
          AppSpacing.lg,
          36,
        ),
        itemCount: filtered.length + (_hasActiveFilters ? 1 : 0),
        itemBuilder: (_, index) {
          if (_hasActiveFilters && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Menampilkan ',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: '${filtered.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: _categoryFilter != null
                              ? ' aduan • ${_categoryFilter!.label}'
                              : ' aduan',
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _resetFilters,
                    child: const Text(
                      'Reset Filter',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final c = filtered[_hasActiveFilters ? index - 1 : index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
            child: ComplaintCard(
              complaint: c,
              onTap: () {
                context.read<ComplaintProvider>().selected = c;
                Navigator.pushNamed(context, '/detail');
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryToggleButton extends StatelessWidget {
  const _CategoryToggleButton({
    required this.isActive,
    required this.hasSelection,
    required this.onTap,
  });

  final bool isActive;
  final bool hasSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 15,
              color: isActive ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              'Kategori',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (hasSelection) ...[
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFFCD34D),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.badge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.badge),
          border: Border.all(
            color: selected ? const Color(0xFF93C5FD) : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.infoText : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.border,
              width: 1,
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