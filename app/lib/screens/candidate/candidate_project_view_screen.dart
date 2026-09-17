import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/project_service.dart';
import '../../theme/app_typography_tokens.dart';
import '../../theme/light_mode_token.dart';
import 'candidate_project_upload_screen.dart';
import 'models/project_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Candidate Project View Screen (Screen 1 under Project - Edit / Delete in Figma)
// ─────────────────────────────────────────────────────────────────────────────

class CandidateProjectViewScreen extends StatefulWidget {
  const CandidateProjectViewScreen({
    super.key,
    required this.project,
    this.allProjects,
    this.currentIndex,
  });

  final ProjectModel project;
  final List<ProjectModel>? allProjects;
  final int? currentIndex;

  @override
  State<CandidateProjectViewScreen> createState() =>
      _CandidateProjectViewScreenState();
}

class _CandidateProjectViewScreenState
    extends State<CandidateProjectViewScreen> {
  late ProjectModel _currentProject;
  late int _projectIndex;
  late final PageController _pageController;
  int _activeMediaIndex = 0;
  bool _isDeleting = false;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _projectIndex = widget.currentIndex ?? 0;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _mediaList {
    if (_currentProject.mediaUrls.isNotEmpty) {
      return _currentProject.mediaUrls;
    }
    if (_currentProject.thumbnailUrl != null &&
        _currentProject.thumbnailUrl!.isNotEmpty) {
      return [_currentProject.thumbnailUrl!];
    }
    return [];
  }

  void _onEditProject() async {
    final updated = await Navigator.of(context).push<ProjectModel>(
      MaterialPageRoute(
        builder: (_) => CandidateProjectUploadScreen(
          projectToEdit: _currentProject,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentProject = updated;
        _activeMediaIndex = 0;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final coverUrl = _currentProject.thumbnailUrl ??
        (_mediaList.isNotEmpty ? _mediaList.first : null);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: BackgroundColors.bgPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Project thumbnail preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: _renderCoverImage(coverUrl),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'Delete "${_currentProject.title}"',
                style: const TextStyle(
                  fontFamily: AppTypographyTokens.displayFontFamily,
                  fontSize: 18,
                  fontWeight: AppTypographyTokens.bold,
                  color: TextColors.textPrimary900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              const Text(
                'Are you sure you want to delete this project from your Project Collection?',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.bodyFontFamily,
                  fontSize: 13,
                  fontWeight: AppTypographyTokens.regular,
                  color: TextColors.textTertiary600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Delete Button (Red)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TextColors.textErrorPrimary600, // #D92D20
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      fontFamily: AppTypographyTokens.bodyFontFamily,
                      fontSize: 14.5,
                      fontWeight: AppTypographyTokens.semibold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Cancel Button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(ctx).pop(false),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: AppTypographyTokens.bodyFontFamily,
                      fontSize: 14,
                      fontWeight: AppTypographyTokens.medium,
                      color: TextColors.textSecondary700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await ProjectService().deleteProject(
            uid: uid,
            projectId: _currentProject.id,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project deleted successfully'),
              backgroundColor: TextColors.textPrimary900,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete project: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _onNextProject() {
    final list = widget.allProjects;
    if (list != null && list.length > 1) {
      final nextIdx = (_projectIndex + 1) % list.length;
      setState(() {
        _projectIndex = nextIdx;
        _currentProject = list[nextIdx];
        _activeMediaIndex = 0;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = _mediaList;
    final isOwner =
        FirebaseAuth.instance.currentUser?.uid == _currentProject.userId;
    final hasNext = widget.allProjects != null && widget.allProjects!.length > 1;

    return Scaffold(
      backgroundColor: UtilityGrayColors.utilityGray50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Navigation Bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: GestureDetector(
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
            ),

            // ── Title & Options Header Row ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project Title
                        Text(
                          _currentProject.title,
                          style: const TextStyle(
                            fontFamily: AppTypographyTokens.displayFontFamily,
                            fontSize: 24,
                            fontWeight: AppTypographyTokens.bold,
                            color: TextColors.textPrimary900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Subtitle: Client Name or Category
                        Text(
                          _currentProject.client != null &&
                                  _currentProject.client!.isNotEmpty
                              ? 'Client: ${_currentProject.client}'
                              : _currentProject.category,
                          style: const TextStyle(
                            fontFamily: AppTypographyTokens.bodyFontFamily,
                            fontSize: 13.5,
                            fontWeight: AppTypographyTokens.medium,
                            color: TextColors.textTertiary600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Vertical 3-Dots Button with Popup Menu ───────────────
                  if (isOwner)
                    _isDeleting
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _buildOptionsPopupMenu(),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Scrollable Body ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Media Preview Carousel ─────────────────────────────
                    if (mediaList.isNotEmpty)
                      _buildCarousel(mediaList)
                    else
                      _buildFallbackHeader(),

                    const SizedBox(height: 22),

                    // ── About Client Section ───────────────────────────────
                    const Text(
                      'About Client',
                      style: TextStyle(
                        fontFamily: AppTypographyTokens.displayFontFamily,
                        fontSize: 16,
                        fontWeight: AppTypographyTokens.bold,
                        color: TextColors.textPrimary900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentProject.companyDescription.isNotEmpty
                          ? _currentProject.companyDescription
                          : (_currentProject.client != null &&
                                  _currentProject.client!.isNotEmpty
                              ? 'Working in collaboration with ${_currentProject.client}.'
                              : 'No company description provided.'),
                      style: const TextStyle(
                        fontFamily: AppTypographyTokens.bodyFontFamily,
                        fontSize: 13.5,
                        fontWeight: AppTypographyTokens.regular,
                        color: TextColors.textTertiary600,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── The Project Section ────────────────────────────────
                    const Text(
                      'The Project',
                      style: TextStyle(
                        fontFamily: AppTypographyTokens.displayFontFamily,
                        fontSize: 16,
                        fontWeight: AppTypographyTokens.bold,
                        color: TextColors.textPrimary900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentProject.projectDescription.isNotEmpty
                          ? _currentProject.projectDescription
                          : 'No project description provided.',
                      style: const TextStyle(
                        fontFamily: AppTypographyTokens.bodyFontFamily,
                        fontSize: 13.5,
                        fontWeight: AppTypographyTokens.regular,
                        color: TextColors.textTertiary600,
                        height: 1.45,
                      ),
                    ),

                    // ── "Next Project >" Link ──────────────────────────────
                    if (hasNext) ...[
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onNextProject,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Next Project',
                                style: TextStyle(
                                  fontFamily: AppTypographyTokens.bodyFontFamily,
                                  fontSize: 13,
                                  fontWeight: AppTypographyTokens.semibold,
                                  color: TextColors.textTertiary600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: TextColors.textTertiary600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Options Popup Menu (Screen 1 in Figma: Edit Project & Delete Project)
  // Dropdown dimensions: 248x93
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOptionsPopupMenu() {
    return PopupMenuButton<String>(
      constraints: const BoxConstraints.tightFor(width: 248, height: 93),
      position: PopupMenuPosition.under,
      offset: const Offset(-212, 6),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: BorderColors.borderSecondary,
          width: 1,
        ),
      ),
      color: BackgroundColors.bgPrimary,
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      onOpened: () {
        setState(() => _isMenuOpen = true);
      },
      onCanceled: () {
        setState(() => _isMenuOpen = false);
      },
      onSelected: (value) {
        setState(() => _isMenuOpen = false);
        if (value == 'edit') {
          _onEditProject();
        } else if (value == 'delete') {
          _confirmDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/edit.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                color: TextColors.textPrimary900,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: TextColors.textPrimary900,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit Project',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.bodyFontFamily,
                  fontSize: 14,
                  fontWeight: AppTypographyTokens.medium,
                  color: TextColors.textPrimary900,
                ),
              ),
            ],
          ),
        ),
        const _PopupMenuDivider1px(),
        PopupMenuItem<String>(
          value: 'delete',
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/delete.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                color: TextColors.textErrorPrimary600, // #D92D20
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: TextColors.textErrorPrimary600,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Project',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.bodyFontFamily,
                  fontSize: 14,
                  fontWeight: AppTypographyTokens.medium,
                  color: TextColors.textErrorPrimary600, // #D92D20
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _isMenuOpen ? BackgroundColors.bgPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: _isMenuOpen
              ? Border.all(
                  color: BackgroundColors.bgBrandSolid, // #E04F16
                  width: 1.5,
                )
              : null,
        ),
        child: Center(
          child: Image.asset(
            'assets/icons/dots-vertical.png',
            width: 18,
            height: 18,
            fit: BoxFit.contain,
            color: _isMenuOpen
                ? BackgroundColors.bgBrandSolid // #E04F16
                : TextColors.textSecondary700,
            errorBuilder: (_, __, ___) => Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: _isMenuOpen
                  ? BackgroundColors.bgBrandSolid
                  : TextColors.textSecondary700,
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Media Carousel with Overlaid Previous/Next buttons & Dots Indicator
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCarousel(List<String> mediaList) {
    return Column(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: UtilityGrayColors.utilityGray100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BorderColors.borderSecondary,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: ShadowColors.shadowXs,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                // PageView
                PageView.builder(
                  controller: _pageController,
                  itemCount: mediaList.length,
                  onPageChanged: (idx) {
                    setState(() => _activeMediaIndex = idx);
                  },
                  itemBuilder: (context, idx) {
                    return _renderCoverImage(mediaList[idx]);
                  },
                ),

                // Left Arrow Button (<)
                if (mediaList.length > 1 && _activeMediaIndex > 0)
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 20,
                              color: TextColors.textPrimary900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Right Arrow Button (>)
                if (mediaList.length > 1 &&
                    _activeMediaIndex < mediaList.length - 1)
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: TextColors.textPrimary900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Indicator Dots
        if (mediaList.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(mediaList.length, (idx) {
              final isActive = idx == _activeMediaIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? BackgroundColors.bgBrandSolid
                      : BorderColors.borderSecondary,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackHeader() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
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
          size: 48,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _renderCoverImage(String? url) {
    if (url == null || url.isEmpty) {
      return _buildFallbackHeader();
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (_, __, ___) => _buildFallbackHeader(),
      );
    } else if (File(url).existsSync()) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackHeader(),
      );
    }
    return _buildFallbackHeader();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exact 1px Menu Divider
// ─────────────────────────────────────────────────────────────────────────────
class _PopupMenuDivider1px extends PopupMenuEntry<Never> {
  const _PopupMenuDivider1px();

  @override
  final double height = 1;

  @override
  bool represents(void value) => false;

  @override
  State<_PopupMenuDivider1px> createState() => _PopupMenuDivider1pxState();
}

class _PopupMenuDivider1pxState extends State<_PopupMenuDivider1px> {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: BorderColors.borderSecondary,
    );
  }
}

