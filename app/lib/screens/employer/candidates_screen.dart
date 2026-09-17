import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../candidate/chat_screen.dart';
import 'candidate_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Candidates Screen — employer sees who swiped right on their job postings
// ─────────────────────────────────────────────────────────────────────────────

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  List<_CandidateLead> _leads = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _processingIds = {}; // prevents double-tap

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 1. All right-swipes on this employer's jobs
      //    (single where → no composite index needed)
      final swipesSnap = await FirebaseFirestore.instance
          .collection('swipes')
          .where('employerId', isEqualTo: uid)
          .get();

      final rightSwipes =
          swipesSnap.docs
              .where((d) => d['direction'] == 'right')
              .where(
                (d) =>
                    (d.data() as Map<String, dynamic>)['employerPass'] != true,
              ) // hide passed candidates
              .toList()
            ..sort((a, b) {
              final aTs = a['swipedAt'] as Timestamp?;
              final bTs = b['swipedAt'] as Timestamp?;
              if (aTs == null || bTs == null) return 0;
              return bTs.compareTo(aTs); // newest first
            });

      if (rightSwipes.isEmpty) {
        if (mounted) setState(() => _leads = []);
        return;
      }

      // 2. Check which candidates are already matched (current snapshot)
      final matchesSnap = await FirebaseFirestore.instance
          .collection('matches')
          .where('employerId', isEqualTo: uid)
          .get();

      // Key = candidateId_jobId → matchId for opening chat
      final matchKeyToId = <String, String>{
        for (final d in matchesSnap.docs)
          '${d['candidateId'] as String}_${d['jobId'] as String}': d.id,
      };
      final matchedKeys = matchKeyToId.keys.toSet();

      // 3. Fetch each candidate's profile (parallel)
      final futures = rightSwipes.map((swipe) async {
        final candidateId = swipe['candidateId'] as String;
        final jobId = swipe['jobId'] as String;

        // Fetch candidate profile
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(candidateId)
            .get();

        // Fetch job title
        final jobDoc = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(jobId)
            .get();

        final userData = userDoc.data() ?? {};
        final profile = (userData['profile'] as Map<String, dynamic>?) ?? {};

        return _CandidateLead(
          swipeDocId: swipe.id,
          candidateId: candidateId,
          jobId: jobId,
          jobTitle: (jobDoc.data()?['title'] as String?) ?? 'Unknown Job',
          name:
              (userData['displayName'] as String?) ??
              (userData['name'] as String?) ??
              (userData['email'] as String?) ??
              'Candidate',
          email: (userData['email'] as String?) ?? '',
          skills: List<String>.from(profile['skills'] ?? []),
          availability: List<String>.from(profile['availability'] ?? []),
          payMin: profile['payMin'] as int? ?? 0,
          payMax: profile['payMax'] as int? ?? 0,
          openToNegotiation: profile['openToNegotiation'] == true,
          locationRadius: profile['locationRadius'] as int? ?? 0,
          bio: (profile['bio'] as String?) ?? '',
          resumeUrl: profile['resumeUrl'] as String?,
          swipedAt: swipe['swipedAt'] as Timestamp?,
          isAlreadyMatched: matchedKeys.contains('${candidateId}_$jobId'),
          matchId: matchKeyToId['${candidateId}_$jobId'],
        );
      });

      final leads = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _leads = leads;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _accept(_CandidateLead lead) async {
    if (_processingIds.contains(lead.swipeDocId)) return;
    setState(() => _processingIds.add(lead.swipeDocId));

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Deduplication: check if a match already exists for this candidate+job
      final existing = await FirebaseFirestore.instance
          .collection('matches')
          .where('employerId', isEqualTo: uid)
          .where('candidateId', isEqualTo: lead.candidateId)
          .where('jobId', isEqualTo: lead.jobId)
          .get();

      if (existing.docs.isNotEmpty) {
        // Already matched — just update local state to reflect this
        setState(() {
          final idx = _leads.indexWhere((l) => l.swipeDocId == lead.swipeDocId);
          if (idx != -1) {
            _leads[idx] = _leads[idx].copyWith(
              isAlreadyMatched: true,
              matchId: existing.docs.first.id,
            );
          }
        });
        return;
      }

      final docRef = await FirebaseFirestore.instance
          .collection('matches')
          .add({
            'candidateId': lead.candidateId,
            'employerId': uid,
            'jobId': lead.jobId,
            'jobTitle': lead.jobTitle,
            'candidateName': lead.name,
            'status': 'matched', // hiring pipeline starts here
            'createdAt': FieldValue.serverTimestamp(),
          });

      // After accept: update local matchId too
      setState(() {
        final idx = _leads.indexWhere((l) => l.swipeDocId == lead.swipeDocId);
        if (idx != -1) {
          _leads[idx] = _leads[idx].copyWith(
            isAlreadyMatched: true,
            matchId: docRef.id,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text("It's a match! You accepted ${lead.name}."),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(lead.swipeDocId));
    }
  }

  Future<void> _pass(_CandidateLead lead) async {
    if (_processingIds.contains(lead.swipeDocId)) return;
    setState(() => _processingIds.add(lead.swipeDocId));

    try {
      // Soft-hide — mark on swipe doc so it doesn't appear again on refresh
      await FirebaseFirestore.instance
          .collection('swipes')
          .doc(lead.swipeDocId)
          .update({'employerPass': true});

      setState(
        () => _leads.removeWhere((l) => l.swipeDocId == lead.swipeDocId),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(lead.swipeDocId));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Failed to load candidates',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_error!, style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_leads.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              Text(
                'No candidates yet',
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Candidates who swipe right on your job\npostings will appear here.',
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _leads.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final lead = _leads[i];
          final isProcessing = _processingIds.contains(lead.swipeDocId);

          return _CandidateCard(
            lead: lead,
            isProcessing: isProcessing,
            onAccept: () => _accept(lead),
            onPass: () => _pass(lead),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Candidate Card
// ─────────────────────────────────────────────────────────────────────────────

class _CandidateCard extends StatelessWidget {
  final _CandidateLead lead;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onPass;

  const _CandidateCard({
    required this.lead,
    required this.isProcessing,
    required this.onAccept,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?';

    String _formatPay(int v) {
      if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
      if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
      return '₹$v';
    }

    return Container(
      decoration: AppDecorations.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accentLight,
                  child: Text(
                    initial,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.accentDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.name, style: AppTextStyles.headlineSmall),
                      Text(lead.email, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CandidateDetailsScreen(candidateId: lead.candidateId),
                    ),
                  ),
                  child: const Text('Profile'),
                ),
                // Match badge
                if (lead.isAlreadyMatched)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: AppRadius.fullRadius,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 12,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Matched',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Applied for badge ──────────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.work_outline_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text('Applied for: ', style: AppTextStyles.bodySmall),
                Expanded(
                  child: Text(
                    lead.jobTitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Skills chips ───────────────────────────────────────────────
            if (lead.skills.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: lead.skills.take(5).map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: AppRadius.fullRadius,
                    ),
                    child: Text(
                      s,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accentDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // ── Pay & availability ─────────────────────────────────────────
            Row(
              children: [
                _InfoPill(
                  icon: Icons.currency_rupee_rounded,
                  label: lead.openToNegotiation
                      ? 'Open to negotiation'
                      : '${_formatPay(lead.payMin)} – ${_formatPay(lead.payMax)}',
                ),
                const SizedBox(width: 8),
                if (lead.availability.isNotEmpty)
                  _InfoPill(
                    icon: Icons.schedule_rounded,
                    label: lead.availability.first,
                  ),
              ],
            ),

            // ── Bio ────────────────────────────────────────────────────────
            if (lead.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                lead.bio,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Action row ─────────────────────────────────────────────────────
            if (lead.isAlreadyMatched)
              StreamBuilder<DocumentSnapshot>(
                stream: lead.matchId != null
                    ? FirebaseFirestore.instance
                          .collection('chats')
                          .doc(lead.matchId)
                          .snapshots()
                    : const Stream.empty(),
                builder: (context, chatSnap) {
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                  final chatData = chatSnap.data?.exists == true
                      ? chatSnap.data!.data() as Map<String, dynamic>
                      : null;
                  final lastMsg = chatData?['lastMessage'] as String? ?? '';
                  final lastTime = chatData?['lastTime'] as Timestamp?;
                  final unread = (chatData?['unreadCount_$uid'] as int?) ?? 0;

                  String _timeLabel(Timestamp? ts) {
                    if (ts == null) return '';
                    final dt = ts.toDate();
                    final now = DateTime.now();
                    final diff = now.difference(dt);
                    if (diff.inDays >= 1) return '${diff.inDays}d ago';
                    if (diff.inHours >= 1) return '${diff.inHours}h ago';
                    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
                    return 'Just now';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Matched row
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Matched — ${lead.jobTitle}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Last message preview
                      if (lastMsg.isNotEmpty) ...[
                        const SizedBox(height: 6),
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
                                _timeLabel(lastTime),
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
                      ],

                      if (lead.matchId != null) ...[
                        const SizedBox(height: 10),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final matchId = lead.matchId!;
                                  final candidateId = lead.candidateId;
                                  final uid =
                                      FirebaseAuth.instance.currentUser?.uid;
                                  if (uid == null) return;
                                  await FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(matchId)
                                      .set({
                                        'matchId': matchId,
                                        'jobId': lead.jobId,
                                        'jobTitle': lead.jobTitle,
                                        'members': [uid, candidateId],
                                        'candidateId': candidateId,
                                        'employerId': uid,
                                        'lastMessage': '',
                                        'lastTime':
                                            FieldValue.serverTimestamp(),
                                        'unreadCount_$uid': 0,
                                        'unreadCount_$candidateId': 0,
                                      }, SetOptions(merge: true));
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ChatScreen(),
                                        settings: RouteSettings(
                                          arguments: {
                                            'chatId': matchId,
                                            'otherUserId': candidateId,
                                            'otherUserName': lead.name,
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(
                                  lastMsg.isNotEmpty
                                      ? Icons.chat_bubble_rounded
                                      : Icons.chat_bubble_outline_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  lastMsg.isNotEmpty
                                      ? 'Continue Chat'
                                      : 'Message',
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
                    ],
                  );
                },
              )
            else if (isProcessing)
              const Center(
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                children: [
                  // Pass button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPass,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Pass'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Accept button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Accept'),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.smRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data model
// ─────────────────────────────────────────────────────────────────────────────

class _CandidateLead {
  final String swipeDocId;
  final String candidateId;
  final String jobId;
  final String jobTitle;
  final String name;
  final String email;
  final List<String> skills;
  final List<String> availability;
  final int payMin;
  final int payMax;
  final bool openToNegotiation;
  final int locationRadius;
  final String bio;
  final String? resumeUrl;
  final Timestamp? swipedAt;
  final bool isAlreadyMatched;

  final String? matchId; // Firestore match document ID = chatId

  const _CandidateLead({
    required this.swipeDocId,
    required this.candidateId,
    required this.jobId,
    required this.jobTitle,
    required this.name,
    required this.email,
    required this.skills,
    required this.availability,
    required this.payMin,
    required this.payMax,
    required this.openToNegotiation,
    required this.locationRadius,
    required this.bio,
    this.resumeUrl,
    required this.swipedAt,
    required this.isAlreadyMatched,
    this.matchId,
  });

  _CandidateLead copyWith({bool? isAlreadyMatched, String? matchId}) {
    return _CandidateLead(
      swipeDocId: swipeDocId,
      candidateId: candidateId,
      jobId: jobId,
      jobTitle: jobTitle,
      name: name,
      email: email,
      skills: skills,
      availability: availability,
      payMin: payMin,
      payMax: payMax,
      openToNegotiation: openToNegotiation,
      locationRadius: locationRadius,
      bio: bio,
      resumeUrl: resumeUrl,
      swipedAt: swipedAt,
      isAlreadyMatched: isAlreadyMatched ?? this.isAlreadyMatched,
      matchId: matchId ?? this.matchId,
    );
  }
}
