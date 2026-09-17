import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/notification_bell.dart';
import '../login_screen.dart';
import 'candidates_screen.dart';
import 'employer_profile_screen.dart';
import 'matched_candidates_screen.dart';
import 'post_job_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Employer Home — shell with 3 tabs via IndexedStack
//  Tab 0: Dashboard   Tab 1: Candidates   Tab 2: Profile
// ─────────────────────────────────────────────────────────────────────────────

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'Dashboard',
    'Candidates',
    'Matches',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: false,
        actions: [
          const NotificationBell(),
          IconButton(
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      // ── FAB (only on dashboard tab) ───────────────────────────────────────
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostJobScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Post a Job'),
            )
          : null,
      // ── Bottom Navigation ─────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            // Candidates tab — shows live badge count
            NavigationDestination(
              icon: uid == null
                  ? const Icon(Icons.people_outline_rounded)
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('swipes')
                          .where('employerId', isEqualTo: uid)
                          .snapshots(),
                      builder: (_, snap) {
                        final count = (snap.data?.docs ?? [])
                            .where((d) {
                              final data = d.data() as Map<String, dynamic>;
                              return data['direction'] == 'right' &&
                                  data['employerPass'] != true;
                            })
                            .length;
                        return count > 0
                            ? Badge(
                                label: Text('$count'),
                                child: const Icon(
                                    Icons.people_outline_rounded),
                              )
                            : const Icon(Icons.people_outline_rounded);
                      },
                    ),
              selectedIcon: const Icon(Icons.people_rounded),
              label: 'Candidates',
            ),
            // Matches tab — shows live unread message badge
            NavigationDestination(
              icon: uid == null
                  ? const Icon(Icons.favorite_border_rounded)
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .where('employerId', isEqualTo: uid)
                          .snapshots(),
                      builder: (_, snap) {
                        int totalUnread = 0;
                        for (final d in snap.data?.docs ?? []) {
                          final chatData =
                              d.data() as Map<String, dynamic>;
                          totalUnread +=
                              (chatData['unreadCount_$uid'] as int?) ?? 0;
                        }
                        return totalUnread > 0
                            ? Badge(
                                label: Text(
                                    totalUnread > 9 ? '9+' : '$totalUnread'),
                                child:
                                    const Icon(Icons.favorite_border_rounded),
                              )
                            : const Icon(Icons.favorite_border_rounded);
                      },
                    ),
              selectedIcon: const Icon(Icons.favorite_rounded),
              label: 'Matches',
            ),
            const NavigationDestination(
              icon: Icon(Icons.business_outlined),
              selectedIcon: Icon(Icons.business_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
      // ── Body — IndexedStack preserves state across tabs ───────────────────
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(uid: uid),
          const CandidatesScreen(),
          const MatchedCandidatesScreen(),
          const EmployerProfileScreen(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Dashboard Tab (index 0)
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final String? uid;

  const _DashboardTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Greeting ───────────────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEDE9FE),
                child: Text(
                  (user?.displayName ?? user?.email ?? 'E')[0]
                      .toUpperCase(),
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: const Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${user?.displayName ?? 'Employer'} 👋',
                      style: theme.textTheme.headlineMedium,
                    ),
                    Text(
                      'Manage your job postings',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Stats row — all live ───────────────────────────────────────────
          Text('Overview', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 14),

          if (uid != null)
            _LiveStatsRow(uid: uid!),

          const SizedBox(height: 28),

          // ── Job Listings ───────────────────────────────────────────────────
          Text('Your Job Postings',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 14),

          if (uid != null)
            _JobListings(uid: uid!),

          const SizedBox(height: 100), // FAB clearance
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Live Stats Row (3 StreamBuilders merged)
// ─────────────────────────────────────────────────────────────────────────────

class _LiveStatsRow extends StatelessWidget {
  final String uid;

  const _LiveStatsRow({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Active jobs
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('employerId', isEqualTo: uid)
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (_, snap) => _StatCard(
              label: 'Active Jobs',
              value: '${snap.data?.docs.length ?? 0}',
              icon: Icons.work_outline_rounded,
              color: AppColors.accent,
              bg: AppColors.accentLight,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Total matches
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matches')
                .where('employerId', isEqualTo: uid)
                .snapshots(),
            builder: (_, snap) => _StatCard(
              label: 'Matches',
              value: '${snap.data?.docs.length ?? 0}',
              icon: Icons.favorite_rounded,
              color: AppColors.error,
              bg: AppColors.errorLight,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Interested (right-swipes)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('swipes')
                .where('employerId', isEqualTo: uid)
                .snapshots(),
            builder: (_, snap) {
              final count = (snap.data?.docs ?? [])
                  .where((d) =>
                      d['direction'] == 'right' &&
                      (d.data() as Map<String, dynamic>)['employerPass'] != true)
                  .length;
              return _StatCard(
                label: 'Interested',
                value: '$count',
                icon: Icons.thumb_up_outlined,
                color: AppColors.success,
                bg: AppColors.successLight,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Job Listings (StreamBuilder, sorted in Dart)
// ─────────────────────────────────────────────────────────────────────────────

class _JobListings extends StatelessWidget {
  final String uid;

  const _JobListings({required this.uid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('employerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error)),
          );
        }

        // Sort in Dart (no composite index needed)
        final docs = [...(snapshot.data?.docs ?? [])]
          ..sort((a, b) {
            final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTs == null || bTs == null) return 0;
            return bTs.compareTo(aTs);
          });

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: AppDecorations.card,
            child: Column(
              children: [
                const Icon(Icons.post_add_rounded,
                    size: 48, color: AppColors.slate300),
                const SizedBox(height: 16),
                Text('No job postings yet',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(
                  'Tap "Post a Job" to create your first\njob card.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _JobCard(data: data, docId: doc.id, uid: uid),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Job Card (with live interested count)
// ─────────────────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String uid;

  const _JobCard(
      {required this.data, required this.docId, required this.uid});

  @override
  Widget build(BuildContext context) {
    final isUrgent = data['isUrgent'] == true;
    final isActive = data['isActive'] == true;
    final payMin = data['payMin'] as int? ?? 0;
    final payMax = data['payMax'] as int? ?? 0;
    final requirements = List<String>.from(data['requirements'] ?? []);

    String fmt(int v) {
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
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['title'] ?? '',
                    style: AppTextStyles.jobTitle,
                  ),
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: const Text('🔥 Urgent',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                _MetaChip(
                    icon: Icons.location_on_outlined,
                    label: data['location'] ?? ''),
                const SizedBox(width: 8),
                _MetaChip(
                    icon: Icons.work_outline_rounded,
                    label: data['jobType'] ?? ''),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              '${fmt(payMin)} – ${fmt(payMax)} / month',
              style: AppTextStyles.salaryLabel,
            ),

            if (requirements.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              ...requirements.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(r,
                              style: AppTextStyles.bodySmall)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Status + interested count
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.successLight
                        : AppColors.surfaceVariant,
                    borderRadius: AppRadius.fullRadius,
                  ),
                  child: Text(
                    isActive ? '● Active' : '● Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Live interested count for this job
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('swipes')
                      .where('jobId', isEqualTo: docId)
                      .where('direction', isEqualTo: 'right')
                      .snapshots(),
                  builder: (_, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: AppRadius.fullRadius,
                      ),
                      child: Text(
                        '$count interested',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentDark,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stat Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.displayMedium.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
