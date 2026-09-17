import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_typography_tokens.dart';
import '../theme/light_mode_token.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'email_otp_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _rememberMe = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  bool _isSignUpPressed = false;

  // Live password validation
  String? _passwordError;
  bool _passwordTouched = false; // only show error after first submit attempt

  // ── Typography ──────────────────────────────────────────────────────────────
  static const _displaySmSemibold = TextStyle(
    fontFamily: AppTypographyTokens.displayFontFamily,
    fontSize: AppTypographyTokens.displaySm,
    fontWeight: AppTypographyTokens.semibold,
    height: AppTypographyTokens.displaySmHeight,
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
  static const _textSmMedium = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textSm,
    fontWeight: AppTypographyTokens.medium,
    height: AppTypographyTokens.textSmHeight,
  );
  static const _textSmRegular = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textSm,
    fontWeight: AppTypographyTokens.regular,
    height: AppTypographyTokens.textSmHeight,
  );

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Password validation ─────────────────────────────────────────────────────
  String? _validatePasswordLive(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Must contain at least one special character';
    }
    return null;
  }

  // ── Sign up ─────────────────────────────────────────────────────────────────
  Future<void> _signUp() async {
    // Mark password as touched so errors display
    setState(() {
      _passwordTouched = true;
      _passwordError = _validatePasswordLive(_passwordController.text);
    });

    if (_passwordError != null) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.createAccount(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user == null) throw Exception('Sign up failed');

      // Generate & store OTP; email delivery via Cloud Function
      await _authService.generateAndStoreOtp(
        user.uid,
        _emailController.text.trim(),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: _emailController.text.trim(),
              uid: user.uid,
              isSignUp: true, // → RoleSelectionScreen after OTP
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          msg = 'The email address is not valid.';
          break;
        case 'weak-password':
          msg = 'The password provided is too weak.';
          break;
        default:
          msg = e.message ?? 'An error occurred.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) => Text(
        text,
        style: _textSmMedium.copyWith(color: TextColors.textSecondary700),
      );

  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget label,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: BackgroundColors.bgBrandSolid,
            side: const BorderSide(color: BorderColors.borderPrimary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        label,
      ],
    );
  }

  // Shared border builder
  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final hasPasswordError = _passwordTouched && _passwordError != null;

    final emailBorderColor = _emailController.text.isNotEmpty
        ? BorderColors.borderBrand
        : BorderColors.borderPrimary;
    final passwordBorderColor = hasPasswordError
        ? BorderColors.borderErrorSubtle
        : (_passwordController.text.isNotEmpty
            ? BorderColors.borderBrand
            : BorderColors.borderPrimary);
    final confirmBorderColor = _confirmPasswordController.text.isNotEmpty
        ? BorderColors.borderBrand
        : BorderColors.borderPrimary;

    return Scaffold(
      backgroundColor: UtilityGrayColors.utilityGray50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
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

                // 24px — same as login screen
                const SizedBox(height: 24),

                // ── Heading ──────────────────────────────────────────────────
                Text(
                  'Sign up to your account',
                  style: _displaySmSemibold.copyWith(
                    color: TextColors.textPrimary900,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Subheading ───────────────────────────────────────────────
                Text(
                  'Please enter your details.',
                  style: _textMdRegular.copyWith(
                    color: TextColors.textTertiary600,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Email label ───────────────────────────────────────────────
                _buildLabel('Email'),
                const SizedBox(height: 6),

                // ── Email input ───────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: _textMdRegular.copyWith(color: TextColors.textPrimary900),
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: _textMdRegular.copyWith(color: TextColors.textPlaceholder),
                    filled: true,
                    fillColor: BackgroundColors.bgPrimary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: _border(BorderColors.borderPrimary),
                    enabledBorder: _border(emailBorderColor),
                    focusedBorder: _border(FocusRingColors.focusRing, width: 2),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Password label ────────────────────────────────────────────
                _buildLabel('Password'),
                const SizedBox(height: 6),

                // ── Password input ────────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: _textMdRegular.copyWith(color: TextColors.textPrimary900),
                  onChanged: (v) {
                    if (_passwordTouched) {
                      setState(() => _passwordError = _validatePasswordLive(v));
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: _textMdRegular.copyWith(color: TextColors.textPlaceholder),
                    filled: true,
                    fillColor: BackgroundColors.bgPrimary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    // Error icon inside field — mirrors Figma design
                    suffixIcon: hasPasswordError
                        ? const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.error_outline_rounded,
                              color: BorderColors.borderErrorSubtle,
                              size: 20,
                            ),
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(),
                    border: _border(BorderColors.borderPrimary),
                    enabledBorder: _border(passwordBorderColor),
                    focusedBorder: _border(
                      hasPasswordError
                          ? FocusRingColors.focusRingError
                          : FocusRingColors.focusRing,
                      width: 2,
                    ),
                    errorBorder: _border(BorderColors.borderErrorSubtle),
                    focusedErrorBorder:
                        _border(FocusRingColors.focusRingError, width: 2),
                  ),
                  // Suppress built-in validator error text — we render it ourselves
                  validator: (_) => null,
                ),

                // Error message — 6px gap, between field and show-password
                // "Show password" shifts down; everything below shifts too (minimal shift)
                if (hasPasswordError) ...[
                  const SizedBox(height: 6),
                  Text(
                    _passwordError!,
                    style: _textSmRegular.copyWith(
                      color: TextColors.textErrorPrimary600,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // ── Show password checkbox ────────────────────────────────────
                _buildCheckboxRow(
                  value: _showPassword,
                  onChanged: (v) => setState(() => _showPassword = v ?? false),
                  label: Text(
                    'Show password',
                    style: _textSmMedium.copyWith(
                      color: TextColors.textSecondary700,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Confirm Password label ────────────────────────────────────
                _buildLabel('Confirm Password'),
                const SizedBox(height: 6),

                // ── Confirm Password input ────────────────────────────────────
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  style: _textMdRegular.copyWith(color: TextColors.textPrimary900),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: _textMdRegular.copyWith(color: TextColors.textPlaceholder),
                    filled: true,
                    fillColor: BackgroundColors.bgPrimary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: _border(BorderColors.borderPrimary),
                    enabledBorder: _border(confirmBorderColor),
                    focusedBorder: _border(FocusRingColors.focusRing, width: 2),
                    errorBorder: _border(BorderColors.borderErrorSubtle),
                    focusedErrorBorder:
                        _border(FocusRingColors.focusRingError, width: 2),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // ── Show confirm password checkbox ────────────────────────────
                _buildCheckboxRow(
                  value: _showConfirmPassword,
                  onChanged: (v) =>
                      setState(() => _showConfirmPassword = v ?? false),
                  label: Text(
                    'Show password',
                    style: _textSmMedium.copyWith(
                      color: TextColors.textSecondary700,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Remember me ───────────────────────────────────────────────
                _buildCheckboxRow(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  label: Text(
                    'Remember me.',
                    style: _textSmMedium.copyWith(
                      color: TextColors.textSecondary700,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ── I agree to Terms & Conditions ─────────────────────────────
                _buildCheckboxRow(
                  value: _agreeTerms,
                  onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                  label: RichText(
                    text: TextSpan(
                      text: 'I agree to ',
                      style: _textSmMedium.copyWith(
                        color: TextColors.textSecondary700,
                      ),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () {
                              // TODO: open T&C page
                            },
                            child: Text(
                              'Terms & Conditions.',
                              style: _textSmMedium.copyWith(
                                color: TextColors.textBrandSecondary700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Sign Up button (skeuomorphic, same as login) ──────────────
                GestureDetector(
                  onTapDown: (_) => setState(() => _isSignUpPressed = true),
                  onTapUp: (_) => setState(() => _isSignUpPressed = false),
                  onTapCancel: () => setState(() => _isSignUpPressed = false),
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: ShapeDecoration(
                      color: BackgroundColors.bgBrandSolid,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          // Pressed → brand-tinted; idle → white highlight
                          color: _isSignUpPressed
                              ? const Color(0x29E04F16)
                              : const Color(0x29FFFFFF),
                          width: 2,
                        ),
                      ),
                      shadows: [
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
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: TextColors.textWhite,
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
                              'Sign up',
                              style: _textMdSemibold.copyWith(
                                color: TextColors.textWhite,
                                height: 1.0,
                              ),
                            ),
                    ),
                  ),
                ),

                // Divider between Sign Up and Google
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 348,
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: BorderColors.borderSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Sign in with Google ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Google Sign In
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: BackgroundColors.bgPrimary,
                      foregroundColor: TextColors.textSecondary700,
                      side: const BorderSide(color: BorderColors.borderPrimary),
                      elevation: 0,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logos/google-icon.png',
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sign in with Google',
                          style: _textMdSemibold.copyWith(
                            color: TextColors.textSecondary700,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Already have an account? ──────────────────────────────────
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: _textSmRegular.copyWith(
                        color: TextColors.textTertiary600,
                      ),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                            child: Text(
                              'Sign in',
                              style: _textSmRegular.copyWith(
                                color: TextColors.textBrandSecondary700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
