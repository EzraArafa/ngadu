import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tampilan saat daftar aduan kosong atau tidak ada yang cocok dengan filter.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.onAction,
    this.title = 'Belum ada laporan kerusakan',
    this.subtitle =
        'Belum ada laporan kerusakan pada kategori ini. Laporkan fasilitas kampus yang rusak agar segera ditangani.',
    this.actionLabel = 'Buat Aduan Baru',
    this.icon = Icons.inbox_rounded,
  });

  final VoidCallback onAction;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBorder,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                minimumSize: const Size(190, 48),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}