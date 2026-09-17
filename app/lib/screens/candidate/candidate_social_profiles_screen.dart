import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_typography_tokens.dart';
import '../../theme/light_mode_token.dart';
import '../../main.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Candidate Onboarding — Screen 2 "Share your Social Profiles"
// ─────────────────────────────────────────────────────────────────────────────

class CandidateSocialProfilesScreen extends StatefulWidget {
  final String uid;
  const CandidateSocialProfilesScreen({super.key, required this.uid});

  @override
  State<CandidateSocialProfilesScreen> createState() =>
      _CandidateSocialProfilesScreenState();
}

class _CandidateSocialProfilesScreenState
    extends State<CandidateSocialProfilesScreen> {
  // ── Controllers ─────────────────────────────────────────────────────────
  final _linkedInController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _newLinkNameController = TextEditingController();
  final _newLinkUrlController = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────
  final List<Map<String, String>> _resumes = [];
  bool _uploadingResume = false;
  bool _isAddingLink = false;
  bool _isContinuePressed = false;
  bool _isLoading = false;

  // Additional links saved by user
  final List<_SocialLink> _additionalLinks = [];

  // ── Typography ────────────────────────────────────────────────────────────
  static const _displaySmSemibold = TextStyle(
    fontFamily: AppTypographyTokens.displayFontFamily,
    fontSize: AppTypographyTokens.displaySm,
    fontWeight: AppTypographyTokens.semibold,
    height: AppTypographyTokens.displaySmHeight,
    color: TextColors.textPrimary900,
  );
  static const _textSmMedium = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textSm,
    fontWeight: AppTypographyTokens.medium,
    height: AppTypographyTokens.textSmHeight,
    color: TextColors.textSecondary700,
  );
  static const _textSmRegular = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textSm,
    fontWeight: AppTypographyTokens.regular,
    height: AppTypographyTokens.textSmHeight,
  );
  static const _textMdRegular = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textMd,
    fontWeight: AppTypographyTokens.regular,
    height: AppTypographyTokens.textMdHeight,
  );
  static const _textMdSemibold = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textMd,
    fontWeight: AppTypographyTokens.semibold,
  );
  static const _textXsRegular = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textXs,
    fontWeight: AppTypographyTokens.regular,
    height: AppTypographyTokens.textXsHeight,
    color: TextColors.textTertiary600,
  );

  @override
  void initState() {
    super.initState();
    _linkedInController.addListener(() => setState(() {}));
    _portfolioController.addListener(() => setState(() {}));
    _newLinkNameController.addListener(() => setState(() {}));
    _newLinkUrlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _linkedInController.dispose();
    _portfolioController.dispose();
    _newLinkNameController.dispose();
    _newLinkUrlController.dispose();
    super.dispose();
  }

  // ── Validation — Continue active when LinkedIn URL is filled ─────────────
  bool get _canContinue => _linkedInController.text.trim().isNotEmpty;

  // ── Resume: pick a PDF/DOC and upload to Storage ─────────────────────────
  Future<void> _pickResume() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      allowMultiple: true, // Allow selecting multiple files at once
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _uploadingResume = true;
    });

    try {
      for (final file in result.files) {
        if (file.path == null) continue;
        
        final extension = (file.extension?.isNotEmpty == true)
            ? file.extension!.toLowerCase()
            : 'pdf';
            
        final ref = FirebaseStorage.instance
            .ref()
            .child('resumes/${widget.uid}_${DateTime.now().millisecondsSinceEpoch}.$extension');
            
        await ref.putFile(File(file.path!));
        final url = await ref.getDownloadURL();
        
        if (mounted) {
          setState(() {
            _resumes.add({
              'fileName': file.name,
              'fileSize': _formatSize(file.size),
              'url': url,
            });
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('One or more resumes failed to upload. Please retry.')),
        );
      }
    }
    if (mounted) setState(() => _uploadingResume = false);
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  // ── Continue ──────────────────────────────────────────────────────────────
  Future<void> _persistOnboardingData() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .set({
          'profile': {
            if (_resumes.isNotEmpty) 'resumes': _resumes,
            if (_linkedInController.text.trim().isNotEmpty)
              'linkedinUrl': _linkedInController.text.trim(),
            if (_portfolioController.text.trim().isNotEmpty)
              'portfolioUrl': _portfolioController.text.trim(),
            if (_additionalLinks.isNotEmpty)
              'socialLinks': _additionalLinks
                  .map((l) => {'name': l.name, 'url': l.url})
                  .toList(),
          },
        }, SetOptions(merge: true));
  }

  Future<void> _completeOnboarding() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set({'onboardingDone': true}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to mark onboarding done: $e');
    }
  }

  Future<void> _onContinue() async {
    if (!_canContinue || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _persistOnboardingData();
      await _completeOnboarding();
    } catch (e) {
      debugPrint('Failed to save onboarding data: $e');
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _skip() async {
    setState(() => _isLoading = true);
    try {
      await _persistOnboardingData();
      await _completeOnboarding();
    } catch (e) {
      debugPrint('Failed to save onboarding data: $e');
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    }
  }

  // ── Save new additional link ───────────────────────────────────────────────
  void _saveNewLink() {
    final name = _newLinkNameController.text.trim();
    final url = _newLinkUrlController.text.trim();
    if (name.isEmpty || url.isEmpty) return;
    setState(() {
      _additionalLinks.add(_SocialLink(name: name, url: url));
      _newLinkNameController.clear();
      _newLinkUrlController.clear();
      _isAddingLink = false;
    });
  }

  void _cancelNewLink() {
    setState(() {
      _newLinkNameController.clear();
      _newLinkUrlController.clear();
      _isAddingLink = false;
    });
  }

  // ── Shared border builder ─────────────────────────────────────────────────
  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  // ── Field label ──────────────────────────────────────────────────────────
  Widget _label(String text) => Text(text, style: _textSmMedium);

  // ── Generic URL input ─────────────────────────────────────────────────────
  Widget _urlField({
    required TextEditingController controller,
    required String hint,
  }) {
    final hasContent = controller.text.isNotEmpty;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.url,
      style: _textMdRegular.copyWith(color: TextColors.textPrimary900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _textMdRegular.copyWith(color: TextColors.textPlaceholder),
        filled: true,
        fillColor: BackgroundColors.bgPrimary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: _border(BorderColors.borderPrimary),
        enabledBorder: _border(
          hasContent ? BorderColors.borderBrand : BorderColors.borderPrimary,
        ),
        focusedBorder: _border(FocusRingColors.focusRing, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UtilityGrayColors.utilityGray50,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Logo row + Skip ───────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/logos/Logomark-without-bg.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                        // Skip button — textMd/Semibold, textTertiary600
                        GestureDetector(
                          onTap: _skip,
                          child: Text(
                            'Skip',
                            style: _textMdSemibold.copyWith(
                              color: TextColors.textTertiary600,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Heading ───────────────────────────────────────────
                    const Text(
                      'Share your Social Profiles',
                      style: _displaySmSemibold,
                    ),

                    const SizedBox(height: 24),

                    // ── Resume upload zone ────────────────────────────────
                    if (_uploadingResume)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: BackgroundColors.bgPrimary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: BorderColors.borderSecondary,
                          ),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                    else
                      _ResumeUploadZone(
                        onTap: _pickResume,
                        textSmRegular: _textSmRegular,
                        textXsRegular: _textXsRegular,
                      ),
                      
                    ..._resumes.map((resume) => Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _ResumeFilePreview(
                            fileName: resume['fileName']!,
                            fileSize: resume['fileSize']!,
                            onRemove: () => setState(() {
                              _resumes.remove(resume);
                            }),
                            textSmMedium: _textSmMedium,
                            textXsRegular: _textXsRegular,
                          ),
                        )),

                    const SizedBox(height: 20),

                    // ── LinkedIn URL ──────────────────────────────────────
                    _label('LinkedIn URL'),
                    const SizedBox(height: 6),
                    _urlField(
                      controller: _linkedInController,
                      hint: 'www.linkedin.com/in/...',
                    ),

                    const SizedBox(height: 20),

                    // ── Portfolio URL ─────────────────────────────────────
                    _label('Portfolio URL'),
                    const SizedBox(height: 6),
                    _urlField(
                      controller: _portfolioController,
                      hint: 'www.portfolio.link',
                    ),

                    // ── Saved additional links ────────────────────────────
                    ..._additionalLinks.map((link) => Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(link.name),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: BackgroundColors.bgPrimary,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: BorderColors.borderBrand,
                                  ),
                                ),
                                child: Text(
                                  link.url,
                                  style: _textMdRegular.copyWith(
                                    color: TextColors.textPrimary900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),

                    const SizedBox(height: 20),

                    // ── Add another inline form ───────────────────────────
                    if (_isAddingLink)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BackgroundColors.bgPrimary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BorderColors.borderPrimary),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name of link
                            _label('Name of Link'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _newLinkNameController,
                              style: _textMdRegular.copyWith(
                                  color: TextColors.textPrimary900),
                              decoration: InputDecoration(
                                hintText: 'Instagram, etc.',
                                hintStyle: _textMdRegular.copyWith(
                                    color: TextColors.textPlaceholder),
                                filled: true,
                                fillColor: BackgroundColors.bgPrimary,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                border: _border(BorderColors.borderPrimary),
                                enabledBorder: _border(
                                  _newLinkNameController.text.isNotEmpty
                                      ? BorderColors.borderBrand
                                      : BorderColors.borderPrimary,
                                ),
                                focusedBorder:
                                    _border(FocusRingColors.focusRing, width: 2),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // URL
                            _label('Link'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _newLinkUrlController,
                              keyboardType: TextInputType.url,
                              style: _textMdRegular.copyWith(
                                  color: TextColors.textPrimary900),
                              decoration: InputDecoration(
                                hintText: 'www.instagram.com/user',
                                hintStyle: _textMdRegular.copyWith(
                                    color: TextColors.textPlaceholder),
                                filled: true,
                                fillColor: BackgroundColors.bgPrimary,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                border: _border(BorderColors.borderPrimary),
                                enabledBorder: _border(
                                  _newLinkUrlController.text.isNotEmpty
                                      ? BorderColors.borderBrand
                                      : BorderColors.borderPrimary,
                                ),
                                focusedBorder:
                                    _border(FocusRingColors.focusRing, width: 2),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Cancel / Save row
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _cancelNewLink,
                                    child: Center(
                                      child: Text(
                                        'Cancel',
                                        style: _textMdSemibold.copyWith(
                                          color: TextColors.textSecondary700,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _saveNewLink,
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: BackgroundColors.bgPrimary,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: BorderColors.borderPrimary,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Save',
                                          style: _textMdSemibold.copyWith(
                                            color: TextColors.textSecondary700,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // ── + Add another ─────────────────────────────────────
                    if (!_isAddingLink)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isAddingLink = true),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: TextColors.textSecondary700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Add another',
                              style: _textSmMedium.copyWith(
                                color: TextColors.textSecondary700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Continue button — pinned at bottom ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTapDown: (_) =>
                    setState(() => _isContinuePressed = true),
                onTapUp: (_) =>
                    setState(() => _isContinuePressed = false),
                onTapCancel: () =>
                    setState(() => _isContinuePressed = false),
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: ShapeDecoration(
                    color: _canContinue
                        ? BackgroundColors.bgBrandSolid
                        : BackgroundColors.bgDisabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: _canContinue
                            ? (_isContinuePressed
                                ? const Color(0x29E04F16)
                                : const Color(0x29FFFFFF))
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    shadows: _canContinue
                        ? [
                            BoxShadow(
                              color: ShadowColors.shadowXs,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                            BoxShadow(
                              color: ShadowColors.shadowSkeumorphicInner,
                              blurRadius: 0,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: (_canContinue && !_isLoading)
                        ? _onContinue
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: _canContinue
                          ? TextColors.textWhite
                          : ForegroundColors.fgDisabled,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: ForegroundColors.fgDisabled,
                      elevation: 0,
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Continue',
                            style: _textMdSemibold.copyWith(
                              color: _canContinue
                                  ? TextColors.textWhite
                                  : ForegroundColors.fgDisabled,
                              height: 1.0,
                            ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Data class for additional social links
// ─────────────────────────────────────────────────────────────────────────────

class _SocialLink {
  final String name;
  final String url;
  const _SocialLink({required this.name, required this.url});
}

// ─────────────────────────────────────────────────────────────────────────────
// Resume upload zone (empty state)
// ─────────────────────────────────────────────────────────────────────────────

class _ResumeUploadZone extends StatelessWidget {
  final VoidCallback onTap;
  final TextStyle textSmRegular;
  final TextStyle textXsRegular;

  const _ResumeUploadZone({
    required this.onTap,
    required this.textSmRegular,
    required this.textXsRegular,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: BackgroundColors.bgPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: BorderColors.borderSecondary),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/upload.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Click to upload',
                    style: textSmRegular.copyWith(
                      fontWeight: AppTypographyTokens.semibold,
                      color: TextColors.textBrandSecondary700,
                    ),
                  ),
                  TextSpan(
                    text: ' or drag and drop',
                    style:
                        textSmRegular.copyWith(color: TextColors.textTertiary600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, DOC or DOCX (max. 10 MB)',
              style: textXsRegular,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resume file preview (uploaded state)
// ─────────────────────────────────────────────────────────────────────────────

class _ResumeFilePreview extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final VoidCallback onRemove;
  final TextStyle textSmMedium;
  final TextStyle textXsRegular;

  const _ResumeFilePreview({
    required this.fileName,
    required this.fileSize,
    required this.onRemove,
    required this.textSmMedium,
    required this.textXsRegular,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BackgroundColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BorderColors.borderSecondary),
      ),
      child: Row(
        children: [
          // File doc icon
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 20,
            color: TextColors.textSecondary700,
          ),
          const SizedBox(width: 10),
          // File name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: textSmMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      fileSize,
                      style: textXsRegular,
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: TextColors.textSuccessPrimary600,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '100%',
                      style: textXsRegular.copyWith(
                        color: TextColors.textSuccessPrimary600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Trash / remove button
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: TextColors.textTertiary600,
            ),
          ),
        ],
      ),
    );
  }
}
