import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/complaint_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/error_state.dart';

/// S-05 Aduan Saya & Profil: riwayat aduan + profil + logout.
class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  late Future<List<Complaint>> _myFuture;

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

  Future<void> _logout() async {
    try {
      if (SupabaseService.isConfigured) await SupabaseService.signOut();
    } catch (_) {}
    if (!mounted) return;
    context.read<AuthController>().setUnauthenticated();
    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext context) {
    final NgaduUser? user = context.watch<AuthController>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aduan Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Belum login. Silakan autentikasi ulang.'))
          : FutureBuilder<List<Complaint>>(
              future: _myFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snapshot.hasError) {
                  return ErrorState(
                    message: 'Gagal memuat riwayat aduan. Periksa koneksi.',
                    onRetry: _refresh,
                  );
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return EmptyState(
                    onAction: () => Navigator.pushNamed(context, '/form'),
                  );
                }

                // Ringkasan sederhana: total dan selesai
                final total = list.length;
                final selesai =
                    list.where((c) => c.status == ComplaintStatus.selesai).length;

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${user.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Role: ${user.role}'),
                          const SizedBox(height: 12),
                          Text('Total: $total | Selesai: $selesai'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 4),
                          itemBuilder: (_, index) {
                            final c = list[index];
                            return ComplaintCard(
                              complaint: c,
                              onTap: () => _onCardTap(c),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
