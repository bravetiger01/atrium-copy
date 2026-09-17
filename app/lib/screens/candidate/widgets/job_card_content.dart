import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Job Card Content — pure UI, used in both swipe stack and detail sheet
// ─────────────────────────────────────────────────────────────────────────────

class JobCardContent extends StatelessWidget {
  final Map<String, dynamic> job;
  final String jobId;
  final double? distanceKm;

  const JobCardContent({
    super.key,
    required this.job,
    required this.jobId,
    this.distanceKm,
  });

  static String formatPay(int v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹$v';
  }

  @override
  Widget build(BuildContext context) {
    final title = job['title'] as String? ?? 'Untitled Role';
    final businessName = job['businessName'] as String? ?? '';
    final location = job['location'] as String? ?? '';
    final jobType = job['jobType'] as String? ?? '';
    final payMin = job['payMin'] as int? ?? 0;
    final payMax = job['payMax'] as int? ?? 0;
    final isUrgent = job['isUrgent'] == true;
    final requirements = List<String>.from(job['requirements'] ?? []);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.jobCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Accent top bar ──────────────────────────────────────────────────
          Container(height: 5, color: AppColors.accent),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Badges ────────────────────────────────────────────────
                  Row(
                    children: [
                      if (isUrgent) ...[
                        _Badge(
                          label: '🔥 Urgent',
                          color: AppColors.warning,
                          bg: AppColors.warningLight,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (jobType.isNotEmpty)
                        _Badge(
                          label: jobType,
                          color: AppColors.accent,
                          bg: AppColors.accentLight,
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Job Title ─────────────────────────────────────────────
                  Text(title, style: AppTextStyles.jobTitle),

                  if (businessName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('at $businessName',
                        style: AppTextStyles.jobCompany
                            .copyWith(color: AppColors.accent)),
                  ],

                  const SizedBox(height: 8),

                  // ── Location ──────────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: AppTextStyles.jobCompany,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distanceKm != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: AppRadius.smRadius,
                          ),
                          child: Text(
                            distanceKm! < 1
                                ? '<1 km'
                                : '${distanceKm!.round()} km',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentDark,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Pay ───────────────────────────────────────────────────
                  Text(
                    '${formatPay(payMin)} – ${formatPay(payMax)} / month',
                    style: AppTextStyles.salaryLabel,
                  ),

                  const Spacer(),

                  // ── Requirements ──────────────────────────────────────────
                  if (requirements.isNotEmpty) ...[
                    Container(
                      height: 0.5,
                      color: AppColors.border,
                    ),
                    const SizedBox(height: 14),
                    ...requirements.take(3).map(
                          (req) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    req,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],

                  const SizedBox(height: 10),

                  // ── Tap hint ──────────────────────────────────────────────
                  Center(
                    child: Text(
                      'Tap for full details',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textHint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Badge chip
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.smRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
