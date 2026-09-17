import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/app_typography_tokens.dart';
import '../theme/light_mode_token.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'signup_screen.dart';
import 'email_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSignInPressed = false;

  // 0 = Sign up tab, 1 = Log in tab
  int _activeTab = 1;

  @override
  void initState() {
    super.initState();
    // Rebuild on every keystroke so border color reacts to content
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user == null) throw Exception('Sign in failed');

      // Generate OTP, store in Firestore, then email it via Cloud Function.
      await _authService.generateAndStoreOtp(
        user.uid,
        _emailController.text.trim(),
      );
      await _authService.sendOtpEmail(_emailController.text.trim());

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: _emailController.text.trim(),
              uid: user.uid,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'An error occurred')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Could not send your code. Try again.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      // User cancelled the Google account picker — do nothing.
      if (user == null) return;
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
      }
    } on GoogleSignInException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.description ?? 'Google sign-in failed. Try again.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Google sign-in failed. Try again.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Text style helpers (all from AppTypographyTokens) ──────────────────────

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
    // no height multiplier — avoids clipping inside fixed-height buttons
  );

  static const _textSmMedium = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textSm,
    fontWeight: AppTypographyTokens.medium,
    height: AppTypographyTokens.textSmHeight,
  );

  static const _textSmSemibold = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textSm,
    fontWeight: AppTypographyTokens.semibold,
    height: AppTypographyTokens.textSmHeight,
  );

  static const _textSmRegular = TextStyle(
    fontFamily: AppTypographyTokens.bodyFontFamily,
    fontSize: AppTypographyTokens.textSm,
    fontWeight: AppTypographyTokens.regular,
    height: AppTypographyTokens.textSmHeight,
  );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // bg: utility-gray-50 = #FAFAFA
      backgroundColor: UtilityGrayColors.utilityGray50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logomark ────────────────────────────────────────────────
                Image.asset(
                  'assets/logos/Logomark-without-bg.png',
                  // exported at 10x — display at 40×40 logical pts
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),

                // 24px gap between logo and heading
                const SizedBox(height: 24),

                // ── Heading ─────────────────────────────────────────────────
                // display-sm / semibold / text-primary900
                Text(
                  'Log in to your account',
                  style: _displaySmSemibold.copyWith(
                    color: TextColors.textPrimary900,
                  ),
                ),

                const SizedBox(height: 4),

                // ── Subheading ───────────────────────────────────────────────
                // text-md / regular / text-tertiary600
                Text(
                  'Welcome back! Please enter your details.',
                  style: _textMdRegular.copyWith(
                    color: TextColors.textTertiary600,
                  ),
                ),

                // 32px gap between switch and email field
                const SizedBox(height: 32),

                // ── Email label ──────────────────────────────────────────────
                // text-md / medium / text-secondary700
                Text(
                  'Email',
                  style: _textMdMedium.copyWith(
                    color: TextColors.textSecondary700,
                  ),
                ),

                const SizedBox(height: 6),

                // ── Email field ──────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  // typed text: text-md / Regular
                  style: _textMdRegular.copyWith(
                    color: TextColors.textPrimary900,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: _textMdMedium.copyWith(
                      color: TextColors.textPlaceholder,
                    ),
                    filled: true,
                    fillColor: BackgroundColors.bgPrimary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: BorderColors.borderPrimary),
                    ),
                    // Brand border when content present, primary otherwise
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _emailController.text.isNotEmpty
                            ? BorderColors.borderBrand
                            : BorderColors.borderPrimary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: FocusRingColors.focusRing,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),

                // 20px gap between email field and password label
                const SizedBox(height: 20),

                // ── Password label ───────────────────────────────────────────
                // text-sm / medium / text-secondary700
                Text(
                  'Password',
                  style: _textSmMedium.copyWith(
                    color: TextColors.textSecondary700,
                  ),
                ),

                const SizedBox(height: 6),

                // ── Password field ───────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  // typed text: text-md / Regular
                  style: _textMdRegular.copyWith(
                    color: TextColors.textPrimary900,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: _textMdMedium.copyWith(
                      color: TextColors.textPlaceholder,
                    ),
                    filled: true,
                    fillColor: BackgroundColors.bgPrimary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: TextColors.textPlaceholder,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: BorderColors.borderPrimary),
                    ),
                    // Brand border when content present, primary otherwise
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _passwordController.text.isNotEmpty
                            ? BorderColors.borderBrand
                            : BorderColors.borderPrimary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: FocusRingColors.focusRing,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),

                // 24px top space for remember me row
                const SizedBox(height: 24),

                // ── Remember me + Forgot password ─────────────────────────────
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? false),
                        activeColor: BackgroundColors.bgBrandSolid,
                        side: BorderSide(
                          color: BorderColors.borderPrimary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // text-sm / medium / text-secondary700
                    Text(
                      'Remember me',
                      style: _textSmMedium.copyWith(
                        color: TextColors.textSecondary700,
                      ),
                    ),
                    const Spacer(),
                    // text-sm / semibold / text-brand-secondary700
                    GestureDetector(
                      onTap: () {
                        // TODO: forgot password
                      },
                      child: Text(
                        'Forgot password',
                        style: _textSmSemibold.copyWith(
                          color: TextColors.textBrandSecondary700,
                        ),
                      ),
                    ),
                  ],
                ),

                // 24px bottom space for remember me row
                const SizedBox(height: 24),

                // ── Sign In button ─────────────────────────────────────────
                // Skeuomorphic: linear white gradient stroke (weight 2) +
                // shadow-xs-skeuomorphic from ShadowColors tokens
                GestureDetector(
                  onTapDown: (_) => setState(() => _isSignInPressed = true),
                  onTapUp: (_) => setState(() => _isSignInPressed = false),
                  onTapCancel: () => setState(() => _isSignInPressed = false),
                  child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: ShapeDecoration(
                    color: BackgroundColors.bgBrandSolid,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      // Gradient stroke: white highlight fading top → bottom
                      side: BorderSide(
                        // Pressed → brand-tinted; idle → white highlight
                        color: _isSignInPressed
                            ? const Color(0x29E04F16)
                            : const Color(0x29FFFFFF),
                        width: 2,
                      ),
                    ),
                    // shadow-xs-skeuomorphic
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
                    onPressed: _isLoading ? null : _signInWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: TextColors.textWhite,
                      elevation: 0,
                      // Let the Container own all sizing — no internal constraints
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
                            'Sign In',
                            style: _textMdSemibold.copyWith(
                              color: TextColors.textWhite,
                              // height:1.0 collapses Bricolage Grotesque's
                              // tall native line-height that causes clipping
                              height: 1.0,
                            ),
                          ),
                  ),
                  ),
                ),

                // 35px gap + border-secondary divider between buttons
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
                const SizedBox(height: 18),

                // ── Sign in with Google ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: BackgroundColors.bgPrimary,
                      foregroundColor: TextColors.textSecondary700,
                      side: BorderSide(color: BorderColors.borderPrimary),
                      elevation: 0,
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
                          // text-md / semibold / text-secondary700
                          style: _textMdSemibold.copyWith(
                            color: TextColors.textSecondary700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Don't have an account? Sign up ────────────────────────────
                Center(
                  child: RichText(
                    text: TextSpan(
                      // text-sm / regular / text-tertiary600
                      text: "Don't have an account? ",
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
                                builder: (_) => const SignUpScreen(),
                              ),
                            ),
                            child: Text(
                              'Sign up',
                              // text-sm / semibold / text-brand-secondary700
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

// ── Tab toggle widget ────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onTabChanged;

  const _TabToggle({required this.activeTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: BackgroundColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BorderColors.borderPrimary),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Sign up',
            isActive: activeTab == 0,
            onTap: () => onTabChanged(0),
          ),
          _Tab(
            label: 'Log in',
            isActive: activeTab == 1,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? BackgroundColors.bgPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isActive
                ? Border.all(color: BorderColors.borderPrimary)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            // text-md / regular
            // active = text-secondary700, inactive = text-quaternary500
            style: TextStyle(
              fontFamily: AppTypographyTokens.bodyFontFamily,
              fontSize: AppTypographyTokens.textMd,
              fontWeight: AppTypographyTokens.regular,
              height: AppTypographyTokens.textMdHeight,
              color: isActive
                  ? TextColors.textSecondary700
                  : TextColors.textQuaternary500,
            ),
          ),
        ),
      ),
    );
  }
}
