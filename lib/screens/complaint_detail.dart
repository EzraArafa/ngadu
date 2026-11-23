import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import 'admin_status_modal.dart';

/// S-06 Detail Aduan: foto, mini-map, linimasa status, bukti perbaikan,
/// serta aksi kondisional sesuai role (Hapus / Update Status).
class ComplaintDetailScreen extends StatelessWidget {
  const ComplaintDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final complaint = context.watch<ComplaintProvider>().selected;
    final user = context.read<AuthController>().user;

    if (complaint == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Aduan')),
        body: const Center(child: Text('Aduan tidak ditemukan.')),
      );
    }

    final canDelete = user != null && complaint.canDelete(user.id);
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Aduan'),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus Aduan',
              onPressed: () => _confirmDelete(context, complaint.id),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto bukti laporan
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                complaint.photoUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 220,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kategori + Status
            Row(
              children: [
                _InfoChip(label: complaint.category.label),
                const SizedBox(width: 8),
                _StatusChip(status: complaint.status),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              complaint.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${complaint.building} - ${complaint.floorRoom}',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              complaint.description,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),

            Text(
              'Dilaporkan oleh ${complaint.reporterName} '
              'pada ${DateFormat('dd MMM yyyy', 'id').format(complaint.createdAt)}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const Divider(height: 28),

            // Peta titik koordinat GPS
            const Text(
              'Lokasi Peta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(complaint.latitude, complaint.longitude),
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ngadu',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            complaint.latitude,
                            complaint.longitude,
                          ),
                          width: 32,
                          height: 32,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${complaint.latitude.toStringAsFixed(5)}, '
              '${complaint.longitude.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const Divider(height: 28),

            // Linimasa status
            const Text(
              'Linimasa Penanganan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _Timeline(status: complaint.status),
            const SizedBox(height: 16),

            // Catatan admin
            if (complaint.adminNote != null &&
                complaint.adminNote!.isNotEmpty) ...[
              const Text(
                'Catatan Petugas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(complaint.adminNote!),
              ),
              const SizedBox(height: 16),
            ],

            // Foto bukti perbaikan
            if (complaint.proofPhotoUrl != null &&
                complaint.proofPhotoUrl!.isNotEmpty) ...[
              const Text(
                'Foto Bukti Perbaikan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  complaint.proofPhotoUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      bottomNavigationBar: isAdmin
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.icon(
                  onPressed: () => _openAdminModal(context, complaint),
                  icon: const Icon(Icons.edit_document),
                  label: const Text('UPDATE STATUS'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Aduan?'),
        content: const Text(
          'Aduan yang masih menunggu verifikasi akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<ComplaintProvider>().delete(id);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aduan berhasil dihapus.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus aduan: $e')),
      );
    }
  }

  void _openAdminModal(BuildContext context, Complaint complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ComplaintProvider>(),
        child: const AdminStatusModal(),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ComplaintStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ComplaintStatus.menunggu => const Color(0xFF8D5E00),
      ComplaintStatus.diproses => const Color(0xFF0D47A1),
      ComplaintStatus.selesai => const Color(0xFF1B5E20),
      ComplaintStatus.ditolak => const Color(0xFFB71C1C),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.blue.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Linimasa status berurutan: Menunggu, Diproses, Selesai/Ditolak.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});
  final ComplaintStatus status;

  static const steps = [
    ComplaintStatus.menunggu,
    ComplaintStatus.diproses,
    ComplaintStatus.selesai,
  ];

  int get currentIndex {
    if (status == ComplaintStatus.ditolak) return 2;
    return steps.indexWhere((s) => s == status);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...steps.asMap().entries.map((entry) {
          final i = entry.value;
          final done = entry.key <= currentIndex;
          final isRejected = status == ComplaintStatus.ditolak && entry.key == 2;
          return Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done
                    ? (isRejected ? Colors.red : Colors.green)
                    : Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  isRejected
                      ? ComplaintStatus.ditolak.label
                      : i.label,
                  style: TextStyle(
                    fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                    color: done ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
