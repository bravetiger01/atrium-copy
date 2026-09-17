import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/light_mode_token.dart';
import '../../theme/app_typography_tokens.dart';
import 'job_screen.dart';
import 'projects_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Candidate Shell — 4-tab bottom navigation
//   0 · Discover   (job_screen.dart)
//   1 · Projects   (projects_screen.dart)
//   2 · Matches    (inbox_screen.dart)
//   3 · Profile    (profile_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

class CandidateShell extends StatefulWidget {
  /// Starting tab index (defaults to Projects = 1 for the Projects section flow).
  final int initialIndex;
  const CandidateShell({super.key, this.initialIndex = 1});

  @override
  State<CandidateShell> createState() => _CandidateShellState();
}

class _CandidateShellState extends State<CandidateShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const List<Widget> _pages = [
    JobScreen(),
    ProjectsScreen(),
    InboxScreen(),
    ProfileScreen(),
  ];

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _CandidateNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _CandidateNavBar extends StatelessWidget {
  const _CandidateNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  // Selected item styling matching Figma tokens
  static const _activeBgColor = UtilityOrangeDarkColors.utilityOrangeDark200; // #FFD6AE
  static const _mainColor = UtilityOrangeDarkColors.utilityOrangeDark600;     // #E62E05

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BackgroundColors.bgPrimary,
        border: Border(
          top: BorderSide(color: BorderColors.borderSecondary, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ── 0 · Discover — uses assets/icons/discover.png ───────────
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
                activeBgColor: _activeBgColor,
                mainColor: _mainColor,
                label: 'Discover',
                iconBuilder: (color) => Image.asset(
                  'assets/icons/discover.png',
                  width: 24,
                  height: 18,
                  fit: BoxFit.contain,
                  color: color,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),

              // ── 1 · Projects — uses assets/icons/projects.png (weight 2) ─
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
                activeBgColor: _activeBgColor,
                mainColor: _mainColor,
                label: 'Projects',
                iconBuilder: (color) => Image.asset(
                  'assets/icons/projects.png',
                  width: 22,
                  height: 20,
                  fit: BoxFit.contain,
                  color: color,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),

              // ── 2 · Matches — uses assets/icons/matches.png (weight 2) ───
              _NavItem(
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
                activeBgColor: _activeBgColor,
                mainColor: _mainColor,
                label: 'Matches',
                iconBuilder: (color) => Image.asset(
                  'assets/icons/matches.png',
                  width: 21,
                  height: 20,
                  fit: BoxFit.contain,
                  color: color,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),

              // ── 3 · Profile — uses assets/icons/profile.png (weight 2) ───
              _NavItem(
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
                activeBgColor: _activeBgColor,
                mainColor: _mainColor,
                label: 'Profile',
                iconBuilder: (color) => Image.asset(
                  'assets/icons/profile.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  color: color,
                  colorBlendMode: BlendMode.srcIn,
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
// Single Nav Item with Pill Background for Selected Item
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.activeBgColor,
    required this.mainColor,
    required this.label,
    required this.iconBuilder,
  });

  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeBgColor;
  final Color mainColor;
  final String label;
  final Widget Function(Color color) iconBuilder;

  bool get _isActive => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: SizedBox(
        width: 72,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Pill container around the icon ────────────────────────────
            // Interpolate to/from activeBgColor with 0 alpha (prevents black flash)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                color: _isActive
                    ? activeBgColor
                    : activeBgColor.withOpacity(0.0),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: AnimatedScale(
                  scale: _isActive ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: iconBuilder(mainColor),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── Label ─────────────────────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontFamily: AppTypographyTokens.bodyFontFamily,
                fontSize: 11,
                fontWeight: _isActive
                    ? AppTypographyTokens.semibold
                    : AppTypographyTokens.medium,
                color: mainColor,
                height: 1.2,
              ),
              child: Text(label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

