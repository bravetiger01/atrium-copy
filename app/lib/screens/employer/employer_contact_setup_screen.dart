import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_typography_tokens.dart';
import '../../theme/light_mode_token.dart';
import '../../main.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Employer Onboarding — Screen 2 "What do you do at your @Company"
// ─────────────────────────────────────────────────────────────────────────────

class EmployerContactSetupScreen extends StatefulWidget {
  final String uid;
  final String orgName;
  final Map<String, String> orgData; // passed from screen 1

  const EmployerContactSetupScreen({
    super.key,
    required this.uid,
    required this.orgName,
    required this.orgData,
  });

  @override
  State<EmployerContactSetupScreen> createState() =>
      _EmployerContactSetupScreenState();
}

class _EmployerContactSetupScreenState
    extends State<EmployerContactSetupScreen> {
  // ── Controllers ─────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _companyUrlController = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────
  String _countryCode = 'US';
  String _dialCode = '+1';
  bool _countryDropdownOpen = false;
  bool _isContinuePressed = false;
  bool _isLoading = false;

  static const _countryCodes = [
    {'code': 'US', 'dial': '+1',   'flag': '🇺🇸', 'placeholder': '(555) 000-0000'},
    {'code': 'IN', 'dial': '+91',  'flag': '🇮🇳', 'placeholder': '98765 43210'},
    {'code': 'GB', 'dial': '+44',  'flag': '🇬🇧', 'placeholder': '07700 900000'},
    {'code': 'CA', 'dial': '+1',   'flag': '🇨🇦', 'placeholder': '(555) 000-0000'},
    {'code': 'AU', 'dial': '+61',  'flag': '🇦🇺', 'placeholder': '0400 000 000'},
    {'code': 'SG', 'dial': '+65',  'flag': '🇸🇬', 'placeholder': '8123 4567'},
    {'code': 'AE', 'dial': '+971', 'flag': '🇦🇪', 'placeholder': '050 000 0000'},
  ];

  /// Returns the placeholder for the currently selected country.
  String get _phonePlaceholder {
    final country = _countryCodes
        .firstWhere((c) => c['code'] == _countryCode,
            orElse: () => _countryCodes.first);
    return country['placeholder']!;
  }

  // ── Typography ────────────────────────────────────────────────────────────
  static const _textSmMedium = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textSm,
    fontWeight: AppTypographyTokens.medium,
    height: AppTypographyTokens.textSmHeight,
    color: TextColors.textSecondary700,
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

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _titleController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _linkedInController.addListener(() => setState(() {}));
    _companyUrlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _linkedInController.dispose();
    _companyUrlController.dispose();
    super.dispose();
  }

  // ── Validation — required: Name, Title, Phone ────────────────────────────
  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty &&
      _titleController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty;

  // ── Persist everything to Firestore ──────────────────────────────────────
  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .set({
      'profile': {
        ...widget.orgData,
        'contactName': _nameController.text.trim(),
        'professionalTitle': _titleController.text.trim(),
        'phone': '$_dialCode ${_phoneController.text.trim()}',
        if (_linkedInController.text.trim().isNotEmpty)
          'linkedinUrl': _linkedInController.text.trim(),
        if (_companyUrlController.text.trim().isNotEmpty)
          'companyUrl': _companyUrlController.text.trim(),
      },
      'onboardingDone': true,
    }, SetOptions(merge: true));
  }

  Future<void> _onContinue() async {
    if (!_canContinue || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _save();
    } catch (e) {
      debugPrint('Failed to save employer data: $e');
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

  Widget _urlField({
    required TextEditingController controller,
    required String hint,
  }) {
    final hasContent = controller.text.isNotEmpty;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.url,
      style: _textMdMedium,
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
    final selectedCountry = _countryCodes
        .firstWhere((c) => c['code'] == _countryCode, orElse: () => _countryCodes.first);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_countryDropdownOpen) setState(() => _countryDropdownOpen = false);
      },
      child: Scaffold(
        backgroundColor: UtilityGrayColors.utilityGray50,
        body: SafeArea(
          child: Column(
            children: [
              // ── Scrollable body ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Logo ────────────────────────────────────────────
                      Image.asset(
                        'assets/logos/Logomark-without-bg.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 24),

                      // ── Heading ─────────────────────────────────────────
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'What do you do ',
                              style: TextStyle(
                                fontFamily:
                                    AppTypographyTokens.displayFontFamily,
                                fontSize: AppTypographyTokens.displaySm,
                                fontWeight: AppTypographyTokens.semibold,
                                height: AppTypographyTokens.displaySmHeight,
                                color: TextColors.textPrimary900,
                              ),
                            ),
                            TextSpan(
                              text: '@${widget.orgName}',
                              style: const TextStyle(
                                fontFamily:
                                    AppTypographyTokens.displayFontFamily,
                                fontSize: AppTypographyTokens.displaySm,
                                fontWeight: AppTypographyTokens.semibold,
                                height: AppTypographyTokens.displaySmHeight,
                                color: TextColors.textPrimary900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Your Name * ─────────────────────────────────────
                      _label('Your Name', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: _textMdMedium,
                        decoration: InputDecoration(
                          hintText: 'John doe',
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

                      // ── Professional Title * ────────────────────────────
                      _label('Professional Title', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        style: _textMdMedium,
                        decoration: InputDecoration(
                          hintText: 'Hiring Manager',
                          hintStyle: _textMdRegular.copyWith(
                              color: TextColors.textPlaceholder),
                          filled: true,
                          fillColor: BackgroundColors.bgPrimary,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: _border(BorderColors.borderPrimary),
                          enabledBorder: _border(
                            _titleController.text.isNotEmpty
                                ? BorderColors.borderBrand
                                : BorderColors.borderPrimary,
                          ),
                          focusedBorder:
                              _border(FocusRingColors.focusRing, width: 2),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Your Business Phone no. * ───────────────────────
                      _label('Your Business Phone no.', required: true),
                      const SizedBox(height: 6),

                      // Phone row with country code selector
                      Container(
                        decoration: BoxDecoration(
                          color: BackgroundColors.bgPrimary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _phoneController.text.isNotEmpty
                                ? BorderColors.borderBrand
                                : BorderColors.borderPrimary,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Country code picker
                            GestureDetector(
                              onTap: () => setState(() =>
                                  _countryDropdownOpen = !_countryDropdownOpen),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                        color: BorderColors.borderPrimary),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _countryCode,
                                      style: _textMdMedium,
                                    ),
                                    const SizedBox(width: 4),
                                    AnimatedRotation(
                                      turns: _countryDropdownOpen ? 0.5 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: TextColors.textSecondary700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Dial code label
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                _dialCode,
                                style: _textMdMedium.copyWith(
                                    color: TextColors.textTertiary600),
                              ),
                            ),
                            // Phone input
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: _textMdMedium,
                                decoration: InputDecoration(
                                  hintText: _phonePlaceholder,
                                  hintStyle: _textMdRegular.copyWith(
                                      color: TextColors.textPlaceholder),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Country code dropdown overlay
                      if (_countryDropdownOpen)
                        Container(
                          decoration: BoxDecoration(
                            color: BackgroundColors.bgPrimary,
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(8)),
                            border: Border(
                              left: BorderSide(
                                  color: BorderColors.borderPrimary),
                              right: BorderSide(
                                  color: BorderColors.borderPrimary),
                              bottom: BorderSide(
                                  color: BorderColors.borderPrimary),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ShadowColors.shadowXs,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: _countryCodes.asMap().entries.map((e) {
                              final i = e.key;
                              final c = e.value;
                              final isSelected = c['code'] == _countryCode;
                              final isLast =
                                  i == _countryCodes.length - 1;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _countryCode = c['code']!;
                                    _dialCode = c['dial']!;
                                    _countryDropdownOpen = false;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 120),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? BackgroundColors.bgActive
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 10),
                                          child: Row(
                                            children: [
                                              Text(c['flag']!,
                                                  style: const TextStyle(
                                                      fontSize: 16)),
                                              const SizedBox(width: 10),
                                              Text(c['code']!,
                                                  style: _textMdMedium.copyWith(
                                                      color: TextColors
                                                          .textPrimary900)),
                                              const SizedBox(width: 6),
                                              Text(c['dial']!,
                                                  style: _textMdRegular.copyWith(
                                                      color: TextColors
                                                          .textTertiary600)),
                                              const Spacer(),
                                              if (isSelected)
                                                Image.asset(
                                                  'assets/icons/check.png',
                                                  width: 16,
                                                  height: 16,
                                                  color: BackgroundColors
                                                      .bgBrandSolid,
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

                      const SizedBox(height: 20),

                      // ── LinkedIn URL ─────────────────────────────────────
                      _label('LinkedIn URL'),
                      const SizedBox(height: 6),
                      _urlField(
                        controller: _linkedInController,
                        hint: 'https://www.linkedin.com/company/',
                      ),

                      const SizedBox(height: 20),

                      // ── Company URL ──────────────────────────────────────
                      _label('Company URL'),
                      const SizedBox(height: 6),
                      _urlField(
                        controller: _companyUrlController,
                        hint: 'https://www.company.link',
                      ),

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
