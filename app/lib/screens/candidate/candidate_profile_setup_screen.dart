import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_typography_tokens.dart';
import '../../theme/light_mode_token.dart';
import 'candidate_social_profiles_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Candidate Onboarding — Screen 1 "Build your profile"
// ─────────────────────────────────────────────────────────────────────────────

class CandidateProfileSetupScreen extends StatefulWidget {
  final String uid;
  const CandidateProfileSetupScreen({super.key, required this.uid});

  @override
  State<CandidateProfileSetupScreen> createState() =>
      _CandidateProfileSetupScreenState();
}

class _CandidateProfileSetupScreenState
    extends State<CandidateProfileSetupScreen> {
  // ── Controllers ─────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _oneLinerController = TextEditingController();
  final _locationController = TextEditingController();
  final _skillSearchController = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────
  final List<String> _selectedSkills = [];
  String? _selectedSalary;
  String? _profilePhotoPath; // local path of the picked photo (pre-upload)
  bool _skillsDropdownOpen = false;
  bool _salaryDropdownOpen = false;
  bool _isContinuePressed = false;
  bool _isLoading = false;

  // ── Data ─────────────────────────────────────────────────────────────────
  static const _allSkills = [
    'Web Designer',
    'Brand Designer',
    'Graphic Designer',
    'UI/UX Designer',
    'Frontend Developer',
    'Backend Developer',
    'Product Manager',
    'Marketing',
    'Copywriter',
    'Video Editor',
    'Content Writer',
    'Social Media',
    'SEO Specialist',
    'Data Analyst',
  ];

  static const _salaryOptions = [
    r'$0-25k',
    r'$25-60k',
    r'$60-100k',
    r'$100k-200k',
    r'$200k+',
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
    _nameController.addListener(() => setState(() {}));
    _oneLinerController.addListener(() => setState(() {}));
    _locationController.addListener(() => setState(() {}));
    _skillSearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oneLinerController.dispose();
    _locationController.dispose();
    _skillSearchController.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────
  bool get _canContinue =>
      _oneLinerController.text.trim().isNotEmpty &&
      _selectedSkills.isNotEmpty &&
      _locationController.text.trim().isNotEmpty &&
      _selectedSalary != null;

  // ── Filtered skills ───────────────────────────────────────────────────────
  List<String> get _filteredSkills {
    final q = _skillSearchController.text.toLowerCase();
    if (q.isEmpty) return _allSkills;
    return _allSkills.where((s) => s.toLowerCase().contains(q)).toList();
  }

  // ── Continue ──────────────────────────────────────────────────────────────
  Future<void> _onContinue() async {
    if (!_canContinue || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      // Upload the picked photo (if any) before persisting.
      String? photoUrl;
      if (_profilePhotoPath != null) {
        photoUrl = await _uploadProfilePhoto(_profilePhotoPath!);
      }

      // Persist the profile (merge so nothing else is clobbered).
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set({
            if (_nameController.text.trim().isNotEmpty)
              'name': _nameController.text.trim(),
            'profilePic': ?photoUrl,
            'profile': {
              'bio': _oneLinerController.text.trim(),
              'skills': _selectedSkills,
              'city': _locationController.text.trim(),
              'salaryRange': _selectedSalary,
            },
          }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CandidateSocialProfilesScreen(uid: widget.uid),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your profile. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Profile photo: pick from gallery ─────────────────────────────────────
  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _profilePhotoPath = picked.path);
  }

  // ── Profile photo: upload to Storage and return a public URL ─────────────
  Future<String> _uploadProfilePhoto(String localPath) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pics/${widget.uid}');
    await ref.putFile(File(localPath));
    return ref.getDownloadURL();
  }

  // ── Shared border builder ─────────────────────────────────────────────────
  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  // ── Section label + optional asterisk + optional info icon ────────────────
  Widget _label(String text, {bool required = false, bool info = false}) =>
      Row(
        children: [
          Text(
            required ? '$text *' : text,
            style: _textSmMedium,
          ),
          if (info) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: TextColors.textTertiary600,
            ),
          ],
        ],
      );

  // ── Helper text below field ───────────────────────────────────────────────
  Widget _helper(String text) =>
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text, style: _textSmRegular),
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Close dropdowns on outside tap
      onTap: () {
        if (_skillsDropdownOpen || _salaryDropdownOpen) {
          setState(() {
            _skillsDropdownOpen = false;
            _salaryDropdownOpen = false;
          });
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: UtilityGrayColors.utilityGray50,
        body: SafeArea(
          child: Column(
            children: [
              // ── Scrollable content ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/logos/Logomark-without-bg.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 24),

                      // ── Heading ───────────────────────────────────────────
                      const Text('Build your profile',
                          style: _displaySmSemibold),

                      const SizedBox(height: 24),

                      // ── Name ──────────────────────────────────────────────
                      _label('Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: _textMdRegular.copyWith(
                            color: TextColors.textPrimary900),
                        decoration: InputDecoration(
                          hintText: 'John Doe',
                          hintStyle: _textMdRegular.copyWith(
                              color: TextColors.textPlaceholder),
                          filled: true,
                          fillColor: BackgroundColors.bgPrimary,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: _border(BorderColors.borderPrimary),
                          enabledBorder: _border(
                            _nameController.text.isNotEmpty
                                ? BorderColors.borderBrand
                                : BorderColors.borderPrimary,
                          ),
                          focusedBorder:
                              _border(FocusRingColors.focusRing, width: 2),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── One Liner ─────────────────────────────────────────
                      _label('One Liner', required: true, info: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _oneLinerController,
                        maxLines: 4,
                        minLines: 3,
                        style: _textMdRegular.copyWith(
                            color: TextColors.textPrimary900),
                        decoration: InputDecoration(
                          hintText: 'Web, UX & Brand Designer...',
                          hintStyle: _textMdRegular.copyWith(
                              color: TextColors.textPlaceholder),
                          filled: true,
                          fillColor: BackgroundColors.bgPrimary,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: _border(BorderColors.borderPrimary),
                          enabledBorder: _border(
                            _oneLinerController.text.isNotEmpty
                                ? BorderColors.borderBrand
                                : BorderColors.borderPrimary,
                          ),
                          focusedBorder:
                              _border(FocusRingColors.focusRing, width: 2),
                        ),
                      ),
                      _helper('Highlight your creative focus.'),

                      const SizedBox(height: 20),

                      // ── Skills ────────────────────────────────────────────
                      _label('Skills', required: true),
                      const SizedBox(height: 6),
                      _SkillsField(
                        selectedSkills: _selectedSkills,
                        searchController: _skillSearchController,
                        filteredSkills: _filteredSkills,
                        isOpen: _skillsDropdownOpen,
                        onTriggerTap: () => setState(() {
                          _skillsDropdownOpen = !_skillsDropdownOpen;
                          _salaryDropdownOpen = false;
                        }),
                        onSkillToggle: (skill) => setState(() {
                          if (_selectedSkills.contains(skill)) {
                            _selectedSkills.remove(skill);
                          } else {
                            _selectedSkills.add(skill);
                          }
                        }),
                        onSkillRemove: (skill) =>
                            setState(() => _selectedSkills.remove(skill)),
                        textMdMedium: _textMdMedium,
                        textSmMedium: _textSmMedium,
                      ),

                      const SizedBox(height: 20),

                      // ── Location ──────────────────────────────────────────
                      _label('Location', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _locationController,
                        style: _textMdRegular.copyWith(
                            color: TextColors.textPrimary900),
                        decoration: InputDecoration(
                          hintText: 'City, State, Country',
                          hintStyle: _textMdRegular.copyWith(
                              color: TextColors.textPlaceholder),
                          filled: true,
                          fillColor: BackgroundColors.bgPrimary,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: _border(BorderColors.borderPrimary),
                          enabledBorder: _border(
                            _locationController.text.isNotEmpty
                                ? BorderColors.borderBrand
                                : BorderColors.borderPrimary,
                          ),
                          focusedBorder:
                              _border(FocusRingColors.focusRing, width: 2),
                        ),
                      ),
                      _helper('Where do you live?'),

                      const SizedBox(height: 20),

                      // ── Salary Range ──────────────────────────────────────
                      _label('Set expected salary range.', required: true),
                      const SizedBox(height: 6),
                      _SalaryDropdown(
                        selectedValue: _selectedSalary,
                        options: _salaryOptions,
                        isOpen: _salaryDropdownOpen,
                        onTriggerTap: () => setState(() {
                          _salaryDropdownOpen = !_salaryDropdownOpen;
                          _skillsDropdownOpen = false;
                          FocusScope.of(context).unfocus();
                        }),
                        onSelect: (v) => setState(() {
                          _selectedSalary = v;
                          _salaryDropdownOpen = false;
                        }),
                        textMdMedium: _textMdMedium,
                      ),

                      const SizedBox(height: 20),

                      // ── Profile Photo ─────────────────────────────────────
                      _label('Profile Photo'),
                      const SizedBox(height: 6),
                      _ProfilePhotoUpload(
                        previewPath: _profilePhotoPath,
                        onTap: _pickProfilePhoto,
                        onRemove: () =>
                            setState(() => _profilePhotoPath = null),
                        textSmRegular: _textSmRegular,
                        textXsRegular: _textXsRegular,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── Continue button — pinned at bottom ────────────────────────
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skills field — searchable multi-select with chips
// ─────────────────────────────────────────────────────────────────────────────

class _SkillsField extends StatelessWidget {
  final List<String> selectedSkills;
  final TextEditingController searchController;
  final List<String> filteredSkills;
  final bool isOpen;
  final VoidCallback onTriggerTap;
  final ValueChanged<String> onSkillToggle;
  final ValueChanged<String> onSkillRemove;
  final TextStyle textMdMedium;
  final TextStyle textSmMedium;

  const _SkillsField({
    required this.selectedSkills,
    required this.searchController,
    required this.filteredSkills,
    required this.isOpen,
    required this.onTriggerTap,
    required this.onSkillToggle,
    required this.onSkillRemove,
    required this.textMdMedium,
    required this.textSmMedium,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Trigger ─────────────────────────────────────────────────────
        GestureDetector(
          onTap: onTriggerTap,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 44),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: BackgroundColors.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOpen || selectedSkills.isNotEmpty
                    ? BorderColors.borderBrand
                    : BorderColors.borderPrimary,
                width: isOpen ? 2 : 1,
              ),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search icon from assets
                Image.asset(
                  'assets/icons/search.png',
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                  color: TextColors.textTertiary600,
                ),
                // Selected skill chips
                ...selectedSkills.map(
                  (skill) => _SkillChip(
                    label: skill,
                    onRemove: () => onSkillRemove(skill),
                  ),
                ),
                // Search input (shown inline)
                if (isOpen)
                  SizedBox(
                    width: 100,
                    height: 24,
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      style: const TextStyle(
                        fontFamily: AppTypographyTokens.bodyFontFamily,
                        fontSize: AppTypographyTokens.textSm,
                        fontWeight: AppTypographyTokens.regular,
                        color: TextColors.textPrimary900,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          fontSize: AppTypographyTokens.textSm,
                          color: TextColors.textPlaceholder,
                        ),
                      ),
                    ),
                  )
                else if (selectedSkills.isEmpty)
                  Text(
                    'Select skills',
                    style: TextStyle(
                      fontFamily: AppTypographyTokens.bodyFontFamily,
                      fontSize: AppTypographyTokens.textMd,
                      fontWeight: AppTypographyTokens.medium,
                      color: TextColors.textPlaceholder,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Options panel ─────────────────────────────────────────────────
        if (isOpen) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: BackgroundColors.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BorderColors.borderPrimary),
              boxShadow: [
                BoxShadow(
                  color: ShadowColors.shadowSm01,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: filteredSkills.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'No skills found',
                          style: textSmMedium.copyWith(
                            color: TextColors.textTertiary600,
                          ),
                        ),
                      ),
                    ]
                  : filteredSkills.asMap().entries.map((entry) {
                      final i = entry.key;
                      final skill = entry.value;
                      final isSelected = selectedSkills.contains(skill);
                      final isLast = i == filteredSkills.length - 1;
                      return _SkillOption(
                        label: skill,
                        isSelected: isSelected,
                        isLast: isLast,
                        onTap: () => onSkillToggle(skill),
                      );
                    }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Skill chip inside trigger ─────────────────────────────────────────────────

class _SkillChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _SkillChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: BackgroundColors.bgPrimary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: BorderColors.borderPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small category dot
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: BackgroundColors.bgBrandSolid,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypographyTokens.bodyFontFamily,
              fontSize: AppTypographyTokens.textSm,
              fontWeight: AppTypographyTokens.medium,
              color: TextColors.textSecondary700,
            ),
          ),
          const SizedBox(width: 5),
          // × remove
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 12,
              color: TextColors.textTertiary600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skill option row in panel ─────────────────────────────────────────────────

class _SkillOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;

  const _SkillOption({
    required this.label,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Inset padding so bgActive doesn't span full panel width
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontFamily: AppTypographyTokens.bodyFontFamily,
                          fontSize: AppTypographyTokens.textMd,
                          fontWeight: AppTypographyTokens.medium,
                          height: AppTypographyTokens.textMdHeight,
                          color: TextColors.textPrimary900,
                        ),
                      ),
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Salary dropdown — single select
// ─────────────────────────────────────────────────────────────────────────────

class _SalaryDropdown extends StatelessWidget {
  final String? selectedValue;
  final List<String> options;
  final bool isOpen;
  final VoidCallback onTriggerTap;
  final ValueChanged<String> onSelect;
  final TextStyle textMdMedium;

  const _SalaryDropdown({
    required this.selectedValue,
    required this.options,
    required this.isOpen,
    required this.onTriggerTap,
    required this.onSelect,
    required this.textMdMedium,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedValue != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Trigger ───────────────────────────────────────────────────────
        GestureDetector(
          onTap: onTriggerTap,
          child: Container(
            width: double.infinity,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: BackgroundColors.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOpen || hasSelection
                    ? BorderColors.borderBrand
                    : BorderColors.borderPrimary,
                width: isOpen ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedValue ?? 'Select salary range',
                    style: textMdMedium.copyWith(
                      color: hasSelection
                          ? TextColors.textPrimary900
                          : TextColors.textPlaceholder,
                    ),
                  ),
                ),
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: TextColors.textPrimary900,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // ── Options panel ─────────────────────────────────────────────────
        if (isOpen) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: BackgroundColors.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BorderColors.borderPrimary),
              boxShadow: [
                BoxShadow(
                  color: ShadowColors.shadowSm01,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.asMap().entries.map((entry) {
                final i = entry.key;
                final option = entry.value;
                final isSelected = option == selectedValue;
                final isLast = i == options.length - 1;
                return GestureDetector(
                  onTap: () => onSelect(option),
                  child: Column(
                    children: [
                      // Inset bgActive — doesn't span full panel width
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
                                  child: Text(
                                    option,
                                    style: const TextStyle(
                                      fontFamily:
                                          AppTypographyTokens.bodyFontFamily,
                                      fontSize: AppTypographyTokens.textMd,
                                      fontWeight: AppTypographyTokens.medium,
                                      height: AppTypographyTokens.textMdHeight,
                                      color: TextColors.textPrimary900,
                                    ),
                                  ),
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
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile photo upload zone (empty state) / preview (picked state)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfilePhotoUpload extends StatelessWidget {
  final String? previewPath;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final TextStyle textSmRegular;
  final TextStyle textXsRegular;

  const _ProfilePhotoUpload({
    required this.previewPath,
    required this.onTap,
    required this.onRemove,
    required this.textSmRegular,
    required this.textXsRegular,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = previewPath != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(hasPhoto ? 12 : 20),
        decoration: BoxDecoration(
          color: BackgroundColors.bgPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasPhoto
                ? BorderColors.borderBrand
                : BorderColors.borderSecondary,
          ),
        ),
        child: hasPhoto
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(previewPath!),
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap to change',
                        style: textSmRegular.copyWith(
                          fontWeight: AppTypographyTokens.semibold,
                          color: TextColors.textBrandSecondary700,
                        ),
                      ),
                      GestureDetector(
                        onTap: onRemove,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: TextColors.textTertiary600,
                            ),
                            const SizedBox(width: 4),
                            Text('Remove', style: textXsRegular),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Upload icon — no color param so actual asset shows
                  Image.asset(
                    'assets/icons/upload.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 8),

                  // "Click to upload or drag and drop"
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
                          style: textSmRegular,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // File spec
                  Text(
                    'SVG, PNG, JPG or GIF (max. 800×400px)',
                    style: textXsRegular,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}
