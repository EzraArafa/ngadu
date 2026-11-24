import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// S-07 Modal Update Status (khusus Admin): pilih status, foto bukti
/// (wajib jika Selesai), catatan petugas, lalu simpan.
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

  bool get _proofRequired => _status == ComplaintStatus.selesai;
  bool get _canSave => !_saving && (!_proofRequired || _proofPhoto != null);

  Future<void> _save() async {
    if (!_canSave) {
      setState(() => _error = 'Foto bukti wajib diunggah untuk status Selesai.');
      return;
    }

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
        const SnackBar(content: Text('Status aduan berhasil diperbarui.')),
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Modal
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tindak Lanjuti Aduan',
                          style: textTheme.titleMedium,
                        ),
                        Text(
                          'Perbarui progres penanganan fasilitas',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Tutup',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),

              // Pilihan Status Penanganan
              Text(
                'Status Penanganan *',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...ComplaintStatus.values.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _StatusOptionTile(
                    status: s,
                    selected: _status == s,
                    onTap: _saving
                        ? null
                        : () => setState(() {
                              _status = s;
                              _error = null;
                            }),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Foto Bukti Perbaikan
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Foto Bukti Perbaikan',
                      style: textTheme.titleSmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _proofRequired
                          ? AppColors.warningBg
                          : AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                      border: Border.all(
                        color: _proofRequired
                            ? AppColors.warningBorder
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      _proofRequired ? 'Wajib untuk Selesai' : 'Opsional',
                      style: textTheme.labelSmall?.copyWith(
                        color: _proofRequired
                            ? AppColors.warningText
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildProofPicker(textTheme),
              const SizedBox(height: AppSpacing.lg),

              // Catatan Petugas
              TextField(
                controller: _noteController,
                enabled: !_saving,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Catatan Petugas / Keterangan',
                  hintText:
                      'Tuliskan tindakan perbaikan atau alasan penolakan...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Banner Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: AppColors.dangerText,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _error!,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.dangerText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Tombol Simpan
              FilledButton.icon(
                onPressed: _canSave ? _save : null,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 19),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProofPicker(TextTheme textTheme) {
    if (_proofPhoto != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: Image.file(
              _proofPhoto!,
              height: 156,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Material(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                onTap: _saving ? null : _pickProof,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ganti Foto',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _saving ? null : _pickProof,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Container(
        height: 124,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: _proofRequired
              ? AppColors.primarySoft.withValues(alpha: 0.45)
              : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color:
                _proofRequired ? AppColors.primaryBorder : AppColors.border,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 32,
              color: _proofRequired
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih Foto Bukti dari Galeri',
              style: textTheme.titleSmall?.copyWith(
                color: _proofRequired
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Format JPG/PNG, maks. lebar 1600px',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOptionTile extends StatelessWidget {
  const _StatusOptionTile({
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
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected ? style.background : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: selected ? style.foreground : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? style.foreground : style.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                style.icon,
                size: 16,
                color: selected ? Colors.white : style.foreground,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                status.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? style.foreground : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? style.foreground : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}