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

/// S-04 Form Buat Aduan (Wizard 3 Langkah).
class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  int _step = 1; // 1 = Foto & GPS, 2 = Lokasi, 3 = Detail

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _floorController = TextEditingController();

  ComplaintCategory _category = ComplaintCategory.listrikAc;
  String _building = kDaftarGedung.first;
  File? _photo;
  GpsResult? _gps;
  String? _gpsError;
  String? _formError;
  bool _isOpeningCamera = false;
  bool _isLocating = false;
  bool _isSubmitting = false;

  static const _stepLabels = ['Foto & GPS', 'Lokasi', 'Detail'];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _floorController.dispose();
    super.dispose();
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
        setState(() {
          _photo = File(picked.path);
          _formError = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Kamera tidak dapat diakses.');
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
      if (mounted) {
        setState(() {
          _gps = gps;
          _formError = null;
        });
      }
    } on LocationPermissionException catch (e) {
      if (mounted) setState(() => _gpsError = e.message);
    } catch (_) {
      if (mounted) setState(() => _gpsError = 'Gagal membaca lokasi GPS.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _handleNextStep() {
    setState(() => _formError = null);

    if (_step == 1) {
      if (_photo == null) {
        setState(() {
          _formError =
              'Wajib mengambil foto bukti kerusakan langsung melalui kamera.';
        });
        return;
      }
      if (_gps == null) {
        setState(() {
          _formError =
              'Menunggu koordinat GPS terkunci. Pastikan GPS perangkat aktif.';
        });
        return;
      }
      setState(() => _step = 2);
    } else if (_step == 2) {
      if (_floorController.text.trim().isEmpty) {
        setState(() {
          _formError = 'Mohon isi detail lantai & ruangan lokasi kerusakan.';
        });
        return;
      }
      setState(() => _step = 3);
    }
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (_titleController.text.trim().length < 5) {
      setState(() => _formError = 'Judul aduan minimal 5 karakter.');
      return;
    }
    if (_descController.text.trim().length < 10) {
      setState(() {
        _formError =
            'Deskripsi kerusakan minimal 10 karakter agar petugas mudah menindaklanjuti.';
      });
      return;
    }
    if (_photo == null || _gps == null) return;

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
      setState(() => _formError = 'Gagal mengirim aduan: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header Form + Stepper Indicator
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buat Aduan Baru',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Langkah $_step dari 3 • ${_stepLabels[_step - 1]}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
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
                  const SizedBox(height: AppSpacing.md),

                  // 3-Step Horizontal Progress Bar
                  Row(
                    children: List.generate(3, (idx) {
                      final stepNum = idx + 1;
                      final isCompleted = _step > stepNum;
                      final isCurrent = _step == stepNum;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 6,
                                decoration: BoxDecoration(
                                  color: (isCompleted || isCurrent)
                                      ? AppColors.primary
                                      : AppColors.border,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$stepNum. ${_stepLabels[idx]}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrent
                                      ? AppColors.primary
                                      : (isCompleted
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Konten Langkah Aktif
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  32,
                ),
                children: [
                  if (_formError != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius:
                            BorderRadius.circular(AppRadius.compactCard),
                        border: Border.all(color: AppColors.dangerBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: AppColors.dangerText,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _formError!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.dangerText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_step == 1) _buildStep1PhotoAndGps(),
                  if (_step == 2) _buildStep2LocationAndCategory(),
                  if (_step == 3) _buildStep3Details(),
                ],
              ),
            ),
          ],
        ),
      ),

      // Footer Navigasi Langkah
      bottomNavigationBar: Container(
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
            child: Row(
              children: [
                if (_step > 1) ...[
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                              _formError = null;
                              _step -= 1;
                            }),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(92, 46),
                    ),
                    child: const Text('Kembali'),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _step < 3
                      ? FilledButton(
                          onPressed: _handleNextStep,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Lanjut ke ${_stepLabels[_step]}'),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded, size: 18),
                            ],
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 17,
                                ),
                          label: Text(
                            _isSubmitting
                                ? 'Mengirim Aduan...'
                                : 'Kirim Aduan Sekarang',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1PhotoAndGps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Bukti Foto Kerusakan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: const Text(
                      'Wajib Kamera',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warningText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Demi keaslian laporan, foto wajib diambil langsung menggunakan kamera perangkat (bukan dari galeri).',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (_photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.compactCard),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_photo!, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successDot,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.badge),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Foto Kamera Terverifikasi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: InkWell(
                            onTap: _isOpeningCamera ? null : _takePhoto,
                            borderRadius: BorderRadius.circular(AppRadius.input),
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
                                    Icons.refresh_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Ambil Ulang',
                                    style: TextStyle(
                                      fontSize: 11,
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
                )
              else
                InkWell(
                  onTap: _isOpeningCamera ? null : _takePhoto,
                  borderRadius: BorderRadius.circular(AppRadius.compactCard),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint.withValues(alpha: 0.65),
                        borderRadius:
                            BorderRadius.circular(AppRadius.compactCard),
                        border: Border.all(
                          color: const Color(0xFF93C5FD),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.compactCard),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ambil Foto via Kamera',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.infoText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Ketuk untuk membuka kamera perangkat',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
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
        const SizedBox(height: AppSpacing.lg),

        // Kartu Status GPS Terkunci
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.navigation_outlined,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Koordinat GPS Otomatis',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _gps != null
                          ? AppColors.successBg
                          : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: _gps != null
                            ? AppColors.successBorder
                            : AppColors.warningBorder,
                      ),
                    ),
                    child: Text(
                      _gps != null ? 'Akurasi Tinggi' : 'Mencari GPS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _gps != null
                            ? AppColors.successText
                            : AppColors.warningText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_gpsError != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius:
                        BorderRadius.circular(AppRadius.compactCard),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _gpsError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.warningText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _fetchLocation,
                            child: const Text('Coba Lagi'),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            onPressed: () => AppSettings.openAppSettings(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 34),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Text('Pengaturan'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else if (_gps == null)
                Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius:
                        BorderRadius.circular(AppRadius.compactCard),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.secondary,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Mengunci koordinat GPS...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.compactCard),
                  child: SizedBox(
                    height: 124,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(_gps!.lat, _gps!.lng),
                            initialZoom: 17,
                            interactionOptions:
                                const InteractionOptions(flags: 0),
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
                                  point: LatLng(_gps!.lat, _gps!.lng),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.badge),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.explore_outlined,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${_gps!.lat.toStringAsFixed(5)}, ${_gps!.lng.toStringAsFixed(5)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: _isLocating ? null : _fetchLocation,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successBg
                                        .withValues(alpha: 0.95),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.badge),
                                    border: Border.all(
                                      color: AppColors.successBorder,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 3,
                                        backgroundColor: AppColors.successDot,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'GPS Terkunci',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.successText,
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
                ),
                const SizedBox(height: 10),
                Text(
                  'Lokasi perangkat Anda terkunci otomatis di area kampus (${_gps!.lat.toStringAsFixed(5)}, ${_gps!.lng.toStringAsFixed(5)}) untuk mempercepat navigasi petugas.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2LocationAndCategory() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Kategori Kerusakan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<ComplaintCategory>(
            initialValue: _category,
            items: ComplaintCategory.values
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.label),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          const Text(
            'Gedung / Area Kampus',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _building,
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
          const SizedBox(height: AppSpacing.lg),

          const Text(
            'Lantai & Ruangan / Titik Spesifik',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _floorController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Contoh: Lantai 3, Ruang 305 Sisi Selatan',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Petugas unit ',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: _category.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const TextSpan(text: ' akan diarahkan ke '),
                        TextSpan(
                          text: '$_building.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
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
    );
  }

  Widget _buildStep3Details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Judul Aduan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Stopkontak Ruang Kelas Percikan Api',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Deskripsi Kerusakan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Jelaskan kondisi kerusakan, sejak kapan terjadi, dan dampaknya terhadap aktivitas kampus...',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (_photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  child: Image.file(
                    _photo!,
                    width: 64,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _category.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_building • ${_floorController.text.trim()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_gps != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'GPS Terkunci (${_gps!.lat.toStringAsFixed(5)}, ${_gps!.lng.toStringAsFixed(5)})',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.successText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}