// lib/screens/notification_screen.dart
//
// Reads from notifications/{uid}/items (written by Cloud Functions).
// - Streams items ordered by createdAt desc
// - Shows unread dot on each item
// - Marks ALL as read when screen is opened
// - Marks a single item as read on tap
// - Shows appropriate icon/color per type: chat / match / interview

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when the screen opens
    _markAllRead();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('notifications')
      .doc(_uid)
      .collection('items');

  Future<void> _markAllRead() async {
    if (_uid.isEmpty) return;
    try {
      final unread = await _col
          .where('read', isEqualTo: false)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> _markOneRead(DocumentSnapshot doc) async {
    if ((doc.data() as Map<String, dynamic>)['read'] == true) return;
    await doc.reference.update({'read': true});
  }

  Future<void> _deleteOne(String docId) async {
    await _col.doc(docId).delete();
  }

  Future<void> _clearAll() async {
    final all = await _col.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in all.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: Text(
              'Clear all',
              style: TextStyle(color: AppColors.accent.withOpacity(0.9)),
            ),
          ),
        ],
      ),
      body: _uid.isEmpty
          ? const Center(child: Text('Not signed in'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // No orderBy — avoids needing a Firestore composite index.
              // We sort in Dart below.
              stream: _col.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Show the actual error so we can diagnose it
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: AppSpacing.pagePadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text('Could not load notifications',
                              style: AppTextStyles.headlineSmall),
                          const SizedBox(height: 8),
                          Text(
                            snap.error.toString(),
                            style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Sort newest-first in Dart
                final docs = [...(snap.data?.docs ?? [])]..sort((a, b) {
                    final aTs = a.data()['createdAt'] as Timestamp?;
                    final bTs = b.data()['createdAt'] as Timestamp?;
                    if (aTs == null || bTs == null) return 0;
                    return bTs.compareTo(aTs);
                  });

                if (docs.isEmpty) {
                  return _EmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();
                    return _NotifTile(
                      data: data,
                      onTap: () => _markOneRead(doc),
                      onDismiss: () => _deleteOne(doc.id),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Single notification tile
// ─────────────────────────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifTile({
    required this.data,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final type = data['type'] as String? ?? 'chat';
    final read = data['read'] as bool? ?? true;
    final ts = data['createdAt'] as Timestamp?;

    final (icon, color, bg) = _iconForType(type);

    String timeLabel() {
      if (ts == null) return '';
      final diff = DateTime.now().difference(ts.toDate());
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'Just now';
    }

    return Dismissible(
      key: Key(data.hashCode.toString() + title),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: AppRadius.mdRadius,
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 22),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: AppDecorations.card.copyWith(
            color: read ? AppColors.surface : AppColors.surfaceVariant,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: read
                                  ? FontWeight.normal
                                  : FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!read) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (ts != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        timeLabel(),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _iconForType(String type) {
    switch (type) {
      case 'match':
        return (Icons.favorite_rounded, AppColors.error, AppColors.errorLight);
      case 'interview':
        return (Icons.event_rounded, AppColors.success, AppColors.successLight);
      case 'chat':
      default:
        return (
          Icons.chat_bubble_rounded,
          AppColors.accent,
          AppColors.accentLight
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 40, color: AppColors.accent),
            ),
            const SizedBox(height: 24),
            Text('All caught up!', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'New messages, matches, and interview\nproposals will appear here.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
