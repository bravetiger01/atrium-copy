import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/location_utils.dart';
import '../../widgets/notification_bell.dart';
import '../login_screen.dart';
import 'company_profile_screen.dart';
import 'widgets/job_card_content.dart';
import 'widgets/swipe_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Job Swipe Feed — candidate's main discovery screen
// ─────────────────────────────────────────────────────────────────────────────

class JobScreen extends StatefulWidget {
  const JobScreen({super.key});

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  // ── Data state ─────────────────────────────────────────────────────────────
  List<QueryDocumentSnapshot> _jobs = [];
  bool _isLoading = true;
  String? _error;
  bool _noLocation = false;

  // ── Location state ──────────────────────────────────────────────────────────
  double? _candidateLat;
  double? _candidateLng;
  int _candidateRadius = 15;
  final Map<String, double> _distances = {};

  // Recreated on every swipe so Flutter always creates a FRESH SwipeCardState
  // for the next card (avoids stale _dragOffset / _isAnimating on reuse).
  GlobalKey<SwipeCardState> _topCardKey = GlobalKey<SwipeCardState>();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _noLocation = false;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 0. Load candidate's location data
      final userData = await AuthService().getUserData(uid);
      final profile = userData?['profile'] as Map<String, dynamic>?;
      _candidateLat = profile?['latitude'] as double?;
      _candidateLng = profile?['longitude'] as double?;
      _candidateRadius = (profile?['locationRadius'] as int?) ?? 15;

      // 0b. If no stored location, try GPS at runtime
      if (_candidateLat == null || _candidateLng == null) {
        try {
          final enabled = await Geolocator.isLocationServiceEnabled();
          if (enabled) {
            var perm = await Geolocator.checkPermission();
            if (perm == LocationPermission.denied) {
              perm = await Geolocator.requestPermission();
            }
            if (perm != LocationPermission.denied &&
                perm != LocationPermission.deniedForever) {
              final pos = await Geolocator.getCurrentPosition();
              _candidateLat = pos.latitude;
              _candidateLng = pos.longitude;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({
                'profile.latitude': pos.latitude,
                'profile.longitude': pos.longitude,
              });
            }
          }
        } catch (_) {}
      }

      if (_candidateLat == null || _candidateLng == null) {
        if (mounted) {
          setState(() { _noLocation = true; _isLoading = false; });
        }
        return;
      }

      // 1. Fetch jobs this candidate already swiped on
      final swipesSnap = await FirebaseFirestore.instance
          .collection('swipes')
          .where('candidateId', isEqualTo: uid)
          .get();

      final swipedIds =
          swipesSnap.docs.map((d) => d['jobId'] as String).toSet();

      // 2. Fetch all active jobs
      final jobsSnap = await FirebaseFirestore.instance
          .collection('jobs')
          .where('isActive', isEqualTo: true)
          .get();

      // 3. Filter: remove already-swiped and own employer postings
      var filtered = jobsSnap.docs
          .where((d) => !swipedIds.contains(d.id))
          .where((d) => (d.data()['employerId'] as String?) != uid)
          .toList();

