import 'package:flutter/material.dart';

import '../models/complaint.dart';

/// Warna lencana status. Dipilih gelap supaya teks lencana memenuhi
/// kontras minimal WCAG AA (4.5:1) di atas latar 12% opacity warna sama.
Color _statusColor(ComplaintStatus s) {
  switch (s) {
    case ComplaintStatus.menunggu:
      return const Color(0xFF8D5E00); // oranye gelap
    case ComplaintStatus.diproses:
      return const Color(0xFF0D47A1); // biru gelap
    case ComplaintStatus.selesai:
      return const Color(0xFF1B5E20); // hijau gelap
    case ComplaintStatus.ditolak:
      return const Color(0xFFB71C1C); // merah gelap
  }
}

/// Kartu daftar aduan yang digunakan di Feed & Aduan Saya.
class ComplaintCard extends StatelessWidget {
  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onTap,
  });

  final Complaint complaint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: const StadiumBorder(),
      child: InkResponse(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Foto bukti
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  complaint.photoUrl,
                  width: 72,
                  height: 72,
                  fit:.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${complaint.building} - ${complaint.floorRoom}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusBadge(status: complaint.status),
                        const Spacer(),
                        Text(
                          complaint.category.label,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ComplaintStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}