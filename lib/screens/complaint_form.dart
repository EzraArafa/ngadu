import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// S-04 Form Buat Aduan.
/// Foto awal wajib dari kamera (aturan bisnis #1), GPS terkunci otomatis.
class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _floorController = TextEditingController();

  ComplaintCategory _category = ComplaintCategory.listrikAc;
  String _building = kDaftarGedung.first;
  File? _photo;
  GpsResult? _gps;
  String? _gpsError;
  bool _isOpeningCamera = false;
  bool _isLocating = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _captureAndLocate();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  /// Buka kamera + kunci GPS secara berurutan saat layar dibuka.
  Future<void> _captureAndLocate() async {
    await _takePhoto();
    await _fetchLocation();
  }

  Future<void> _takePhoto() async {
    if (_isOpeningCamera) return;
    setState(() => _isOpeningCamera = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() => _photo = File(picked.path));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamera tidak dapat diakses.')),
      );
    } finally {
      if (mounted) setState(() => _isOpeningCamera = false);
    }
  }

  Future<void> _fetchLocation() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _gpsError = null;
    });

    try {
      final gps = await LocationService.getCurrentPosition();
      if (mounted) setState(() => _gps = gps);
    } on LocationPermissionException catch (e) {
      if (mounted) setState(() => _gpsError = e.message);
    } catch (_) {
      if (mounted) setState(() => _gpsError = 'Gagal membaca lokasi GPS.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openAppSettings() async {
    await AppSettings.openAppSettings();
  }

  bool get _canSubmit =>
      _photo != null &&
      _gps != null &&
      _titleController.text.trim().isNotEmpty &&
      _descController.text.trim().isNotEmpty &&
      _floorController.text.trim().isNotEmpty &&
      !_isSubmitting;

  String? get _submitHint {
    if (_photo == null) return 'Ambil foto bukti kerusakan terlebih dahulu';
    if (_gps == null) return 'Menunggu koordinat GPS terkunci';
    if (_floorController.text.trim().isEmpty ||
        _titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      return 'Lengkapi seluruh kolom bertanda wajib (*)';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _photo == null || _gps == null) {
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthController>();
      final nav = Navigator.of(context);
      final cp = context.read<ComplaintProvider>();
      final user = auth.user;
      if (user == null) throw Exception('Sesi berakhir. Silakan login ulang.');

      final photoUrl = await SupabaseService.uploadPhoto(_photo!, user.id);
      if (!mounted) return;

      final complaint = Complaint(
        id: '',
        reporterId: user.id,
        reporterName: user.name,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        building: _building,
        floorRoom: _floorController.text.trim(),
        latitude: _gps!.lat,
        longitude: _gps!.lng,
        photoUrl: photoUrl,
        status: ComplaintStatus.menunggu,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final saved = await cp.create(complaint);
      if (!mounted) return;
      cp.selected = saved;
      nav.pushReplacementNamed('/detail');
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim aduan: $e'),
          action: SnackBarAction(
            label: 'Coba Lagi',
            onPressed: _submit,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Aduan Baru'),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            // Bagian 1: Bukti Foto & Lokasi GPS
            _SectionCard(
              stepNumber: '1',
              title: 'Bukti Foto & Titik Lokasi',
              subtitle: 'Wajib diambil langsung dari kamera di lokasi kejadian',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPhotoPreview(textTheme),
                  const SizedBox(height: AppSpacing.md),
                  _buildMiniMap(textTheme),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Bagian 2: Kategori & Lokasi Spesifik
            _SectionCard(
              stepNumber: '2',
              title: 'Kategori & Area Kampus',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<ComplaintCategory>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: 'Kategori Kerusakan *',
                      prefixIcon: Icon(
                        _category.icon,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    items: ComplaintCategory.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Icon(
                                  c.icon,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Text(c.label),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _building,
                    decoration: const InputDecoration(
                      labelText: 'Gedung / Zona *',
                      prefixIcon: Icon(
                        Icons.apartment_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    items: kDaftarGedung
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _building = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _floorController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Lantai & Ruangan / Patokan *',
                      hintText: 'Contoh: Lt. 3, Ruang 302',
                      prefixIcon: Icon(
                        Icons.meeting_room_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Lantai & ruangan wajib diisi'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Bagian 3: Detail Laporan
            _SectionCard(
              stepNumber: '3',
              title: 'Keterangan Kerusakan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Judul Aduan *',
                      hintText: 'Contoh: AC Bocor Ruang 302',
                      prefixIcon: Icon(
                        Icons.title_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Judul wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Kerusakan *',
                      hintText:
                          'Jelaskan kondisi kerusakan secara singkat agar petugas mudah menindaklanjuti',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Deskripsi wajib diisi'
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_submitHint != null && !_isSubmitting) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _submitHint!,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                FilledButton.icon(
                  onPressed: _canSubmit ? _submit : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isSubmitting ? 'Mengirim Aduan...' : 'Kirim Aduan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(TextTheme textTheme) {
    if (_photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.file(
                _photo!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: AppColors.successText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Foto Kamera Siap',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.successText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Material(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                onTap: _isOpeningCamera ? null : _takePhoto,
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
                        Icons.camera_alt_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ambil Ulang',
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
      onTap: _isOpeningCamera ? null : _takePhoto,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Container(
        height: 176,
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primarySoft.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: AppColors.primaryBorder,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _isOpeningCamera
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _isOpeningCamera
                  ? 'Membuka kamera...'
                  : 'Ketuk untuk Ambil Foto Bukti',
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Foto harus diambil langsung menggunakan kamera',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMap(TextTheme textTheme) {
    if (_gpsError != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: AppColors.warningBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_off_rounded,
                  size: 20,
                  color: AppColors.warningText,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _gpsError!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.warningText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _fetchLocation,
                  child: const Text('Coba Lagi'),
                ),
                const SizedBox(width: AppSpacing.xs),
                OutlinedButton(
                  onPressed: _openAppSettings,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: AppColors.warningBorder),
                    foregroundColor: AppColors.warningText,
                  ),
                  child: const Text('Buka Pengaturan'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_gps == null) {
      return Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mengunci koordinat GPS...',
                    style: textTheme.titleSmall,
                  ),
                  Text(
                    'Pastikan layanan lokasi perangkat aktif',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            color: AppColors.surfaceSubtle,
            child: Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  size: 16,
                  color: AppColors.successText,
                ),
                const SizedBox(width: 6),
                Text(
                  'GPS Terkunci',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.successText,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_gps!.lat.toStringAsFixed(5)}, ${_gps!.lng.toStringAsFixed(5)}',
                  style: textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _isLocating ? null : _fetchLocation,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 132,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_gps!.lat, _gps!.lng),
                initialZoom: 17,
                interactionOptions: const InteractionOptions(flags: 0),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ngadu',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_gps!.lat, _gps!.lng),
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
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.stepNumber,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String stepNumber;
  final String title;
  final String? subtitle;
  final Widget child;

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
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}