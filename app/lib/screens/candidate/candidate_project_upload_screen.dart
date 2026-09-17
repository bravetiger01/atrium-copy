import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_typography_tokens.dart';
import '../../theme/light_mode_token.dart';
import 'candidate_project_details_screen.dart';
import 'models/project_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Project Media Item (wraps either an existing remote URL or a new local File)
// ─────────────────────────────────────────────────────────────────────────────

class ProjectMediaItem {
  final File? file;
  final String? url;

  ProjectMediaItem.file(File this.file) : url = null;
  ProjectMediaItem.url(String this.url) : file = null;

  bool get isUrl => url != null && url!.isNotEmpty;
  String get identifier => isUrl ? url! : file!.path;
}

// ─────────────────────────────────────────────────────────────────────────────
// Candidate Project Upload Screen — Screen 1 & Screen 2
//   • Screen 1: Empty state (Import the media of your project)
//   • Screen 2: Populated state (Adjust the media of your project)
// ─────────────────────────────────────────────────────────────────────────────

class CandidateProjectUploadScreen extends StatefulWidget {
  const CandidateProjectUploadScreen({
    super.key,
    this.projectToEdit,
  });

  final ProjectModel? projectToEdit;

  @override
  State<CandidateProjectUploadScreen> createState() =>
      _CandidateProjectUploadScreenState();
}

