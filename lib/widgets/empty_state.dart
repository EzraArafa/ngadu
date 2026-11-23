import 'package:flutter/material.dart';

/// Tampilan saat daftar aduan kosong (atau hasil filter kosong).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.report_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada laporan kerusakan pada kategori ini',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: const Text('Buat Aduan'),
            ),
          ],
        ),
      ),
    );
  }
}