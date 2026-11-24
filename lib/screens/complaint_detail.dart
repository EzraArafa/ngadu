import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/complaint_card.dart';
import 'admin_status_modal.dart';

/// S-06 Detail Aduan: foto, linimasa status, catatan & bukti perbaikan,
/// mini-map GPS, serta aksi kondisional sesuai role (Hapus / Update Status).
class ComplaintDetailScreen extends StatelessWidget {
  const ComplaintDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final complaint = context.watch<ComplaintProvider>().selected;
    final user = context.read<AuthController>().user;
    final textTheme = Theme.of(context).textTheme;

    if (complaint == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Aduan')),
        body: Center(
          child: Text(
            'Data aduan tidak ditemukan.',
            style: textTheme.bodyMedium,
          ),
        ),
      );
    }

    final canDelete = user != null && complaint.canDelete(user.id);
    final isAdmin = user?.isAdmin ?? false;
    final hasAdminNote =
        complaint.adminNote != null && complaint.adminNote!.trim().isNotEmpty;
    final hasProofPhoto = complaint.proofPhotoUrl != null &&
        complaint.proofPhotoUrl!.trim().isNotEmpty;
    final locationText = complaint.floorRoom.trim().isNotEmpty
        ? '${complaint.building} • ${complaint.floorRoom}'
        : complaint.building;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Aduan'),
        actions: [
          if (canDelete)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.dangerText,
                ),
                tooltip: 'Hapus Aduan',
                onPressed: () => _confirmDelete(context, complaint.id),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Foto Bukti Laporan (dapat diketuk untuk diperbesar)
            _ZoomablePhotoBanner(
              imageUrl: complaint.photoUrl,
              badgeLabel: 'Foto Bukti Laporan',
              onTap: () => _showFullImage(
                context,
                imageUrl: complaint.photoUrl,
                title: 'Foto Bukti Laporan',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Kartu Informasi Utama Aduan
            _DetailSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ComplaintStatusBadge(status: complaint.status),
                      _CategoryBadge(category: complaint.category),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    complaint.title,
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Sorotan Lokasi Gedung & Ruangan
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            locationText,
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Deskripsi Kerusakan',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    complaint.description,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Info Pelapor & Tanggal
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.reporterName,
                              style: textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Dilaporkan ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(complaint.createdAt)}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Kartu Linimasa Penanganan
            _DetailSectionCard(
              title: 'Linimasa Penanganan',
              icon: Icons.timeline_rounded,
              child: _VerticalTimeline(status: complaint.status),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4. Kartu Tindak Lanjut Petugas (Catatan / Bukti Perbaikan)
            if (hasAdminNote || hasProofPhoto) ...[
              _DetailSectionCard(
                title: 'Tindak Lanjut Petugas',
                icon: Icons.engineering_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasAdminNote) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.notes_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                complaint.adminNote!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasProofPhoto) const SizedBox(height: AppSpacing.md),
                    ],
                    if (hasProofPhoto) ...[
                      Text(
                        'Foto Bukti Perbaikan',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ZoomablePhotoBanner(
                        imageUrl: complaint.proofPhotoUrl!,
                        height: 190,
                        badgeLabel: 'Bukti Selesai',
                        badgeColor: AppColors.successText,
                        badgeBg: AppColors.successBg,
                        badgeBorder: AppColors.successBorder,
                        onTap: () => _showFullImage(
                          context,
                          imageUrl: complaint.proofPhotoUrl!,
                          title: 'Foto Bukti Perbaikan',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // 5. Kartu Titik Koordinat Peta GPS
            _DetailSectionCard(
              title: 'Titik Lokasi GPS',
              icon: Icons.map_outlined,
              trailing: Text(
                '${complaint.latitude.toStringAsFixed(5)}, ${complaint.longitude.toStringAsFixed(5)}',
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.input),
                child: SizedBox(
                  height: 180,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter:
                          LatLng(complaint.latitude, complaint.longitude),
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
                            width: 36,
                            height: 36,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.dangerText,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isAdmin
          ? Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: FilledButton.icon(
                    onPressed: () => _openAdminModal(context),
                    icon: const Icon(Icons.edit_note_rounded, size: 22),
                    label: const Text('Update Status Aduan'),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _showFullImage(
    BuildContext context, {
    required String imageUrl,
    required String title,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 56,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Aduan?'),
        content: const Text(
          'Aduan yang masih menunggu verifikasi akan dihapus secara permanen.',
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

  void _openAdminModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ComplaintProvider>(),
        child: const AdminStatusModal(),
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.child,
    this.title,
    this.icon,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(title!, style: textTheme.titleSmall),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final ComplaintCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            category.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomablePhotoBanner extends StatelessWidget {
  const _ZoomablePhotoBanner({
    required this.imageUrl,
    required this.badgeLabel,
    required this.onTap,
    this.height = 230,
    this.badgeColor = AppColors.textPrimary,
    this.badgeBg = AppColors.surface,
    this.badgeBorder = AppColors.border,
  });

  final String imageUrl;
  final String badgeLabel;
  final VoidCallback onTap;
  final double height;
  final Color badgeColor;
  final Color badgeBg;
  final Color badgeBorder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.surfaceSubtle,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2.2),
                );
              },
              errorBuilder: (_, _, _) => Container(
                color: AppColors.surfaceSubtle,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  size: 44,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeBg.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.zoom_out_map_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Perbesar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linimasa status vertikal: Menunggu Verifikasi -> Sedang Diproses -> Selesai/Ditolak.
class _VerticalTimeline extends StatelessWidget {
  const _VerticalTimeline({required this.status});

  final ComplaintStatus status;

  static const _steps = [
    ComplaintStatus.menunggu,
    ComplaintStatus.diproses,
    ComplaintStatus.selesai,
  ];

  int get _currentIndex {
    if (status == ComplaintStatus.ditolak) return 2;
    return _steps.indexOf(status);
  }

  String _subtitleForStep(int index, bool isRejected) {
    if (index == 0) return 'Laporan masuk dan menunggu pengecekan admin';
    if (index == 1) return 'Laporan diverifikasi dan sedang ditindaklanjuti';
    return isRejected
        ? 'Aduan tidak dapat ditindaklanjuti oleh petugas'
        : 'Perbaikan fasilitas telah selesai dikerjakan';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: List.generate(_steps.length, (index) {
        final step = _steps[index];
        final isCompleted = index <= _currentIndex;
        final isLast = index == _steps.length - 1;
        final isRejected = status == ComplaintStatus.ditolak && isLast;

        final activeColor = isRejected
            ? AppColors.dangerText
            : (index == 2 && isCompleted
                ? AppColors.successText
                : AppColors.primary);

        final dotColor = isCompleted ? activeColor : AppColors.borderStrong;
        final label = isRejected ? ComplaintStatus.ditolak.label : step.label;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indikator titik & garis vertikal
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isCompleted ? dotColor : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dotColor,
                          width: isCompleted ? 0 : 2,
                        ),
                      ),
                      child: isCompleted
                          ? Icon(
                              isRejected
                                  ? Icons.close_rounded
                                  : Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          color: index < _currentIndex
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Teks Tahapan
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: textTheme.titleSmall?.copyWith(
                          color: isCompleted
                              ? (isRejected
                                  ? AppColors.dangerText
                                  : AppColors.textPrimary)
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitleForStep(index, isRejected),
                        style: textTheme.bodySmall?.copyWith(
                          color: isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}