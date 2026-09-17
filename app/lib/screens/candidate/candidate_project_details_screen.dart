import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/project_service.dart';
import '../../theme/app_typography_tokens.dart';
import '../../theme/light_mode_token.dart';
import 'candidate_project_upload_screen.dart';
import 'models/project_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Candidate Project Details Screen — Screen 3
//   • Title, Client, Company Description, Rich Description with toolbar
//   • Uploads to Firebase Storage and saves/updates in Firestore
// ─────────────────────────────────────────────────────────────────────────────

class CandidateProjectDetailsScreen extends StatefulWidget {
  const CandidateProjectDetailsScreen({
    super.key,
    required this.mediaItems,
    this.projectToEdit,
  });

  final List<ProjectMediaItem> mediaItems;
  final ProjectModel? projectToEdit;

  @override
  State<CandidateProjectDetailsScreen> createState() =>
      _CandidateProjectDetailsScreenState();
}

class _CandidateProjectDetailsScreenState
    extends State<CandidateProjectDetailsScreen> {
  final _titleController = TextEditingController();
  final _clientController = TextEditingController();
  final _companyDescController = TextEditingController();
  final _projectDescController = TextEditingController();

  final int _maxChars = 1000;
  bool _isSaving = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // Formatting toolbar active states
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();
    if (widget.projectToEdit != null) {
      _titleController.text = widget.projectToEdit!.title;
      _clientController.text = widget.projectToEdit!.client ?? '';
      _companyDescController.text = widget.projectToEdit!.companyDescription;
      _projectDescController.text = widget.projectToEdit!.projectDescription;
    }
    _projectDescController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _clientController.dispose();
    _companyDescController.dispose();
    _projectDescController.dispose();
    super.dispose();
  }

  Future<void> _submitProject() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a Project Title')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save a project')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadStatus = 'Processing media...';
    });

    try {
      final isEditing = widget.projectToEdit != null;
      final projectId = isEditing
          ? widget.projectToEdit!.id
          : DateTime.now().millisecondsSinceEpoch.toString();

      // Separate existing remote URLs and new local Files to upload
      final List<File> filesToUpload = [];
      final Map<int, String> existingUrlMap = {};

      for (int i = 0; i < widget.mediaItems.length; i++) {
        final item = widget.mediaItems[i];
        if (item.isUrl) {
          existingUrlMap[i] = item.url!;
        } else if (item.file != null) {
          filesToUpload.add(item.file!);
        }
      }

      List<String> uploadedUrls = [];
      if (filesToUpload.isNotEmpty) {
        if (mounted) {
          setState(() => _uploadStatus = 'Uploading media to storage...');
        }
        uploadedUrls = await ProjectService().uploadProjectMedia(
          uid: uid,
          projectId: projectId,
          files: filesToUpload,
          onProgress: (prog) {
            if (mounted) setState(() => _uploadProgress = prog);
          },
        );
      }

      // Reconstruct final media list in user's specified order
      final List<String> finalMediaUrls = [];
      int uploadIndex = 0;
      for (int i = 0; i < widget.mediaItems.length; i++) {
        if (existingUrlMap.containsKey(i)) {
          finalMediaUrls.add(existingUrlMap[i]!);
        } else if (uploadIndex < uploadedUrls.length) {
          finalMediaUrls.add(uploadedUrls[uploadIndex]);
          uploadIndex++;
        }
      }

      if (mounted) {
        setState(() => _uploadStatus = isEditing ? 'Updating project...' : 'Saving project details...');
      }

      ProjectModel savedProject;
      if (isEditing) {
        await ProjectService().updateProject(
          uid: uid,
          projectId: projectId,
          title: title,
          client: _clientController.text.trim().isNotEmpty
              ? _clientController.text.trim()
              : null,
          category: widget.projectToEdit!.category,
          companyDescription: _companyDescController.text.trim(),
          projectDescription: _projectDescController.text.trim(),
          mediaUrls: finalMediaUrls,
          createdAt: widget.projectToEdit!.createdAt,
        );

        savedProject = widget.projectToEdit!.copyWith(
          title: title,
          client: _clientController.text.trim().isNotEmpty
              ? _clientController.text.trim()
              : null,
          companyDescription: _companyDescController.text.trim(),
          projectDescription: _projectDescController.text.trim(),
          mediaUrls: finalMediaUrls,
          thumbnailUrl: finalMediaUrls.isNotEmpty ? finalMediaUrls.first : null,
        );
      } else {
        await ProjectService().saveProject(
          uid: uid,
          title: title,
          client: _clientController.text.trim().isNotEmpty
              ? _clientController.text.trim()
              : null,
          category: 'Design',
          companyDescription: _companyDescController.text.trim(),
          projectDescription: _projectDescController.text.trim(),
          mediaUrls: finalMediaUrls,
        );

        savedProject = ProjectModel(
          id: projectId,
          userId: uid,
          title: title,
          client: _clientController.text.trim().isNotEmpty
              ? _clientController.text.trim()
              : null,
          category: 'Design',
          companyDescription: _companyDescController.text.trim(),
          projectDescription: _projectDescController.text.trim(),
          mediaUrls: finalMediaUrls,
          thumbnailUrl: finalMediaUrls.isNotEmpty ? finalMediaUrls.first : null,
          createdAt: DateTime.now(),
        );
      }

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Project updated successfully!' : 'Project created successfully!'),
            backgroundColor: const Color(0xFF12B76A),
          ),
        );

        if (isEditing) {
          Navigator.of(context).pop(savedProject);
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save project: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final charsRemaining = _maxChars - _projectDescController.text.length;

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

            // ── Form Content ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    const Text(
                      'Give some details of your project',
                      style: TextStyle(
                        fontFamily: AppTypographyTokens.displayFontFamily,
                        fontSize: 22,
                        fontWeight: AppTypographyTokens.semibold,
                        color: TextColors.textPrimary900,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── 1. Project Title * ─────────────────────────────────
                    _buildLabel('Project Title', isRequired: true),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'Project - Case Study',
                    ),

                    const SizedBox(height: 16),

                    // ── 2. Client ──────────────────────────────────────────
                    _buildLabel('Client'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _clientController,
                      hint: 'Client Name',
                    ),

                    const SizedBox(height: 16),

                    // ── 3. Company Description ─────────────────────────────
                    _buildLabel('Company Description'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _companyDescController,
                      hint: 'What you worked with this project',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Highlight your company focus.',
                      style: TextStyle(
                        fontFamily: AppTypographyTokens.bodyFontFamily,
                        fontSize: 12,
                        color: TextColors.textTertiary600,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── 4. Project Description with Formatting Toolbar ─────
                    _buildLabel('Project Description'),
                    const SizedBox(height: 8),

                    // Toolbar
                    _buildFormattingToolbar(),

                    // Editor box
                    Container(
                      decoration: const BoxDecoration(
                        color: BackgroundColors.bgPrimary,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(8),
                        ),
                        border: Border(
                          left: BorderSide(color: BorderColors.borderSecondary),
                          right: BorderSide(color: BorderColors.borderSecondary),
                          bottom: BorderSide(color: BorderColors.borderSecondary),
                        ),
                      ),
                      child: TextField(
                        controller: _projectDescController,
                        maxLength: _maxChars,
                        maxLines: 7,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                            null, // custom counter below
                        style: TextStyle(
                          fontFamily: AppTypographyTokens.bodyFontFamily,
                          fontSize: 14,
                          fontWeight: _isBold
                              ? AppTypographyTokens.bold
                              : AppTypographyTokens.regular,
                          fontStyle:
                              _isItalic ? FontStyle.italic : FontStyle.normal,
                          decoration: _isUnderline
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          color: TextColors.textPrimary900,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter project details, role, impact...',
                          hintStyle: TextStyle(
                            fontFamily: AppTypographyTokens.bodyFontFamily,
                            fontSize: 14,
                            color: TextColors.textPlaceholder,
                          ),
                          contentPadding: EdgeInsets.all(14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Character counter
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$charsRemaining characters left',
                        style: const TextStyle(
                          fontFamily: AppTypographyTokens.bodyFontFamily,
                          fontSize: 12,
                          color: TextColors.textQuaternary500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Bottom Save Button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BackgroundColors.bgBrandSolid,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        BackgroundColors.bgBrandSolid.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _uploadStatus.isNotEmpty
                                  ? _uploadStatus
                                  : 'Publishing...',
                              style: const TextStyle(
                                fontFamily: AppTypographyTokens.bodyFontFamily,
                                fontSize: 14,
                                fontWeight: AppTypographyTokens.semibold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          widget.projectToEdit != null
                              ? 'Save Changes'
                              : 'Publish Project',
                          style: const TextStyle(
                            fontFamily: AppTypographyTokens.bodyFontFamily,
                            fontSize: 15,
                            fontWeight: AppTypographyTokens.semibold,
                            color: Colors.white,
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

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: AppTypographyTokens.bodyFontFamily,
          fontSize: 13.5,
          fontWeight: AppTypographyTokens.medium,
          color: TextColors.textSecondary700,
        ),
        children: [
          TextSpan(text: label),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: UtilityOrangeDarkColors.utilityOrangeDark600,
                fontWeight: AppTypographyTokens.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BackgroundColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: BorderColors.borderSecondary,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontFamily: AppTypographyTokens.bodyFontFamily,
          fontSize: 14,
          color: TextColors.textPrimary900,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: AppTypographyTokens.bodyFontFamily,
            fontSize: 14,
            color: TextColors.textPlaceholder,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: UtilityGrayColors.utilityGray50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          top: BorderSide(color: BorderColors.borderSecondary),
          left: BorderSide(color: BorderColors.borderSecondary),
          right: BorderSide(color: BorderColors.borderSecondary),
          bottom: BorderSide(color: BorderColors.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          // Bold
          _toolbarBtn(
            label: 'B',
            isActive: _isBold,
            onTap: () => setState(() => _isBold = !_isBold),
            isBold: true,
          ),
          const SizedBox(width: 8),
          // Italic
          _toolbarBtn(
            label: 'I',
            isActive: _isItalic,
            onTap: () => setState(() => _isItalic = !_isItalic),
            isItalic: true,
          ),
          const SizedBox(width: 8),
          // Underline
          _toolbarBtn(
            label: 'U',
            isActive: _isUnderline,
            onTap: () => setState(() => _isUnderline = !_isUnderline),
            isUnderline: true,
          ),
          const SizedBox(width: 14),
          // Dot / Bullet
          _toolbarIcon(Icons.circle, size: 8, onTap: () {
            final cur = _projectDescController.text;
            _projectDescController.text = '$cur\n• ';
          }),
          const SizedBox(width: 14),
          // Align left
          _toolbarIcon(Icons.format_align_left_rounded, size: 18, onTap: () {}),
          const SizedBox(width: 12),
          // Align center
          _toolbarIcon(Icons.format_align_center_rounded, size: 18, onTap: () {}),
          const SizedBox(width: 12),
          // List numbers
          _toolbarIcon(Icons.format_list_numbered_rounded, size: 18, onTap: () {
            final cur = _projectDescController.text;
            _projectDescController.text = '$cur\n1. ';
          }),
        ],
      ),
    );
  }

  Widget _toolbarBtn({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive
              ? UtilityOrangeDarkColors.utilityOrangeDark200
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              decoration: isUnderline ? TextDecoration.underline : null,
              color: isActive
                  ? UtilityOrangeDarkColors.utilityOrangeDark600
                  : TextColors.textSecondary700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, {required double size, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: size,
        color: TextColors.textTertiary600,
      ),
    );
  }
}
