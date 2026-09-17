import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/project_service.dart';
import '../../theme/app_typography_tokens.dart';
import '../../theme/light_mode_token.dart';
import 'candidate_project_upload_screen.dart';
import 'candidate_project_view_screen.dart';
import 'models/project_model.dart';
import 'project_search_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Projects Screen — empty state & populated feed (Screen 4)
// ─────────────────────────────────────────────────────────────────────────────

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  void _onCreateProject(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CandidateProjectUploadScreen(),
      ),
    );
  }

  void _onSearch(BuildContext context, List<ProjectModel> projects) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectSearchScreen(initialProjects: projects),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<ProjectModel>>(
      stream: ProjectService().streamCandidateProjects(uid),
      builder: (context, snapshot) {
        final projects = snapshot.data ?? [];

        if (projects.isEmpty) {
          // ── Screen 1: Empty state ──────────────────────────────────────────
          return Scaffold(
            backgroundColor: UtilityGrayColors.utilityGray50,
            body: SafeArea(
              child: Column(
                children: [
                  const _ProjectsAppBar(),
                  Expanded(
                    child: _EmptyStateBody(
                      onCreateProject: () => _onCreateProject(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ── Screen 4: Your Projects populated list ─────────────────────────
        return Scaffold(
          backgroundColor: UtilityGrayColors.utilityGray50,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _YourProjectsAppBar(
                      onSearchTap: () => _onSearch(context, projects),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 80),
                        itemCount: projects.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 24),
                        itemBuilder: (context, index) {
                          return _ProjectFeedCard(
                            project: projects[index],
                            allProjects: projects,
                            currentIndex: index,
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Floating "+ Add Project" button
                Positioned(
                  bottom: 16,
                  right: 24,
                  child: _AddProjectFloatingButton(
                    onTap: () => _onCreateProject(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _ProjectsAppBar extends StatelessWidget {
  const _ProjectsAppBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Projects',
          style: TextStyle(
            fontFamily: AppTypographyTokens.displayFontFamily,
            fontSize: AppTypographyTokens.textXl,
            fontWeight: AppTypographyTokens.semibold,
            color: TextColors.textPrimary900,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State Body
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyStateBody extends StatelessWidget {
  const _EmptyStateBody({required this.onCreateProject});
  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          // ── Illustration acting as an interactive button ─────────────────
          _InteractiveIllustration(onTap: onCreateProject),

          // Exact 20px gap between graphic and "No projects found"
          const SizedBox(height: 20),

          // ── Heading ──────────────────────────────────────────────────────
          const Text(
            'No projects found',
            style: TextStyle(
              fontFamily: AppTypographyTokens.displayFontFamily,
              fontSize: 20,
              fontWeight: AppTypographyTokens.semibold,
              color: TextColors.textPrimary900,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // ── Sub-copy: single line matching design ─────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Import existing projects that you have Worked on Previously.',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.bodyFontFamily,
                  fontSize: 13.5,
                  fontWeight: AppTypographyTokens.regular,
                  color: TextColors.textTertiary600,
                  letterSpacing: -0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── "Create Project" CTA button (intrinsic width, text only) ─────
          _CreateProjectButton(onTap: onCreateProject),

          const Spacer(flex: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interactive Illustration with exported upload-project glassy badge
//
// The whole illustration functions as a tap target with tactile feedback.
// ─────────────────────────────────────────────────────────────────────────────

class _InteractiveIllustration extends StatefulWidget {
  const _InteractiveIllustration({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_InteractiveIllustration> createState() =>
      _InteractiveIllustrationState();
}

class _InteractiveIllustrationState extends State<_InteractiveIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _animCtrl;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _animCtrl.reverse(),
        onTapUp: (_) {
          _animCtrl.forward();
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => _animCtrl.forward(),
        child: SizedBox(
          width: 220,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Base fan illustration of three cards
              Positioned(
                top: 0,
                child: Image.asset(
                  'assets/illustrations/project-upload.png',
                  width: 220,
                  height: 170,
                  fit: BoxFit.contain,
                ),
              ),

              // Exported glassy upload button in front of cards
              Positioned(
                bottom: 0,
                child: Image.asset(
                  'assets/illustrations/upload-project.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Create Project" CTA Button
//
// Matches reference: intrinsic width pill/rounded button, brand orange, text only.
// ─────────────────────────────────────────────────────────────────────────────

class _CreateProjectButton extends StatefulWidget {
  const _CreateProjectButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CreateProjectButton> createState() => _CreateProjectButtonState();
}

class _CreateProjectButtonState extends State<_CreateProjectButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _scaleCtrl.reverse(),
        onTapUp: (_) {
          _scaleCtrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _scaleCtrl.forward(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          decoration: BoxDecoration(
            color: BackgroundColors.bgBrandSolid,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE04F16).withOpacity(0.28),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Text(
            'Create Project',
            style: TextStyle(
              fontFamily: AppTypographyTokens.bodyFontFamily,
              fontSize: 14,
              fontWeight: AppTypographyTokens.semibold,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen 4: Your Projects App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _YourProjectsAppBar extends StatelessWidget {
  const _YourProjectsAppBar({required this.onSearchTap});
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Your Projects',
            style: TextStyle(
              fontFamily: AppTypographyTokens.displayFontFamily,
              fontSize: 22,
              fontWeight: AppTypographyTokens.semibold,
              color: TextColors.textPrimary900,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSearchTap,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Image.asset(
                'assets/icons/search.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                color: TextColors.textTertiary600,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.search_rounded,
                  size: 24,
                  color: TextColors.textTertiary600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen 4: Project Feed Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProjectFeedCard extends StatelessWidget {
  const _ProjectFeedCard({
    required this.project,
    this.allProjects,
    this.currentIndex,
  });

  final ProjectModel project;
  final List<ProjectModel>? allProjects;
  final int? currentIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CandidateProjectViewScreen(
              project: project,
              allProjects: allProjects,
              currentIndex: currentIndex,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover Image ────────────────────────────────────────────────────
        Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: UtilityGrayColors.utilityGray100,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: ShadowColors.shadowXs,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildCoverImage(),
          ),
        ),

        const SizedBox(height: 10),

        // ── Category Tag ("Design") ─────────────────────────────────────────
        Text(
          project.category,
          style: const TextStyle(
            fontFamily: AppTypographyTokens.bodyFontFamily,
            fontSize: 12,
            fontWeight: AppTypographyTokens.semibold,
            color: UtilityOrangeDarkColors.utilityOrangeDark600, // #E62E05
          ),
        ),

        const SizedBox(height: 4),

        // ── Title & Outward Arrow ──────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                project.title,
                style: const TextStyle(
                  fontFamily: AppTypographyTokens.bodyFontFamily,
                  fontSize: 16,
                  fontWeight: AppTypographyTokens.bold,
                  color: TextColors.textPrimary900,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_outward_rounded,
              size: 18,
              color: TextColors.textTertiary600,
            ),
          ],
        ),

        const SizedBox(height: 4),

        // ── Subtitle / Description ─────────────────────────────────────────
        Text(
          project.projectDescription.isNotEmpty
              ? project.projectDescription
              : project.companyDescription,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: AppTypographyTokens.bodyFontFamily,
            fontSize: 13,
            fontWeight: AppTypographyTokens.regular,
            color: TextColors.textTertiary600,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildCoverImage() {
    final url = project.thumbnailUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (_, __, ___) => _fallbackCover(),
        );
      } else if (File(url).existsSync()) {
        return Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackCover(),
        );
      }
    }
    return _fallbackCover();
  }

  Widget _fallbackCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0E5EC),
            Color(0xFF7A68FF),
            Color(0xFFE04F16),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.photo_library_rounded,
          size: 40,
          color: Colors.white70,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating "+ Add Project" Button
// ─────────────────────────────────────────────────────────────────────────────

class _AddProjectFloatingButton extends StatefulWidget {
  const _AddProjectFloatingButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AddProjectFloatingButton> createState() =>
      _AddProjectFloatingButtonState();
}

class _AddProjectFloatingButtonState extends State<_AddProjectFloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: BackgroundColors.bgBrandSolid,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE04F16).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Add Project',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.bodyFontFamily,
                  fontSize: 13.5,
                  fontWeight: AppTypographyTokens.semibold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


