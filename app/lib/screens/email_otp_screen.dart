import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_typography_tokens.dart';
import '../theme/light_mode_token.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'role_selection_screen.dart';

class EmailOtpScreen extends StatefulWidget {
  final String email;
  final String uid;
  /// true = came from sign-up → go to RoleSelectionScreen after verify
  /// false = came from login  → go to AuthGate after verify
  final bool isSignUp;

  const EmailOtpScreen({
    super.key,
    required this.email,
    required this.uid,
    this.isSignUp = false,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final _authService = AuthService();
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(4, (_) => FocusNode());

  bool _isVerifying = false;

  bool get _isComplete =>
      _controllers.every((c) => c.text.isNotEmpty);

  @override
  void initState() {
    super.initState();
    // Rebuild on every keystroke so button and border colors react
    for (final c in _controllers) {
      c.addListener(() => setState(() {}));
    }
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNodes[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onDigitEntered(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    // Auto-submit when last box is filled
    if (index == 3 && value.isNotEmpty) _verify();
  }

  Future<void> _resendCode() async {
    try {
      await _authService.generateAndStoreOtp(widget.uid, widget.email);
      await _authService.sendOtpEmail(widget.email);
      // Clear all boxes
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent to your email.')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Could not resend code. Try again.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not resend code. Try again.')),
        );
      }
    }
  }

  Future<void> _verify() async {
    if (!_isComplete || _isVerifying) return;
    setState(() => _isVerifying = true);

    final entered = _controllers.map((c) => c.text).join();

    try {
      final valid = await _authService.verifyOtp(widget.uid, entered);
      if (!mounted) return;

      if (valid) {
        if (widget.isSignUp) {
          // New user → pick a role
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => RoleSelectionScreen(uid: widget.uid),
            ),
            (_) => false,
          );
        } else {
          // Returning user → home
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthGate()),
            (_) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or expired code. Please try again.'),
          ),
        );
        for (final c in _controllers) c.clear();
        _focusNodes[0].requestFocus();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Available width minus 24+24 padding, minus 3×12 gaps → divide by 4
    final boxWidth = (screenWidth - 48 - 36) / 4;
    const boxHeight = 80.0;

    return Scaffold(
      backgroundColor: UtilityGrayColors.utilityGray50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logomark ────────────────────────────────────────────────
              Image.asset(
                'assets/logos/Logomark-without-bg.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),

              // 24px — same gap as login screen logo → heading
              const SizedBox(height: 24),

              // ── Heading ─────────────────────────────────────────────────
              // display-sm / semibold / text-primary900
              const Text(
                'We emailed you a code',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.displayFontFamily,
                  fontSize: AppTypographyTokens.displaySm,
                  fontWeight: AppTypographyTokens.semibold,
                  height: AppTypographyTokens.displaySmHeight,
                  color: TextColors.textPrimary900,
                ),
              ),

              const SizedBox(height: 4),

              // ── Subtext line 1 ───────────────────────────────────────────
              // text-md / regular / text-tertiary600
              const Text(
                'Enter verification code sent to:',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.bodyFontFamily,
                  fontSize: AppTypographyTokens.textMd,
                  fontWeight: AppTypographyTokens.regular,
                  height: AppTypographyTokens.textMdHeight,
                  color: TextColors.textTertiary600,
                ),
              ),

              // ── Email address ────────────────────────────────────────────
              // text-md / regular / text-tertiary600
              Text(
                widget.email,
                style: const TextStyle(
                  fontFamily: AppTypographyTokens.bodyFontFamily,
                  fontSize: AppTypographyTokens.textMd,
                  fontWeight: AppTypographyTokens.regular,
                  height: AppTypographyTokens.textMdHeight,
                  color: TextColors.textTertiary600,
                ),
              ),

              // 32px between email address and "Secure code" label
              const SizedBox(height: 32),

              // ── "Secure code" label ──────────────────────────────────────
              // text-sm / medium / text-secondary700
              const Text(
                'Secure code',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.bodyFontFamily,
                  fontSize: AppTypographyTokens.textSm,
                  fontWeight: AppTypographyTokens.medium,
                  height: AppTypographyTokens.textSmHeight,
                  color: TextColors.textSecondary700,
                ),
              ),

              // 6px between label and boxes
              const SizedBox(height: 6),

              // ── OTP boxes ────────────────────────────────────────────────
              Row(
                children: List.generate(4, (i) {
                  final isFilled = _controllers[i].text.isNotEmpty;
                  return Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 12.0 : 0),
                    child: _OtpBox(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      prevFocusNode: i > 0 ? _focusNodes[i - 1] : null,
                      width: boxWidth,
                      height: boxHeight,
                      isFilled: isFilled,
                      onChanged: (v) => _onDigitEntered(i, v),
                    ),
                  );
                }),
              ),

              // 12px between boxes and "Resend code"
              const SizedBox(height: 12),

              // ── Resend code ──────────────────────────────────────────────
              // text-sm / semibold / text-brand-secondary700
              GestureDetector(
                onTap: _resendCode,
                child: const Text(
                  'Resend code',
                  style: TextStyle(
                    fontFamily: AppTypographyTokens.bodyFontFamily,
                    fontSize: AppTypographyTokens.textSm,
                    fontWeight: AppTypographyTokens.semibold,
                    height: AppTypographyTokens.textSmHeight,
                    color: TextColors.textBrandSecondary700,
                  ),
                ),
              ),

              // Push Continue button to bottom
              const Spacer(),

              // ── Continue button: 380×44 ──────────────────────────────────
              // Disabled: bg-disabled / fg-disabled
              // Active:   bg-brand-solid / text-white
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: (_isComplete && !_isVerifying) ? _verify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isComplete
                        ? BackgroundColors.bgBrandSolid
                        : BackgroundColors.bgDisabled,
                    foregroundColor: _isComplete
                        ? TextColors.textWhite
                        : ForegroundColors.fgDisabled,
                    disabledBackgroundColor: BackgroundColors.bgDisabled,
                    disabledForegroundColor: ForegroundColors.fgDisabled,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isVerifying
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
                          style: TextStyle(
                            fontFamily: AppTypographyTokens.bodyFontFamily,
                            fontSize: AppTypographyTokens.textMd,
                            fontWeight: AppTypographyTokens.semibold,
                            color: _isComplete
                                ? TextColors.textWhite
                                : ForegroundColors.fgDisabled,
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

// ── Individual OTP input box ─────────────────────────────────────────────────

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? prevFocusNode;
  final double width;
  final double height;
  final bool isFilled;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    this.prevFocusNode,
    required this.width,
    required this.height,
    required this.isFilled,
    required this.onChanged,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  Color get _borderColor {
    if (_isFocused || widget.isFilled) return BorderColors.borderBrand;
    return BorderColors.borderPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            widget.controller.text.isEmpty &&
            widget.prevFocusNode != null) {
          widget.prevFocusNode!.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: BackgroundColors.bgPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor, width: 2),
        ),
        child: Stack(
          children: [
            // ── Transparent TextField: captures keyboard input ────────────
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  keyboardType: TextInputType.number,
                  showCursor: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
            ),

            // ── Centered Text: guaranteed pixel-perfect centering ─────────
            Center(
              child: Text(
                widget.controller.text.isEmpty ? '0' : widget.controller.text,
                style: TextStyle(
                  fontFamily: AppTypographyTokens.displayFontFamily,
                  fontSize: AppTypographyTokens.displayLg,
                  fontWeight: AppTypographyTokens.medium,
                  color: widget.isFilled
                      ? TextColors.textBrandTertiaryAlt
                      : TextColors.textPlaceholderSubtle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
