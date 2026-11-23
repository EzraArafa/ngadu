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

  /// Buka kamera + kunci GPS. Dipanggil saat layar dibuka (alur B wireframe).
  Future<void> _captureAndLocate() async {
    // 1. Kamera
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _photo = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamera tidak dapat diakses.')),
      );
    }

    // 2. GPS
    try {
      final gps = await LocationService.getCurrentPosition();
      if (mounted) setState(() => _gps = gps);
    } on LocationPermissionException catch (e) {
      if (mounted) setState(() => _gpsError = e.message);
    } catch (_) {
      if (mounted) setState(() => _gpsError = 'Gagal membaca lokasi GPS.');
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _photo == null || _gps == null) {
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthController>();
      final user = auth.user;
      if (user == null) throw Exception('Sesi berakhir. Silakan login ulang.');

      final photoUrl = await SupabaseService.uploadPhoto(_photo!, user.id);
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
      final nav = Navigator.of(context);
      final cp = context.read<ComplaintProvider>();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Aduan Baru')),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preview foto
            _buildPhotoPreview(),

            const SizedBox(height: 12),

            // Mini-map GPS
            _buildMiniMap(),

            const SizedBox(height: 16),

            DropdownButtonFormField<ComplaintCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori *',
                border: OutlineInputBorder(),
              ),
              items: ComplaintCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.label),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _building,
              decoration: const InputDecoration(
                labelText: 'Gedung / Zona *',
                border: OutlineInputBorder(),
              ),
              items: kDaftarGedung
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _building = v!),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _floorController,
              decoration: const InputDecoration(
                labelText: 'Lantai & Ruangan / Patokan *',
                hintText: 'Contoh: Lt. 3, Ruang 302',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Lantai & ruangan wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Aduan *',
                hintText: 'Contoh: AC Bocor Ruang 302',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Judul wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Kerusakan *',
                hintText: 'Jelaskan kondisi singkat kerusakan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Deskripsi wajib diisi'
                  : null,
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('KIRIM ADUAN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _photo != null
              ? Image.file(
                  _photo!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(child: Text('Membuka kamera...')),
                ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton.filledTonal(
            icon: const Icon(Icons.refresh),
            tooltip: 'Foto Ulang',
            onPressed: _captureAndLocate,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMap() {
    if (_gpsError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange.shade800),
            const SizedBox(width: 8),
            Expanded(child: Text(_gpsError!)),
            TextButton(
              onPressed: _openAppSettings,
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
    }

    if (_gps == null) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Mencari lokasi GPS...'),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
    );
  }
}
