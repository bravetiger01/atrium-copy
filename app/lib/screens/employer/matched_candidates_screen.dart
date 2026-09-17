import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/hiring_status.dart';
import '../candidate/chat_screen.dart';
import 'candidate_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Employer — Matched Candidates (Matches tab)
//  Each match card streams chats/{matchId} to show:
//    • last message preview (bold when unread)
//    • time of last message
//    • unread count badge on the chat button
// ─────────────────────────────────────────────────────────────────────────────

class MatchedCandidatesScreen extends StatefulWidget {
  const MatchedCandidatesScreen({super.key});

  @override
  State<MatchedCandidatesScreen> createState() =>
      _MatchedCandidatesScreenState();
}

class _MatchedCandidatesScreenState extends State<MatchedCandidatesScreen> {
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
        .where('employerId', isEqualTo: uid)
        .snapshots()
        .listen(
          (snap) {
            final docs = [...snap.docs]
              ..sort((a, b) {
                final aTs =
                    (a.data() as Map<String, dynamic>)['createdAt']
                        as Timestamp?;
                final bTs =
                    (b.data() as Map<String, dynamic>)['createdAt']
                        as Timestamp?;
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
        title: const Text('Matched Candidates'),
        actions: [
          if (_matches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: AppRadius.fullRadius,
                  ),
                  child: Text(
                    '${_matches.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
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
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text('Could not load matches', style: AppTextStyles.headlineSmall),
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
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No matches yet',
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'When you accept a candidate,\nthey show up here.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final data = _matches[i].data() as Map<String, dynamic>;
        return _EmployerMatchCard(matchId: _matches[i].id, data: data);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Match card — streams chats/{matchId} for live unread indicator
// ─────────────────────────────────────────────────────────────────────────────

class _EmployerMatchCard extends StatelessWidget {
  final String matchId;
  final Map<String, dynamic> data;

  const _EmployerMatchCard({required this.matchId, required this.data});

  Future<void> _openChat(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final candidateId = data['candidateId'] as String? ?? '';
    if (candidateId.isEmpty) return;

    final chatId = matchId;
    final candidateName =
        data['candidateName'] as String? ?? data['name'] ?? 'Candidate';

    try {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'matchId': matchId,
        'jobId': data['jobId'] ?? '',
        'jobTitle': data['jobTitle'] ?? '',
        'members': [uid, candidateId],
        'candidateId': candidateId,
        'employerId': uid,
        'lastMessage': '',
        'lastTime': FieldValue.serverTimestamp(),
        'unreadCount_$uid': 0,
        'unreadCount_$candidateId': 0,
      }, SetOptions(merge: true));
    } catch (_) {}

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatScreen(),
          settings: RouteSettings(
            arguments: {
              'chatId': chatId,
              'otherUserId': candidateId,
              'otherUserName': candidateName,
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidateName = data['candidateName'] as String? ?? 'Candidate';
    final jobTitle = data['jobTitle'] as String? ?? 'Job';
    final createdAt = data['createdAt'] as Timestamp?;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final status = data['status'] as String? ?? HiringStatus.matched;

    String timeAgo(Timestamp? ts) {
      if (ts == null) return '';
      final diff = DateTime.now().difference(ts.toDate());
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'Just now';
    }

    String timeLabel(Timestamp? ts) {
      if (ts == null) return '';
      final dt = ts.toDate();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'Just now';
    }

    return GestureDetector(
      onLongPress: () => _showUpdateStatusSheet(context, status),
      child: Container(
        decoration: AppDecorations.card,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CandidateDetailsScreen(
                          candidateId: data['candidateId'] as String? ?? '',
                        ),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.successLight,
                      child: Text(
                        candidateName.isNotEmpty
                            ? candidateName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.success,
                        ),
                      ),
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
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          candidateName,
                          style: AppTextStyles.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CandidateDetailsScreen(
                          candidateId: data['candidateId'] as String? ?? '',
                        ),
                      ),
                    ),
                    child: const Text('Profile'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Status row ───────────────────────────────────────────────────────
              Row(
                children: [
                  HiringStatus.pill(status),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showUpdateStatusSheet(context, status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Update',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Pipeline stepper ────────────────────────────────────────────────────
              HiringStatus.stepper(status),

              const SizedBox(height: 14),

              // ── Applied for ───────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.work_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Applied for: $jobTitle',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Live chat CTA ─────────────────────────────────────────────────
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(matchId)
                    .snapshots(),
                builder: (context, snap) {
                  final chatData = snap.data?.exists == true
                      ? snap.data!.data() as Map<String, dynamic>
                      : null;
                  final lastMsg = chatData?['lastMessage'] as String? ?? '';
                  final lastTime = chatData?['lastTime'] as Timestamp?;
                  final unread = (chatData?['unreadCount_$uid'] as int?) ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Last message preview
                      if (lastMsg.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_rounded,
                              size: 13,
                              color: unread > 0
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
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
                            if (lastTime != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                timeLabel(lastTime),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: unread > 0
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (unread > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
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

                      // Chat button with badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () => _openChat(context),
                              icon: Icon(
                                lastMsg.isNotEmpty
                                    ? Icons.chat_bubble_rounded
                                    : Icons.chat_bubble_outline_rounded,
                                size: 18,
                              ),
                              label: Text(
                                lastMsg.isNotEmpty
                                    ? 'Continue Chat'
                                    : 'Start Chat →',
                              ),
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
      ),
    );
  }

  void _showUpdateStatusSheet(BuildContext context, String currentStatus) {
    final currentIdx = HiringStatus.indexOf(currentStatus);
    // Only allow statuses the employer can manually set (interview_completed onwards)
    final employerStatuses = [
      HiringStatus.interviewCompleted,
      HiringStatus.offerSent,
      HiringStatus.hired,
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Update Hiring Status', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Current: ${HiringStatus.label(currentStatus)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...employerStatuses.map((s) {
                final sIdx = HiringStatus.indexOf(s);
                final isCurrent = s == currentStatus;
                final isAlreadyPast = sIdx < currentIdx;
                final disabled = isAlreadyPast;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? HiringStatus.bgColor(s)
                          : disabled
                          ? AppColors.surfaceVariant
                          : HiringStatus.bgColor(s).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      HiringStatus.icon(s),
                      color: isCurrent
                          ? HiringStatus.color(s)
                          : disabled
                          ? AppColors.textHint
                          : HiringStatus.color(s).withOpacity(0.6),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    HiringStatus.label(s),
                    style: TextStyle(
                      fontWeight: isCurrent
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: disabled
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 20,
                        )
                      : null,
                  onTap: disabled || isCurrent
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await FirebaseFirestore.instance
                              .collection('matches')
                              .doc(matchId)
                              .update({'status': s});
                        },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
