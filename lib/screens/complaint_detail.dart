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

/// S-06 Detail Aduan.
class ComplaintDetailScreen extends StatelessWidget {
  const ComplaintDetailScreen({super.key});

  String _shortTicketId(String id) {
    final clean = id.replaceAll('-', '').toUpperCase();
    if (clean.isEmpty) return 'BARU';
    return clean.length > 6 ? clean.substring(0, 6) : clean;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final complaint = context.watch<ComplaintProvider>().selected;
    final user = context.read<AuthController>().user;

    if (complaint == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Aduan')),
        body: const Center(child: Text('Data aduan tidak ditemukan.')),
      );
    }

    final canDelete = user != null && complaint.canDelete(user.id);
    final isAdmin = user?.isAdmin ?? false;
    final hasAdminNote =
        complaint.adminNote != null && complaint.adminNote!.trim().isNotEmpty;
    final hasProofPhoto = complaint.proofPhotoUrl != null &&
        complaint.proofPhotoUrl!.trim().isNotEmpty;
    final isOwnReport = user != null && complaint.reporterId == user.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header Detail (Kembali + #ID)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Kembali',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '#${_shortTicketId(complaint.id)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Konten Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: (isAdmin || canDelete) ? 28 : 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Foto Bukti Laporan Penuh (16:10)
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            complaint.photoUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: AppColors.surfaceSubtle,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.surfaceSubtle,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                size: 42,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: InkWell(
                              onTap: () => _showFullImage(
                                context,
                                imageUrl: complaint.photoUrl,
                                title: 'Foto Bukti Laporan',
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.input),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xCC0F172A),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.input),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.open_in_full_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Perbesar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Kumpulan Kartu Bento
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Kartu Informasi Utama
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ComplaintStatusBadge(
                                      status: complaint.status,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceSubtle,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        complaint.category.label,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  complaint.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.375,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Kotak Sorotan Lokasi Gedung & Ruangan
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTint,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.compactCard,
                                    ),
                                    border: Border.all(
                                      color: AppColors.primaryBorder,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.input,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'LOKASI KERUSAKAN',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.6,
                                                color: AppColors.secondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              complaint.building,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            if (complaint.floorRoom
                                                .trim()
                                                .isNotEmpty)
                                              Text(
                                                complaint.floorRoom,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Deskripsi Lengkap
                                const Text(
                                  'DESKRIPSI KERUSAKAN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  complaint.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 12),

                                // Info Pelapor & Tanggal
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: AppColors.surfaceSubtle,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _getInitials(complaint.reporterName),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text.rich(
                                            TextSpan(
                                              text: complaint.reporterName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                              children: [
                                                if (isOwnReport)
                                                  const TextSpan(
                                                    text: ' (Anda)',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Text(
                                            'Pelapor Fasilitas Kampus',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy, HH:mm',
                                        'id_ID',
                                      ).format(complaint.createdAt),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.cardGap),

                          // 2. Kartu Tindak Lanjut Petugas Kampus
                          if (hasAdminNote || hasProofPhoto) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.card),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.build_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Tindak Lanjut Petugas Kampus',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasAdminNote) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.input,
                                        ),
                                        border:
                                            Border.all(color: AppColors.border),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'CATATAN PETUGAS',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            complaint.adminNote!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textPrimary,
                                              height: 1.55,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (hasProofPhoto) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'FOTO BUKTI PERBAIKAN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: AppColors.successText,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.compactCard,
                                      ),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              complaint.proofPhotoUrl!,
                                              fit: BoxFit.cover,
                                            ),
                                            Positioned(
                                              right: 8,
                                              bottom: 8,
                                              child: InkWell(
                                                onTap: () => _showFullImage(
                                                  context,
                                                  imageUrl:
                                                      complaint.proofPhotoUrl!,
                                                  title: 'Foto Bukti Perbaikan',
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xBF0F172A),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      AppRadius.badge,
                                                    ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .open_in_full_rounded,
                                                        size: 12,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Perbesar',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.cardGap),
                          ],

                          // 3. Linimasa Penanganan
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.layers_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Linimasa Penanganan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _CanvasVerticalTimeline(
                                  status: complaint.status,
                                  createdAt: complaint.createdAt,
                                  adminNote: complaint.adminNote,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.cardGap),

                          // 4. Kartu Titik Lokasi GPS
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.navigation_outlined,
                                      size: 14,
                                      color: AppColors.secondary,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Titik Lokasi GPS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.compactCard,
                                  ),
                                  child: SizedBox(
                                    height: 132,
                                    child: Stack(
                                      children: [
                                        FlutterMap(
                                          options: MapOptions(
                                            initialCenter: LatLng(
                                              complaint.latitude,
                                              complaint.longitude,
                                            ),
                                            initialZoom: 16,
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName:
                                                  'com.example.ngadu',
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
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 3,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.location_on_rounded,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          left: 8,
                                          right: 8,
                                          bottom: 8,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 9,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.95),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AppRadius.badge,
                                                  ),
                                                  border: Border.all(
                                                    color: AppColors.border,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.explore_outlined,
                                                      size: 12,
                                                      color: AppColors.primary,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      '${complaint.latitude.toStringAsFixed(5)}, ${complaint.longitude.toStringAsFixed(5)}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontFamily: 'monospace',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.successBg
                                                      .withValues(alpha: 0.95),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AppRadius.badge,
                                                  ),
                                                  border: Border.all(
                                                    color:
                                                        AppColors.successBorder,
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 3,
                                                      backgroundColor:
                                                          AppColors.successDot,
                                                    ),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      'GPS Terkunci',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors
                                                            .successText,
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
            ),
          ],
        ),
      ),

      // Sticky Bottom Bar Kondisional
      bottomNavigationBar: (canDelete || isAdmin)
          ? Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: isAdmin
                      ? FilledButton.icon(
                          onPressed: () => _openAdminModal(context),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                          ),
                          icon: const Icon(Icons.build_rounded, size: 16),
                          label: const Text('Update Status Aduan'),
                        )
                      : OutlinedButton.icon(
                          onPressed: () =>
                              _confirmDelete(context, complaint.id),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            backgroundColor: AppColors.dangerBg,
                            foregroundColor: AppColors.dangerText,
                            side: const BorderSide(
                              color: AppColors.dangerBorder,
                            ),
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                          ),
                          label: const Text('Hapus Aduan'),
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
        backgroundColor: const Color(0xF2020617),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Navigator.pop(ctx),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text('Hapus Aduan Ini?'),
        content: const Text(
          'Aduan akan dihapus secara permanen dari sistem karena masih berstatus Menunggu Verifikasi.',
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
            child: const Text('Ya, Hapus'),
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

class _CanvasVerticalTimeline extends StatelessWidget {
  const _CanvasVerticalTimeline({
    required this.status,
    required this.createdAt,
    this.adminNote,
  });

  final ComplaintStatus status;
  final DateTime createdAt;
  final String? adminNote;

  @override
  Widget build(BuildContext context) {
    final isRejected = status == ComplaintStatus.ditolak;
    final createdStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(createdAt);

    final steps = isRejected
        ? [
            (
              title: 'Menunggu Verifikasi',
              done: true,
              active: false,
              rightText: createdStr,
              note: 'Laporan diterima oleh sistem NGADU.',
              dotColor: AppColors.warningDot,
              ringColor: AppColors.warningBorder,
            ),
            (
              title: 'Ditolak',
              done: true,
              active: true,
              rightText: 'Ditutup',
              note: (adminNote != null && adminNote!.trim().isNotEmpty)
                  ? adminNote!
                  : 'Aduan tidak dapat ditindaklanjuti oleh petugas.',
              dotColor: AppColors.dangerDot,
              ringColor: AppColors.dangerBorder,
            ),
          ]
        : [
            (
              title: 'Menunggu Verifikasi',
              done: true,
              active: status == ComplaintStatus.menunggu,
              rightText: createdStr,
              note: 'Laporan diterima sistem dengan titik GPS terverifikasi.',
              dotColor: AppColors.warningDot,
              ringColor: AppColors.warningBorder,
            ),
            (
              title: 'Sedang Diproses',
              done: status == ComplaintStatus.diproses ||
                  status == ComplaintStatus.selesai,
              active: status == ComplaintStatus.diproses,
              rightText: status == ComplaintStatus.menunggu
                  ? 'Menunggu giliran'
                  : 'Diproses',
              note: status == ComplaintStatus.menunggu
                  ? 'Petugas sarpras akan segera memverifikasi laporan ini.'
                  : ((adminNote != null && adminNote!.trim().isNotEmpty)
                      ? adminNote!
                      : 'Ditindaklanjuti oleh tim teknisi kampus.'),
              dotColor: AppColors.infoDot,
              ringColor: AppColors.infoBorder,
            ),
            (
              title: 'Selesai',
              done: status == ComplaintStatus.selesai,
              active: status == ComplaintStatus.selesai,
              rightText:
                  status == ComplaintStatus.selesai ? 'Tuntas' : 'Belum selesai',
              note: status == ComplaintStatus.selesai
                  ? 'Perbaikan fasilitas selesai dikerjakan.'
                  : 'Menunggu konfirmasi & foto bukti perbaikan.',
              dotColor: AppColors.successDot,
              ringColor: AppColors.successBorder,
            ),
          ];

    return Column(
      children: List.generate(steps.length, (idx) {
        final item = steps[idx];
        final isLast = idx == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: item.done ? item.dotColor : AppColors.border,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.done
                            ? item.ringColor
                            : AppColors.borderStrong,
                        width: 2,
                      ),
                      boxShadow: item.active
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.22),
                                blurRadius: 0,
                                spreadRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: item.done
                            ? AppColors.primaryBorder
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item.done
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                          Text(
                            item.rightText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.note,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: item.done
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