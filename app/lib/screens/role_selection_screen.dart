import 'package:flutter/material.dart';

import '../theme/app_typography_tokens.dart';
import '../theme/light_mode_token.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'candidate/candidate_profile_setup_screen.dart';
import 'employer/employer_profile_setup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String uid;
  const RoleSelectionScreen({super.key, required this.uid});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _authService = AuthService();

  // null = nothing chosen yet
  String? _selectedRole; // 'candidate' | 'employer'
  bool _dropdownOpen = false;
  bool _isContinuePressed = false;
  bool _isLoading = false;

  static const _options = [
    _RoleOption(label: 'Seeking Job', value: 'candidate'),
    _RoleOption(label: 'Hiring', value: 'employer'),
  ];

  // ── Typography (same tokens as other screens) ────────────────────────────
  static const _displaySmSemibold = TextStyle(
    fontFamily: AppTypographyTokens.displayFontFamily,
    fontSize: AppTypographyTokens.displaySm,
    fontWeight: AppTypographyTokens.semibold,
    height: AppTypographyTokens.displaySmHeight,
    color: TextColors.textPrimary900,
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

  Future<void> _continue() async {
    if (_selectedRole == null || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _authService.setUserRole(widget.uid, _selectedRole!);
      if (mounted) {
        if (_selectedRole == 'candidate') {
          // Candidate → build profile onboarding
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CandidateProfileSetupScreen(uid: widget.uid),
            ),
            (_) => false,
          );
        } else {
          // Employer → build org profile onboarding
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EmployerProfileSetupScreen(uid: widget.uid),
            ),
            (_) => false,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save role. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _dropdownLabel =>
      _selectedRole == null
          ? 'Select Role'
          : _options.firstWhere((o) => o.value == _selectedRole).label;

  @override
  Widget build(BuildContext context) {
    final isReady = _selectedRole != null;

    return Scaffold(
      backgroundColor: UtilityGrayColors.utilityGray50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo ─────────────────────────────────────────────────────
              Image.asset(
                'assets/logos/Logomark-without-bg.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 24),

              // ── Heading — same typography as "Log in to your account" ────
              const Text(
                'Which one best describes you?',
                style: _displaySmSemibold,
              ),

              const SizedBox(height: 24),

              // ── Custom dropdown ───────────────────────────────────────────
              _DropdownField(
                label: _dropdownLabel,
                isOpen: _dropdownOpen,
                isPlaceholder: _selectedRole == null,
                onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
              ),

              // 6px between dropdown trigger and the options panel
              if (_dropdownOpen) ...[
                const SizedBox(height: 6),
                _DropdownPanel(
                  options: _options,
                  selectedValue: _selectedRole,
                  onSelect: (value) => setState(() {
                    _selectedRole = value;
                    _dropdownOpen = false;
                  }),
                ),
              ],

              // Push Continue to bottom
              const Spacer(),

              // ── Continue button ───────────────────────────────────────────
              GestureDetector(
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
                    color: isReady
                        ? BackgroundColors.bgBrandSolid
                        : BackgroundColors.bgDisabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isReady
                            ? (_isContinuePressed
                                ? const Color(0x29E04F16)
                                : const Color(0x29FFFFFF))
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    shadows: isReady
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
                              offset: Offset.zero,
                            ),
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: (isReady && !_isLoading) ? _continue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: isReady
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
                              color: isReady
                                  ? TextColors.textWhite
                                  : ForegroundColors.fgDisabled,
                              height: 1.0,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role option data class ────────────────────────────────────────────────────

class _RoleOption {
  final String label;
  final String value;
  const _RoleOption({required this.label, required this.value});
}

// ── Dropdown trigger field ────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label;
  final bool isOpen;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const _DropdownField({
    required this.label,
    required this.isOpen,
    required this.isPlaceholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: BackgroundColors.bgPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            // Brand border when open, primary otherwise
            color: isOpen ? BorderColors.borderBrand : BorderColors.borderPrimary,
            width: isOpen ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypographyTokens.bodyFontFamily,
                  fontSize: AppTypographyTokens.textMd,
                  fontWeight: AppTypographyTokens.medium,
                  height: AppTypographyTokens.textMdHeight,
                  // Placeholder uses textPlaceholder; selected uses textPrimary900
                  color: isPlaceholder
                      ? TextColors.textPlaceholder
                      : TextColors.textPrimary900,
                ),
              ),
            ),
            // Chevron down
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: TextColors.textPrimary900,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dropdown options panel ────────────────────────────────────────────────────

class _DropdownPanel extends StatelessWidget {
  final List<_RoleOption> options;
  final String? selectedValue;
  final ValueChanged<String> onSelect;

  const _DropdownPanel({
    required this.options,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: options.map((opt) {
          final isSelected = opt.value == selectedValue;
          return _DropdownOption(
            option: opt,
            isSelected: isSelected,
            onTap: () => onSelect(opt.value),
            isLast: opt == options.last,
          );
        }).toList(),
      ),
    );
  }
}

// ── Individual option row ─────────────────────────────────────────────────────

class _DropdownOption extends StatelessWidget {
  final _RoleOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLast;

  const _DropdownOption({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Inset padding — bgActive doesn't span full panel width
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
                    horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.label,
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
