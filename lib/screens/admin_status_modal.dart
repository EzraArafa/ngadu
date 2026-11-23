import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../services/supabase_service.dart';

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
      if (picked != null) {
        setState(() => _proofPhoto = File(picked.path));
      }
    } catch (e) {
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tindak Lanjuti Aduan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            const Text(
              'Ubah Status Penanganan *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...ComplaintStatus.values.map(
              (s) => RadioListTile<ComplaintStatus>(
                title: Text(s.label),
                value: s,
                groupValue: _status,
                onChanged: (v) => setState(() => _status = v!),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              _proofRequired
                  ? 'Foto Bukti Perbaikan * (wajib untuk Selesai)'
                  : 'Foto Bukti Perbaikan (opsional)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickProof,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                alignment: Alignment.center,
                child: _proofPhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _proofPhoto!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 36, color: Colors.grey.shade600),
                          const SizedBox(height: 6),
                          Text('Ambil / Pilih Foto',
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan Petugas / Keterangan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
            ],

            FilledButton(
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('SIMPAN PERUBAHAN'),
            ),
          ],
        ),
      ),
    );
  }
}