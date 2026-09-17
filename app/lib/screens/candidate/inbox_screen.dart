import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/hiring_status.dart';
import '../../widgets/notification_bell.dart';
import 'chat_screen.dart';
import 'company_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Inbox / Matches Screen — candidate sees jobs they matched with
//  Uses a persistent StreamSubscription so updates arrive even when the tab
//  is not active (avoiding the StatelessWidget + inline stream stale-uid risk).
// ─────────────────────────────────────────────────────────────────────────────

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<QueryDocumentSnapshot> _matches = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<QuerySnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    _sub = FirebaseFirestore.instance
        .collection('matches')
        .where('candidateId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snap) {
        // Sort in Dart by createdAt (newest first)
        final docs = [...snap.docs]
          ..sort((a, b) {
            final aTs =
                (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTs =
                (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTs == null || bTs == null) return 0;
            return bTs.compareTo(aTs);
          });

        if (mounted) {
          setState(() {
            _matches = docs;
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Matches'),
        actions: [
          const NotificationBell(),
          if (_matches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: AppRadius.fullRadius,
                  ),
                  child: Text(
                    '${_matches.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Could not load matches',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(_error!, style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _sub?.cancel();
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _subscribe();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final data = _matches[i].data() as Map<String, dynamic>;
        return _MatchCard(
          matchId: _matches[i].id,
          data: data,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Match Card
// ─────────────────────────────────────────────────────────────────────────────

class _MatchCard extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> data;

  const _MatchCard({required this.matchId, required this.data});

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  Future<void> _openChat(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final employerId = widget.data['employerId'] as String? ?? '';
    if (employerId.isEmpty) return;

    // matchId IS the chatId — one thread per match (per job)
    final chatId = widget.matchId;

    // Look up employer name
    String employerName = 'Employer';
    try {
      final employerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(employerId)
          .get();
      if (employerDoc.exists) {
        final d = employerDoc.data() as Map<String, dynamic>;
        employerName = d['displayName']?.toString() ??
            d['name']?.toString() ??
            d['email']?.toString() ??
            'Employer';
      }
    } catch (_) {}

    // Ensure chat document exists (idempotent set)
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'matchId': widget.matchId,
        'jobId': widget.data['jobId'] ?? '',
        'jobTitle': widget.data['jobTitle'] ?? '',
        'members': [uid, employerId],
        'candidateId': uid,
        'employerId': employerId,
        'lastMessage': '',
        'lastTime': FieldValue.serverTimestamp(),
        'unreadCount_$uid': 0,
        'unreadCount_$employerId': 0,
      }, SetOptions(merge: true));
    } catch (_) {}

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatScreen(),
          settings: RouteSettings(arguments: {
            'chatId': chatId,
            'otherUserId': employerId,
            'otherUserName': employerName,
          }),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobTitle = widget.data['jobTitle'] as String? ?? 'Job';
    final createdAt = widget.data['createdAt'] as Timestamp?;
    final status = widget.data['status'] as String? ?? HiringStatus.matched;

    String timeAgo(Timestamp? ts) {
      if (ts == null) return '';
      final diff = DateTime.now().difference(ts.toDate());
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'Just now';
    }

    return Container(
      decoration: AppDecorations.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "It's a Match! 🎉",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        jobTitle,
                        style: AppTextStyles.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final employerId =
                        widget.data['employerId'] as String? ?? '';
                    if (employerId.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CompanyProfileScreen(employerId: employerId),
                      ),
                    );
                  },
                  child: const Text('Company'),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Status pill (read-only for candidate) ─────────────────────────
            Row(
              children: [
                HiringStatus.pill(status),
                const Spacer(),
                Text(
                  timeAgo(createdAt),
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textHint),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.smRadius,
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The employer has accepted your application for this role.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── CTA — live chat state ─────────────────────────────────────────
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.matchId)
                  .snapshots(),
              builder: (context, snap) {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final chatData =
                    snap.data?.exists == true
                        ? snap.data!.data() as Map<String, dynamic>
                        : null;
                final lastMsg =
                    chatData?['lastMessage'] as String? ?? '';
                final hasChat = lastMsg.isNotEmpty;
                final unread =
                    (chatData?['unreadCount_$uid'] as int?) ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasChat) ...[
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_rounded,
                              size: 14,
                              color: unread > 0
                                  ? AppColors.accent
                                  : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              lastMsg,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: unread > 0
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: unread > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => _openChat(context),
                            icon: Icon(
                              hasChat
                                  ? Icons.chat_bubble_rounded
                                  : Icons.chat_bubble_outline_rounded,
                              size: 18,
                            ),
                            label: Text(
                                hasChat ? 'Continue Chat' : 'Start Chat →'),
                          ),
                        ),
                        if (unread > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text('No matches yet',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Keep swiping! When an employer\naccepts your application, it shows up here.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}