class _CandidateProjectUploadScreenState
    extends State<CandidateProjectUploadScreen> {
  final List<ProjectMediaItem> _mediaItems = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.projectToEdit != null) {
      for (final u in widget.projectToEdit!.mediaUrls) {
        if (u.isNotEmpty) {
          _mediaItems.add(ProjectMediaItem.url(u));
        }
      }
      if (_mediaItems.isEmpty &&
          widget.projectToEdit!.thumbnailUrl != null &&
          widget.projectToEdit!.thumbnailUrl!.isNotEmpty) {
        _mediaItems.add(ProjectMediaItem.url(widget.projectToEdit!.thumbnailUrl!));
      }
    }
  }

  Future<void> _pickImages() async {
    HapticFeedback.lightImpact();
    try {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 85);
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _mediaItems.addAll(
            pickedFiles.map((x) => ProjectMediaItem.file(File(x.path))),
          );
        });
      }
    } catch (_) {
      // Fallback to FilePicker if ImagePicker fails or for other formats
      _pickFiles();
    }
  }

  Future<void> _pickFiles() async {
    HapticFeedback.lightImpact();
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'svg', 'mp4', 'mov', 'pptx'],
      );

      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          for (final path in result.paths) {
            if (path != null) {
              _mediaItems.add(ProjectMediaItem.file(File(path)));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file picker')),
        );
      }
    }
  }

  void _removeMedia(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _mediaItems.removeAt(index);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _mediaItems.removeAt(oldIndex);
      _mediaItems.insert(newIndex, item);
    });
  }

  void _onNext() async {
    if (_mediaItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 image for thumbnail'),
        ),
      );
      return;
    }

    final updatedProject = await Navigator.of(context).push<ProjectModel>(
      MaterialPageRoute(
        builder: (_) => CandidateProjectDetailsScreen(
          mediaItems: _mediaItems,
          projectToEdit: widget.projectToEdit,
        ),
      ),
    );

    if (updatedProject != null && mounted) {
      Navigator.of(context).pop(updatedProject);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _mediaItems.isNotEmpty;

    return Scaffold(
      backgroundColor: UtilityGrayColors.utilityGray50,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
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
                ],
              ),
            ),

            // ── Body: Screen 1 vs Screen 2 ─────────────────────────────────
            Expanded(
              child: hasMedia ? _buildScreen2() : _buildScreen1(),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Screen 1: Empty state — Import the media of your project
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildScreen1() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Heading
            const Text(
              'Import the media of your project',
              style: TextStyle(
                fontFamily: AppTypographyTokens.displayFontFamily,
                fontSize: 22,
                fontWeight: AppTypographyTokens.semibold,
                color: TextColors.textPrimary900,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Only Images, Videos, PPTX, are supported',
              style: TextStyle(
                fontFamily: AppTypographyTokens.bodyFontFamily,
                fontSize: 13.5,
                fontWeight: AppTypographyTokens.regular,
                color: TextColors.textTertiary600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Dropzone Container
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cloud upload badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: UtilityGrayColors.utilityGray100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: BorderColors.borderSecondary,
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          size: 22,
                          color: TextColors.textTertiary600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Callout text
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: AppTypographyTokens.bodyFontFamily,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: 'Click to upload',
                            style: TextStyle(
                              color: BackgroundColors.bgBrandSolid, // #E04F16
                              fontWeight: AppTypographyTokens.semibold,
                            ),
                          ),
                          TextSpan(
                            text: ' or drag and drop',
                            style: TextStyle(
                              color: TextColors.textTertiary600,
                              fontWeight: AppTypographyTokens.regular,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'SVG, PNG, JPG or GIF (max. 800x400px)',
                      style: TextStyle(
                        fontFamily: AppTypographyTokens.bodyFontFamily,
                        fontSize: 12,
                        color: TextColors.textQuaternary500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Helper note
            const Text(
              'Atleast 1 Image is Required for thumbnail',
              style: TextStyle(
                fontFamily: AppTypographyTokens.bodyFontFamily,
                fontSize: 12.5,
                fontWeight: AppTypographyTokens.medium,
                color: TextColors.textTertiary600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Screen 2: Populated state — Adjust the media of your project
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildScreen2() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading
                const Text(
                  'Adjust the media of your project',
                  style: TextStyle(
                    fontFamily: AppTypographyTokens.displayFontFamily,
                    fontSize: 22,
                    fontWeight: AppTypographyTokens.semibold,
                    color: TextColors.textPrimary900,
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle
                const Text(
                  'The first image will serve as the cover for this project.',
                  style: TextStyle(
                    fontFamily: AppTypographyTokens.bodyFontFamily,
                    fontSize: 13.5,
                    fontWeight: AppTypographyTokens.regular,
                    color: TextColors.textTertiary600,
                  ),
                ),

                const SizedBox(height: 20),

                // Reorderable list of media cards
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _mediaItems.length,
                  onReorder: _onReorder,
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    final item = _mediaItems[index];
                    return _MediaCard(
                      key: ValueKey(item.identifier),
                      item: item,
                      index: index,
                      onDelete: () => _removeMedia(index),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // "Add more media" separator
                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: BorderColors.borderSecondary,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Add more media',
                        style: TextStyle(
                          fontFamily: AppTypographyTokens.bodyFontFamily,
                          fontSize: 12.5,
                          fontWeight: AppTypographyTokens.medium,
                          color: TextColors.textTertiary600,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: BorderColors.borderSecondary,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Secondary compact upload box
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: BackgroundColors.bgPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: BorderColors.borderSecondary,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: UtilityGrayColors.utilityGray100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: BorderColors.borderSecondary,
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 20,
                              color: TextColors.textTertiary600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: AppTypographyTokens.bodyFontFamily,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: 'Click to upload',
                                style: TextStyle(
                                  color: BackgroundColors.bgBrandSolid,
                                  fontWeight: AppTypographyTokens.semibold,
                                ),
                              ),
                              TextSpan(
                                text: ' or drag and drop',
                                style: TextStyle(
                                  color: TextColors.textTertiary600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'SVG, PNG, JPG or GIF (max. 800x400px)',
                          style: TextStyle(
                            fontFamily: AppTypographyTokens.bodyFontFamily,
                            fontSize: 11,
                            color: TextColors.textQuaternary500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // ── Bottom "Next" button ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: BackgroundColors.bgBrandSolid,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.bodyFontFamily,
                  fontSize: 15,
                  fontWeight: AppTypographyTokens.semibold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Media Card with drag handle and delete button
// ─────────────────────────────────────────────────────────────────────────────

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    super.key,
    required this.item,
    required this.index,
    required this.onDelete,
  });

  final ProjectMediaItem item;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 180,
      decoration: BoxDecoration(
        color: UtilityGrayColors.utilityGray200,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: ShadowColors.shadowXs,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media Image Thumbnail (URL or File)
            item.isUrl
                ? CachedNetworkImage(
                    imageUrl: item.url!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 44,
                        color: TextColors.textTertiary600,
                      ),
                    ),
                  )
                : Image.file(
                    item.file!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.insert_drive_file_rounded,
                        size: 48,
                        color: TextColors.textTertiary600,
                      ),
                    ),
                  ),

            // Top-left Drag Handle
            Positioned(
              top: 10,
              left: 10,
              child: ReorderableDragStartListener(
                index: index,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 20,
                      color: TextColors.textPrimary900,
                    ),
                  ),
                ),
              ),
            ),

            // Top-right Delete Cross
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: TextColors.textPrimary900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
