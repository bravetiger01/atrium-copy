import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../theme/app_typography_tokens.dart';
import '../../theme/light_mode_token.dart';
import 'employer_contact_setup_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Employer Onboarding — Screen 1 "Build your organization profile"
// ─────────────────────────────────────────────────────────────────────────────

class EmployerProfileSetupScreen extends StatefulWidget {
  final String uid;
  const EmployerProfileSetupScreen({super.key, required this.uid});

  @override
  State<EmployerProfileSetupScreen> createState() =>
      _EmployerProfileSetupScreenState();
}

class _EmployerProfileSetupScreenState
    extends State<EmployerProfileSetupScreen> {
  // ── Controllers ─────────────────────────────────────────────────────────
  final _orgNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────
  String? _companySize;
  bool _sizeDropdownOpen = false;
  String? _logoFileName;
  String? _logoUrl;
  String? _logoLocalPath; // for preview before re-upload
  bool _uploadingLogo = false;
  bool _isContinuePressed = false;
  bool _isLoading = false;

  static const _companySizeOptions = [
    '0-25',
    '25-60',
    '60-100',
    '100-1000',
    '1000+',
  ];

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
    color: TextColors.textTertiary600,
  );
  static const _textMdRegular = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textMd,
    fontWeight: AppTypographyTokens.regular,
    height: AppTypographyTokens.textMdHeight,
  );
  static const _textMdMedium = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textMd,
    fontWeight: AppTypographyTokens.medium,
    height: AppTypographyTokens.textMdHeight,
    color: TextColors.textPrimary900,
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
    _orgNameController.addListener(() => setState(() {}));
    _gstinController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
    _locationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _gstinController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── Validation — required: GSTIN, Description, Location, Company Size ────
  bool get _canContinue =>
      _gstinController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty &&
      _companySize != null;

  // ── Logo upload ───────────────────────────────────────────────────────────
  Future<void> _pickLogo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;
    final extension =
        (file.extension?.isNotEmpty == true) ? file.extension! : 'png';

    setState(() {
      _uploadingLogo = true;
      _logoLocalPath = file.path; // show local preview immediately
    });
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('logos/${widget.uid}_${DateTime.now().millisecondsSinceEpoch}.$extension');
      await ref.putFile(File(file.path!));
      _logoUrl = await ref.getDownloadURL();
      if (mounted) setState(() => _logoFileName = file.name);
    } catch (_) {
      if (mounted) {
        setState(() => _logoLocalPath = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo upload failed. Please retry.')),
        );
      }
    }
    if (mounted) setState(() => _uploadingLogo = false);
  }

  void _removeLogo() {
    setState(() {
      _logoFileName = null;
      _logoUrl = null;
      _logoLocalPath = null;
    });
  }

  // ── Continue → Screen 2 ───────────────────────────────────────────────────
  Future<void> _onContinue() async {
    if (!_canContinue || _isLoading) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmployerContactSetupScreen(
            uid: widget.uid,
            orgName: _orgNameController.text.trim().isNotEmpty
                ? _orgNameController.text.trim()
                : 'Company',
            orgData: {
              'orgName': _orgNameController.text.trim(),
              'gstin': _gstinController.text.trim(),
              'description': _descriptionController.text.trim(),
              'location': _locationController.text.trim(),
              'companySize': _companySize!,
              if (_logoUrl != null) 'logoUrl': _logoUrl!,
            },
          ),
        ),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Shared border ─────────────────────────────────────────────────────────
  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _label(String text, {bool required = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: _textSmMedium),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                fontFamily: AppTypographyTokens.bodyFontFamily,
                fontSize: AppTypographyTokens.textSm,
                fontWeight: AppTypographyTokens.medium,
                color: TextColors.textBrandSecondary700,
              ),
            ),
        ],
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? helperText,
  }) {
    final hasContent = controller.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: _textMdMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                _textMdRegular.copyWith(color: TextColors.textPlaceholder),
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
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(helperText, style: _textXsRegular),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_sizeDropdownOpen) setState(() => _sizeDropdownOpen = false);
      },
      child: Scaffold(
        backgroundColor: UtilityGrayColors.utilityGray50,
        body: SafeArea(
          child: Column(
            children: [
              // ── Scrollable body ────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Logo ───────────────────────────────────────────────
                      Image.asset(
                        'assets/logos/Logomark-without-bg.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 24),

                      // ── Heading ────────────────────────────────────────────
                      const Text(
                        'Build your organization profile.',
                        style: _displaySmSemibold,
                      ),

                      const SizedBox(height: 32),

                      // ── Organization's Name (optional) ─────────────────────
                      _label("Organization's Name"),
                      const SizedBox(height: 6),
                      _inputField(
                        controller: _orgNameController,
                        hint: 'Atrium Inc.',
                      ),

                      const SizedBox(height: 20),

                      // ── Business GSTIN * ───────────────────────────────────
                      _label('Business GSTIN', required: true),
                      const SizedBox(height: 6),
                      _inputField(
                        controller: _gstinController,
                        hint: 'GST000544',
                      ),

                      const SizedBox(height: 20),

                      // ── Company Description * ──────────────────────────────
                      _label('Company Description', required: true),
                      const SizedBox(height: 6),
                      _inputField(
                        controller: _descriptionController,
                        hint: 'Hiring platform for Startups…',
                        maxLines: 4,
                        helperText: 'Highlight your company focus.',
                      ),

                      const SizedBox(height: 20),

                      // ── Location * ─────────────────────────────────────────
                      _label('Location', required: true),
                      const SizedBox(height: 6),
                      _inputField(
                        controller: _locationController,
                        hint: 'Vadodara, Gl, IN',
                        helperText: 'Where do you live?',
                      ),

                      const SizedBox(height: 20),

                      // ── Company Size? * (dropdown) ─────────────────────────
                      Row(
                        children: [
                          _label('Company Size?', required: true),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: TextColors.textTertiary600,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Dropdown trigger
                      _CompanySizeDropdown(
                        selected: _companySize,
                        isOpen: _sizeDropdownOpen,
                        options: _companySizeOptions,
                        textMdMedium: _textMdMedium,
                        textMdRegular: _textMdRegular,
                        textSmMedium: _textSmMedium,
                        textXsRegular: _textXsRegular,
                        onToggle: () => setState(
                            () => _sizeDropdownOpen = !_sizeDropdownOpen),
                        onSelect: (v) => setState(() {
                          _companySize = v;
                          _sizeDropdownOpen = false;
                        }),
                      ),

                      const SizedBox(height: 20),

                      // ── Company's Logo ─────────────────────────────────────
                      _label("Company's Logo"),
                      const SizedBox(height: 6),

                      // Show preview card once an image is picked
                      if (_logoLocalPath != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BackgroundColors.bgPrimary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _uploadingLogo
                                    ? BorderColors.borderSecondary
                                    : BorderColors.borderBrand),
                          ),
                          child: Row(
                            children: [
                              // Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(_logoLocalPath!),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // File info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _logoFileName ?? 'logo',
                                      style: _textSmMedium,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),
                                    if (_uploadingLogo) ...[
                                      const SizedBox(
                                        height: 3,
                                        child: LinearProgressIndicator(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(2)),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Uploading…',
                                          style: _textXsRegular),
                                    ] else ...[
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 13,
                                            color:
                                                TextColors.textSuccessPrimary600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text('Uploaded',
                                              style: _textXsRegular.copyWith(
                                                  color: TextColors
                                                      .textSuccessPrimary600)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Replace / remove buttons
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: _uploadingLogo ? null : _pickLogo,
                                    child: Text(
                                      'Replace',
                                      style: _textXsRegular.copyWith(
                                        color:
                                            TextColors.textBrandSecondary700,
                                        fontWeight:
                                            AppTypographyTokens.semibold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _uploadingLogo ? null : _removeLogo,
                                    child: Text(
                                      'Remove',
                                      style: _textXsRegular.copyWith(
                                        color: TextColors.textErrorPrimary600,
                                        fontWeight:
                                            AppTypographyTokens.semibold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Empty upload zone
                        _uploadingLogo
                            ? Container(
                                width: double.infinity,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: BackgroundColors.bgPrimary,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: BorderColors.borderSecondary),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: _pickLogo,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20),
                                  decoration: BoxDecoration(
                                    color: BackgroundColors.bgPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: BorderColors.borderSecondary),
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
                                              style: _textSmRegular.copyWith(
                                                fontWeight: AppTypographyTokens
                                                    .semibold,
                                                color: TextColors
                                                    .textBrandSecondary700,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' or drag and drop',
                                              style: _textSmRegular,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'PNG, JPG or GIF (max. 800×400px)',
                                        style: _textXsRegular,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── Continue button — pinned ─────────────────────────────────
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
                      onPressed:
                          (_canContinue && !_isLoading) ? _onContinue : null,
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
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Company Size custom dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _CompanySizeDropdown extends StatelessWidget {
  final String? selected;
  final bool isOpen;
  final List<String> options;
  final TextStyle textMdMedium;
  final TextStyle textMdRegular;
  final TextStyle textSmMedium;
  final TextStyle textXsRegular;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  const _CompanySizeDropdown({
    required this.selected,
    required this.isOpen,
    required this.options,
    required this.textMdMedium,
    required this.textMdRegular,
    required this.textSmMedium,
    required this.textXsRegular,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trigger
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: double.infinity,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: BackgroundColors.bgPrimary,
              borderRadius: isOpen
                  ? const BorderRadius.vertical(top: Radius.circular(8))
                  : BorderRadius.circular(8),
              border: Border.all(
                color: isOpen
                    ? BorderColors.borderBrand
                    : BorderColors.borderPrimary,
                width: isOpen ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected ?? '',
                    style: selected != null
                        ? textMdMedium
                        : textMdRegular.copyWith(
                            color: TextColors.textPlaceholder),
                  ),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: TextColors.textSecondary700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Options panel
        if (isOpen)
          Container(
            decoration: BoxDecoration(
              color: BackgroundColors.bgPrimary,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
              border: Border(
                left: BorderSide(
                    color: BorderColors.borderPrimary, width: 1),
                right: BorderSide(
                    color: BorderColors.borderPrimary, width: 1),
                bottom: BorderSide(
                    color: BorderColors.borderPrimary, width: 1),
              ),
            ),
            child: Column(
              children: options.asMap().entries.map((entry) {
                final i = entry.key;
                final option = entry.value;
                final isSelected = option == selected;
                final isLast = i == options.length - 1;
                return GestureDetector(
                  onTap: () => onSelect(option),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? BackgroundColors.bgActive
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(option,
                                      style: textMdMedium.copyWith(
                                        color: TextColors.textPrimary900,
                                      )),
                                ),
                                if (isSelected)
                                  Image.asset(
                                    'assets/icons/check.png',
                                    width: 16,
                                    height: 16,
                                    color: BackgroundColors.bgBrandSolid,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 14,
                          endIndent: 14,
                          color: BorderColors.borderSecondary,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
