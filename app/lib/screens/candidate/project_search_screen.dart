import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/project_service.dart';
import '../../theme/app_typography_tokens.dart';
import '../../theme/light_mode_token.dart';
import 'candidate_project_view_screen.dart';
import 'models/project_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Project Search Screen (Screen 2 & Screen 3 from Figma)
//   • Item height: 124 (380x124)
//   • Gap between each item: 8 units
// ─────────────────────────────────────────────────────────────────────────────

class ProjectSearchScreen extends StatefulWidget {
  const ProjectSearchScreen({
    super.key,
    this.initialProjects,
  });

  final List<ProjectModel>? initialProjects;

  @override
  State<ProjectSearchScreen> createState() => _ProjectSearchScreenState();
}

class _ProjectSearchScreenState extends State<ProjectSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _searchController.clear();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<ProjectModel> _filterProjects(List<ProjectModel> allProjects) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      // When query is empty, show all available projects
      return allProjects;
    }

    return allProjects.where((p) {
      final titleMatch = p.title.toLowerCase().contains(query);
      final descMatch = p.projectDescription.toLowerCase().contains(query);
      final companyMatch = p.companyDescription.toLowerCase().contains(query);
      final categoryMatch = p.category.toLowerCase().contains(query);
      final clientMatch = (p.client ?? '').toLowerCase().contains(query);
      return titleMatch || descMatch || companyMatch || categoryMatch || clientMatch;
    }).toList();
  }

  void _onViewProject(
    ProjectModel project,
    List<ProjectModel> allProjects,
    int index,
  ) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CandidateProjectViewScreen(
          project: project,
          allProjects: allProjects,
          currentIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: UtilityGrayColors.utilityGray50,
      body: SafeArea(
        child: StreamBuilder<List<ProjectModel>>(
          stream: ProjectService().streamCandidateProjects(uid),
          initialData: widget.initialProjects,
          builder: (context, snapshot) {
            final allProjects = snapshot.data ?? [];
            final filtered = _filterProjects(allProjects);
            final hasQuery = _searchController.text.trim().isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header with Back Button & Title ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 24,
                              color: TextColors.textTertiary600,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontFamily: AppTypographyTokens.bodyFontFamily,
                                fontSize: 14,
                                fontWeight: AppTypographyTokens.medium,
                                color: TextColors.textTertiary600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Title
                      const Text(
                        'Your Projects',
                        style: TextStyle(
                          fontFamily: AppTypographyTokens.displayFontFamily,
                          fontSize: 22,
                          fontWeight: AppTypographyTokens.semibold,
                          color: TextColors.textPrimary900,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Search Input Field ──────────────────────────────────
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: BackgroundColors.bgPrimary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: BorderColors.borderSecondary,
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: ShadowColors.shadowXs,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/search.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                              color: TextColors.textTertiary600,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: TextColors.textTertiary600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                autofocus: true,
                                textInputAction: TextInputAction.search,
                                cursorColor: TextColors.textPrimary900,
                                style: const TextStyle(
                                  fontFamily: AppTypographyTokens.bodyFontFamily,
                                  fontSize: 14,
                                  color: TextColors.textPrimary900,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'UX Review',
                                  hintStyle: TextStyle(
                                    fontFamily: AppTypographyTokens.bodyFontFamily,
                                    fontSize: 14,
                                    color: TextColors.textQuaternary500,
                                  ),
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Clear Search Link ─────────────────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _clearSearch,
                          child: const Text(
                            'Clear Search',
                            style: TextStyle(
                              fontFamily: AppTypographyTokens.bodyFontFamily,
                              fontSize: 12.5,
                              fontWeight: AppTypographyTokens.medium,
                              color: TextColors.textTertiary600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Search Results List ─────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyResults(hasQuery)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final project = filtered[index];
                            return _SearchProjectItemCard(
                              project: project,
                              onViewProject: () =>
                                  _onViewProject(project, filtered, index),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyResults(bool hasQuery) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: UtilityGrayColors.utilityGray100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: BorderColors.borderSecondary,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.search_off_rounded,
                  size: 26,
                  color: TextColors.textTertiary600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No matching projects found' : 'No projects yet',
              style: const TextStyle(
                fontFamily: AppTypographyTokens.displayFontFamily,
                fontSize: 16,
                fontWeight: AppTypographyTokens.semibold,
                color: TextColors.textPrimary900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Try searching with different keywords or project titles.'
                  : 'Add a project to showcase your work here.',
              style: const TextStyle(
                fontFamily: AppTypographyTokens.bodyFontFamily,
                fontSize: 13,
                color: TextColors.textTertiary600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Project Item Card — Exactly 380x124
// ─────────────────────────────────────────────────────────────────────────────

class _SearchProjectItemCard extends StatelessWidget {
  const _SearchProjectItemCard({
    required this.project,
    required this.onViewProject,
  });

  final ProjectModel project;
  final VoidCallback onViewProject;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewProject,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 124,
        width: double.infinity,
        decoration: BoxDecoration(
          color: BackgroundColors.bgPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BorderColors.borderSecondary,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: ShadowColors.shadowXs,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left: Thumbnail (100x100 within 124 card) ───────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 100,
                child: _buildThumbnail(),
              ),
            ),

            const SizedBox(width: 12),

            // ── Right: Details Column ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypographyTokens.bodyFontFamily,
                          fontSize: 14.5,
                          fontWeight: AppTypographyTokens.bold,
                          color: TextColors.textPrimary900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Description (2 lines max)
                      Text(
                        project.projectDescription.isNotEmpty
                            ? project.projectDescription
                            : project.companyDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypographyTokens.bodyFontFamily,
                          fontSize: 11.5,
                          fontWeight: AppTypographyTokens.regular,
                          color: TextColors.textTertiary600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),

                  // "View Project ->" Action Link
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Project',
                        style: const TextStyle(
                          fontFamily: AppTypographyTokens.bodyFontFamily,
                          fontSize: 12.5,
                          fontWeight: AppTypographyTokens.semibold,
                          color: BackgroundColors.bgBrandSolid, // #E04F16
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: BackgroundColors.bgBrandSolid, // #E04F16
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final url = project.thumbnailUrl ??
        (project.mediaUrls.isNotEmpty ? project.mediaUrls.first : null);

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: UtilityGrayColors.utilityGray100,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
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
          size: 26,
          color: Colors.white70,
        ),
      ),
    );
  }
}