      // 4. Filter by distance if candidate has location data
      _distances.clear();
      if (_candidateLat != null && _candidateLng != null) {
        filtered = filtered.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final jobLat = data['latitude'] as double?;
          final jobLng = data['longitude'] as double?;
          if (jobLat == null || jobLng == null) return false;
          final dist = haversineDistance(
            _candidateLat!, _candidateLng!, jobLat, jobLng,
          );
          _distances[doc.id] = dist;
          return dist <= _candidateRadius;
        }).toList();
      }

      if (mounted) {
        setState(() {
          _jobs = filtered;
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

  // ── Swipe actions ──────────────────────────────────────────────────────────

  Future<void> _recordSwipe(
    String jobId,
    String employerId,
    String direction,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Swipe doc ID = uid_jobId (unique, idempotent)
    await FirebaseFirestore.instance
        .collection('swipes')
        .doc('${uid}_$jobId')
        .set({
      'candidateId': uid,
      'jobId': jobId,
      'employerId': employerId,
      'direction': direction,
      'swipedAt': FieldValue.serverTimestamp(),
    });
  }

  void _onSwipeRight(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _recordSwipe(doc.id, data['employerId'] ?? '', 'right');
    setState(() {
      _jobs.removeAt(0);
      _topCardKey = GlobalKey<SwipeCardState>(); // fresh state for next card
    });

    // Brief "Interested!" feedback
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('You expressed interest!'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
    }
  }

  void _onSwipeLeft(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _recordSwipe(doc.id, data['employerId'] ?? '', 'left');
    setState(() {
      _jobs.removeAt(0);
      _topCardKey = GlobalKey<SwipeCardState>(); // fresh state for next card
    });
  }

  // ── Button-triggered swipes ────────────────────────────────────────────────

  void _buttonSwipeRight() {
    _topCardKey.currentState?.triggerSwipeRight();
  }

  void _buttonSwipeLeft() {
    _topCardKey.currentState?.triggerSwipeLeft();
  }

  // ── Job detail bottom sheet ────────────────────────────────────────────────

  void _showDetail(Map<String, dynamic> job, String jobId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JobDetailSheet(
        job: job,
        jobId: jobId,
        onInterested: () {
          Navigator.pop(context);
          // Slight delay so the sheet closes before card flies off
          Future.delayed(const Duration(milliseconds: 150),
              () => _buttonSwipeRight());
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SwipeHire'),
        centerTitle: false,
        actions: [
          const NotificationBell(),
          IconButton(
            onPressed: _loadFeed,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _LoadingState();
    if (_error != null) return _ErrorState(error: _error!, onRetry: _loadFeed);
    if (_noLocation) return _NoLocationState(onRetry: _loadFeed);
    if (_jobs.isEmpty) return _EmptyState(onRefresh: _loadFeed);

    return Column(
      children: [
        // ── Counter ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Text(
                '${_jobs.length} jobs near you',
                style: AppTextStyles.labelMedium,
              ),
              const Spacer(),
              Text(
                'Swipe right to apply',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        ),

        // ── Card stack ───────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _CardStack(
              jobs: _jobs,
              distances: _distances,
              topCardKey: _topCardKey,
              onSwipeRight: _onSwipeRight,
              onSwipeLeft: _onSwipeLeft,
              onTap: (job, jobId) => _showDetail(job, jobId),
            ),
          ),
        ),

        // ── Action buttons ───────────────────────────────────────────────────
        _ActionButtons(
          onPass: _buttonSwipeLeft,
          onInterested: _buttonSwipeRight,
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Card Stack — renders top 3 cards with depth effect
// ─────────────────────────────────────────────────────────────────────────────

class _CardStack extends StatelessWidget {
  final List<QueryDocumentSnapshot> jobs;
  final Map<String, double> distances;
  final GlobalKey<SwipeCardState> topCardKey;
  final void Function(QueryDocumentSnapshot) onSwipeRight;
  final void Function(QueryDocumentSnapshot) onSwipeLeft;
  final void Function(Map<String, dynamic>, String) onTap;

  const _CardStack({
    required this.jobs,
    required this.distances,
    required this.topCardKey,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // ── 3rd card (back) ──────────────────────────────────────────────────
        if (jobs.length > 2)
          Positioned.fill(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, 16),
                child: Transform.scale(
                  scale: 0.92,
                  child: JobCardContent(
                    job: jobs[2].data() as Map<String, dynamic>,
                    jobId: jobs[2].id,
                    distanceKm: distances[jobs[2].id],
                  ),
                ),
              ),
            ),
          ),

        // ── 2nd card (middle) ────────────────────────────────────────────────
        if (jobs.length > 1)
          Positioned.fill(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, 8),
                child: Transform.scale(
                  scale: 0.96,
                  child: JobCardContent(
                    job: jobs[1].data() as Map<String, dynamic>,
                    jobId: jobs[1].id,
                    distanceKm: distances[jobs[1].id],
                  ),
                ),
              ),
            ),
          ),

        // ── Top card (interactive) ───────────────────────────────────────────
        Positioned.fill(
          child: SwipeCard(
            key: topCardKey,
            onSwipeRight: () => onSwipeRight(jobs[0]),
            onSwipeLeft: () => onSwipeLeft(jobs[0]),
            onTap: () {
              final data = jobs[0].data() as Map<String, dynamic>;
              onTap(data, jobs[0].id);
            },
            child: JobCardContent(
              job: jobs[0].data() as Map<String, dynamic>,
              jobId: jobs[0].id,
              distanceKm: distances[jobs[0].id],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action Buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onPass;
  final VoidCallback onInterested;

  const _ActionButtons({required this.onPass, required this.onInterested});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 16, 48, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ── Pass button ────────────────────────────────────────────────────
          GestureDetector(
            onTap: onPass,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.swipeLeft, width: 2),
                boxShadow: AppShadows.cardShadow,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.swipeLeft,
                size: 30,
              ),
            ),
          ),

          // ── Interested button ──────────────────────────────────────────────
          GestureDetector(
            onTap: onInterested,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: AppShadows.buttonShadow,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Job Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _JobDetailSheet extends StatelessWidget {
  final Map<String, dynamic> job;
  final String jobId;
  final VoidCallback onInterested;

  const _JobDetailSheet({
    required this.job,
    required this.jobId,
    required this.onInterested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = job['title'] as String? ?? '';
    final location = job['location'] as String? ?? '';
    final jobType = job['jobType'] as String? ?? '';
    final payMin = job['payMin'] as int? ?? 0;
    final payMax = job['payMax'] as int? ?? 0;
    final isUrgent = job['isUrgent'] == true;
    final requirements = List<String>.from(job['requirements'] ?? []);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate300,
                borderRadius: AppRadius.fullRadius,
              ),
            ),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  // ── Title + badges ──────────────────────────────────────────
                  Row(
                    children: [
                      if (isUrgent) ...[
                        _SheetBadge(
                          label: '🔥 Urgent',
                          color: AppColors.warning,
                          bg: AppColors.warningLight,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (jobType.isNotEmpty)
                        _SheetBadge(
                          label: jobType,
                          color: AppColors.accent,
                          bg: AppColors.accentLight,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(title, style: AppTextStyles.jobTitle),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(location, style: AppTextStyles.jobCompany),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Pay ─────────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: AppRadius.lgRadius,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.currency_rupee_rounded,
                            color: AppColors.accentDark, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${JobCardContent.formatPay(payMin)} – '
                          '${JobCardContent.formatPay(payMax)} / month',
                          style: AppTextStyles.salaryLabel
                              .copyWith(color: AppColors.accentDark),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Requirements ─────────────────────────────────────────────
                  if (requirements.isNotEmpty) ...[
                    Text('What they need',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 14),
                    ...requirements.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.successLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  size: 12, color: AppColors.success),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(r, style: AppTextStyles.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── Company ───────────────────────────────────────────────────
                  const Divider(height: 32),
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (job['businessName'] as String? ?? 'C')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.accentDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job['businessName'] as String? ?? 'Company',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600)),
                            if (job['employerName'] != null)
                              Text(job['employerName'] as String,
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: AppColors.textHint)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CompanyProfileScreen(
                                employerId:
                                    job['employerId'] as String,
                              ),
                            ),
                          );
                        },
                        child: const Text('View'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── CTA ──────────────────────────────────────────────────────
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: onInterested,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text("I'm Interested →"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Maybe Later'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _SheetBadge(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smRadius),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  State Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Finding jobs near you…',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 64, color: AppColors.slate300),
            const SizedBox(height: 20),
            Text('Something went wrong',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              error,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoLocationState extends StatelessWidget {
  final VoidCallback onRetry;

  const _NoLocationState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_rounded,
                  size: 40, color: AppColors.warning),
            ),
            const SizedBox(height: 24),
            Text('Set Your Location',
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Enable GPS or select your city in Profile\nto see jobs near you.',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.gps_fixed_rounded),
                label: const Text('Retry GPS'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Or go to Profile → Edit → select your city',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text("You're all caught up!",
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              "You've seen all available jobs in your area.\nCheck back later for new postings.",
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 180,
              child: OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}