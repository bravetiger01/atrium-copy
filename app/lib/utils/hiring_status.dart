// lib/utils/hiring_status.dart
// Shared status constants, colours, labels, and icons
// used by both candidate (inbox) and employer (matches) screens.

import 'package:flutter/material.dart';

class HiringStatus {
  static const String matched = 'matched';
  static const String interviewScheduled = 'interview_scheduled';
  static const String interviewCompleted = 'interview_completed';
  static const String offerSent = 'offer_sent';
  static const String hired = 'hired';

  static const _pipeline = [
    matched,
    interviewScheduled,
    interviewCompleted,
    offerSent,
    hired,
  ];

  static List<String> get pipeline => _pipeline;

  static int indexOf(String status) =>
      _pipeline.indexOf(status).clamp(0, _pipeline.length - 1);

  // ── Labels ──────────────────────────────────────────────────────────────────
  static String label(String status) {
    switch (status) {
      case matched:
        return 'Matched';
      case interviewScheduled:
        return 'Interview Scheduled';
      case interviewCompleted:
        return 'Interview Completed';
      case offerSent:
        return 'Offer Sent';
      case hired:
        return 'Hired 🎉';
      default:
        return 'Matched';
    }
  }

  // ── Colors ───────────────────────────────────────────────────────────────────
  static Color color(String status) {
    switch (status) {
      case matched:
        return const Color(0xFF3B82F6); // blue
      case interviewScheduled:
        return const Color(0xFF8B5CF6); // purple
      case interviewCompleted:
        return const Color(0xFFF59E0B); // amber
      case offerSent:
        return const Color(0xFFF97316); // orange
      case hired:
        return const Color(0xFF22C55E); // green
      default:
        return const Color(0xFF3B82F6);
    }
  }

  static Color bgColor(String status) => color(status).withOpacity(0.12);

  // ── Icons ────────────────────────────────────────────────────────────────────
  static IconData icon(String status) {
    switch (status) {
      case matched:
        return Icons.favorite_rounded;
      case interviewScheduled:
        return Icons.event_rounded;
      case interviewCompleted:
        return Icons.event_available_rounded;
      case offerSent:
        return Icons.local_offer_rounded;
      case hired:
        return Icons.workspace_premium_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  // ── Status Pill Widget ───────────────────────────────────────────────────────
  static Widget pill(String status) {
    final c = color(status);
    final bg = bgColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon(status), size: 12, color: c),
          const SizedBox(width: 5),
          Text(
            label(status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pipeline Stepper Widget (employer view) ──────────────────────────────────
  static Widget stepper(String currentStatus) {
    final currentIdx = indexOf(currentStatus);
    return Row(
      children: List.generate(_pipeline.length * 2 - 1, (i) {
        if (i.isOdd) {
          // connector line
          final stepIdx = i ~/ 2;
          final filled = stepIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: filled
                  ? color(_pipeline[stepIdx])
                  : const Color(0xFFE2E8F0),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final step = _pipeline[stepIdx];
        final done = stepIdx <= currentIdx;
        final c = done ? color(step) : const Color(0xFFCBD5E1);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? c.withOpacity(0.15) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: c, width: done ? 2 : 1),
              ),
              child: Icon(
                done ? icon(step) : Icons.circle_outlined,
                size: 13,
                color: c,
              ),
            ),
          ],
        );
      }),
    );
  }
}
