import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// S-07 Bottom Sheet Modal Update Status (khusus Admin — Grid 2x2).
class AdminStatusModal extends StatefulWidget {
  const AdminStatusModal({super.key});

  @override
  State<AdminStatusModal> createState() => _AdminStatusModalState();
}

class _AdminStatusModalState extends State<AdminStatusModal> {
  ComplaintStatus _status = ComplaintStatus.diproses;
  File? _proofPhoto;
  final _noteController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final selected = context.read<ComplaintProvider>().selected;
    if (selected != null) {
      _status = selected.status;
      _noteController.text = selected.adminNote ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() {
          _proofPhoto = File(picked.path);
          _error = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memilih foto bukti.');
    }
  }

  String _shortTicketId(String id) {
    final clean = id.replaceAll('-', '').toUpperCase();
    if (clean.isEmpty) return 'BARU';
    return clean.length > 6 ? clean.substring(0, 6) : clean;
  }

  bool get _proofRequired => _status == ComplaintStatus.selesai;
  bool get _canSave => !_saving && (!_proofRequired || _proofPhoto != null);

  Future<void> _save() async {
    if (!_canSave) return;

    final complaint = context.read<ComplaintProvider>().selected;
    final user = context.read<AuthController>().user;
    if (complaint == null || user == null) {
      setState(() => _error = 'Data aduan atau sesi admin tidak ditemukan.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      String? proofUrl;
      if (_proofPhoto != null) {
        proofUrl = await SupabaseService.uploadPhoto(_proofPhoto!, user.id);
      }
      if (!mounted) return;
      await context.read<ComplaintProvider>().updateStatus(
            id: complaint.id,
            status: _status,
            adminNote: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            proofPhotoUrl: proofUrl,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status aduan diperbarui menjadi "${_status.label}"'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal menyimpan perubahan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = context.read<ComplaintProvider>().selected;
    final ticketId = _shortTicketId(complaint?.id ?? '');

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: 4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Status Aduan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tiket #$ticketId • Mode Petugas Kampus',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _saving ? null : () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Pilih Status Terbaru',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.8,
              children: ComplaintStatus.values.map((s) {
                return _GridStatusCard(
                  status: s,
                  selected: _status == s,
                  onTap: _saving
                      ? null
                      : () => setState(() {
                            _status = s;
                            _error = null;
                          }),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Foto Bukti Perbaikan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_proofRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.dangerBorder),
                    ),
                    child: const Text(
                      'WAJIB untuk Selesai',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dangerText,
                      ),
                    ),
                  )
                else
                  const Text(
                    'Opsional',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            if (_proofPhoto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.compactCard),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_proofPhoto!, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: _saving
                              ? null
                              : () => setState(() => _proofPhoto = null),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xBF0F172A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successDot,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Bukti Terlampir',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              InkWell(
                onTap: _saving ? null : _pickProof,
                borderRadius: BorderRadius.circular(AppRadius.compactCard),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.compactCard),
                    border: Border.all(
                      color: _proofRequired
                          ? AppColors.primaryBorder
                          : AppColors.borderStrong,
                      width: 1.2,
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 22,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Pilih Foto Bukti Perbaikan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_proofRequired && _proofPhoto == null) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 13,
                    color: AppColors.dangerText,
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Pilih foto bukti perbaikan terlebih dahulu untuk menandai Selesai.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.dangerText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Catatan Petugas',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              enabled: !_saving,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Tuliskan progres perbaikan atau alasan penolakan...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (_error != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dangerText,
                  ),
                ),
              ),
            ],

            FilledButton.icon(
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textMuted,
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: Text(
                _saving ? 'Menyimpan...' : 'Simpan Perubahan Status',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridStatusCard extends StatelessWidget {
  const _GridStatusCard({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final ComplaintStatus status;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = status.style;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.compactCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryTint.withValues(alpha: 0.45)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.compactCard),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(style.icon, size: 14, color: style.foreground),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}