import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../providers/complaint_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/complaint_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';

/// S-03 Beranda / Feed Aduan + NavigationBar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  ComplaintStatus? _statusFilter;
  ComplaintCategory? _categoryFilter;
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
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (e) {
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
      return;
    }
    if (index == 2) {
      Navigator.pushNamed(context, '/my');
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.report_problem_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'NGADU',
              style: textTheme.titleLarge?.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<ComplaintCategory?>(
            tooltip: 'Filter Kategori',
            onSelected: (val) => setState(() => _categoryFilter = val),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: _categoryFilter != null
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
                if (_categoryFilter != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            itemBuilder: (_) => [
              PopupMenuItem<ComplaintCategory?>(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.apps_rounded,
                      size: 18,
                      color: _categoryFilter == null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Semua Kategori',
                      style: TextStyle(
                        fontWeight: _categoryFilter == null
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _categoryFilter == null
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...ComplaintCategory.values.map(
                (cat) => PopupMenuItem<ComplaintCategory?>(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(
                        cat.icon,
                        size: 18,
                        color: _categoryFilter == cat
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontWeight: _categoryFilter == cat
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _categoryFilter == cat
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Panel Pencarian & Filter Status
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    hintText: 'Cari judul aduan, gedung, atau kerusakan...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 11,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Chip Filter Status Horizontal
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
                          accentColor: s.style.foreground,
                          onTap: () => setState(() => _statusFilter = s),
                        ),
                      ),
                    ],
                  ),
                ),

                // Indikator Kategori Aktif (jika dipilih dari menu)
                if (_categoryFilter != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.primaryBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _categoryFilter!.icon,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Kategori: ${_categoryFilter!.label}',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _categoryFilter = null),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Daftar Aduan
          Expanded(
            child: _buildList(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _navIndex,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primarySoft,
          height: 68,
          onDestinationSelected: _onNavTap,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_box_outlined, color: AppColors.primary),
              selectedIcon:
                  Icon(Icons.add_box_rounded, color: AppColors.primary),
              label: 'Buat Aduan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon:
                  Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Aduan Saya',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_initialLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingState(),
      );
    }
    if (_errorMsg != null) {
      return ErrorState(message: _errorMsg!, onRetry: _loadComplaints);
    }

    final complaints = context.watch<ComplaintProvider>().all;
    final filtered = _applyFilters(complaints);

    if (filtered.isEmpty) {
      if (_hasActiveFilters && complaints.isNotEmpty) {
        return EmptyState(
          icon: Icons.filter_alt_off_rounded,
          title: 'Aduan tidak ditemukan',
          subtitle:
              'Tidak ada laporan yang cocok dengan filter atau kata kunci pencarian saat ini.',
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
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, index) {
          final c = filtered[index];
          return ComplaintCard(
            complaint: c,
            onTap: () {
              context.read<ComplaintProvider>().selected = c;
              Navigator.pushNamed(context, '/detail');
            },
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accentColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (accentColor != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}