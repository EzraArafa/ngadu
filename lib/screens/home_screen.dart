import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../providers/complaint_provider.dart';
import '../widgets/complaint_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/error_state.dart';

/// S-03 Beranda / Feed Aduan + BottomNavigationBar.
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('NGADU'),
        actions: [
          PopupMenuButton<ComplaintCategory?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Kategori',
            onSelected: (val) => setState(() => _categoryFilter = val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Semua Kategori')),
              ...ComplaintCategory.values.map(
                (cat) => PopupMenuItem(value: cat, child: Text(cat.label)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chip filter status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                ),
                ...ComplaintStatus.values.map(
                  (s) => _FilterChip(
                    label: s.label,
                    selected: _statusFilter == s,
                    onTap: () => setState(() => _statusFilter = s),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Cari aduan...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Daftar aduan
          Expanded(
            child: _buildList(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onNavTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline, size: 32),
            label: 'Buat Aduan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Aduan Saya',
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_initialLoading) return const LoadingState();
    if (_errorMsg != null) {
      return ErrorState(message: _errorMsg!, onRetry: _loadComplaints);
    }

    final complaints = context.watch<ComplaintProvider>().all;
    final filtered = _applyFilters(complaints);

    if (filtered.isEmpty) {
      return EmptyState(
        onAction: () => Navigator.pushNamed(context, '/form'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
