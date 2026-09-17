import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SwipeCard — wraps any child with drag-to-swipe gesture + animated overlays
//
//  Usage:
//    SwipeCard(
//      key: ValueKey(job.id),          // IMPORTANT: unique key per card
//      onSwipeRight: () { ... },       // called after fly-off animation completes
//      onSwipeLeft:  () { ... },
//      onTap:        () { ... },       // called on tiny-drag (tap)
//      child: JobCardContent(...),
//    )
//
//  Programmatic swipe (e.g. from buttons):
//    final key = GlobalKey<SwipeCardState>();
//    key.currentState?.triggerSwipeRight();
// ─────────────────────────────────────────────────────────────────────────────

class SwipeCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onTap;

  const SwipeCard({
    super.key,
    required this.child,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.onTap,
  });

  @override
  State<SwipeCard> createState() => SwipeCardState();
}

class SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Animation<Offset>? _anim;

  Offset _offset = Offset.zero;
  bool _isAnimating = false;

  // Threshold to register a full swipe (px)
  static const double _swipeThreshold = 110.0;
  // Max px movement to still count as a tap
  static const double _tapThreshold = 6.0;

  // ── Computed values ────────────────────────────────────────────────────────

  /// Subtle card tilt while dragging
  double get _rotation => (_offset.dx / 350).clamp(-0.25, 0.25);

  /// Green overlay opacity (0→1 as you drag right toward threshold)
  double get _rightOpacity =>
      (_offset.dx > 0 ? _offset.dx / _swipeThreshold : 0.0).clamp(0.0, 1.0);

  /// Red overlay opacity (0→1 as you drag left toward threshold)
  double get _leftOpacity =>
      (_offset.dx < 0 ? -_offset.dx / _swipeThreshold : 0.0).clamp(0.0, 1.0);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Gesture handlers ───────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails _) {
    if (_isAnimating) return;
    _ctrl.stop();
    _anim = null;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_isAnimating) return;
    setState(() => _offset += d.delta);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_isAnimating) return;

    // Tiny movement → treat as tap
    if (_offset.distance < _tapThreshold) {
      _snapBack();
      widget.onTap?.call();
      return;
    }

    if (_offset.dx >= _swipeThreshold) {
      _flyOff(right: true);
    } else if (_offset.dx <= -_swipeThreshold) {
      _flyOff(right: false);
    } else {
      _snapBack();
    }
  }

  // ── Animation helpers ──────────────────────────────────────────────────────

  void _snapBack() {
    _isAnimating = true;
    final start = _offset;
    _ctrl
      ..duration = const Duration(milliseconds: 500)
      ..reset();

    _anim = Tween<Offset>(begin: start, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut))
      ..addListener(_syncOffset);

    _ctrl.forward().then((_) {
      if (mounted) setState(() => _isAnimating = false);
    });
  }

  void _flyOff({required bool right}) {
    _isAnimating = true;
    final screenW = MediaQuery.of(context).size.width;
    final end = Offset(
      right ? screenW * 1.8 : -screenW * 1.8,
      _offset.dy + 60,
    );

    _ctrl
      ..duration = const Duration(milliseconds: 320)
      ..reset();

    _anim = Tween<Offset>(begin: _offset, end: end)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut))
      ..addListener(_syncOffset);

    _ctrl.forward().then((_) {
      if (right) {
        widget.onSwipeRight?.call();
      } else {
        widget.onSwipeLeft?.call();
      }
    });
  }

  void _syncOffset() {
    if (mounted && _anim != null) setState(() => _offset = _anim!.value);
  }

  // ── Public API (for button-triggered swipes) ───────────────────────────────

  void triggerSwipeRight() => _flyOff(right: true);
  void triggerSwipeLeft() => _flyOff(right: false);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(
          angle: _rotation,
          alignment: Alignment.bottomCenter,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Card face ────────────────────────────────────────────────
              widget.child,

              // ── INTERESTED overlay (drag right) ──────────────────────────
              if (_offset.dx > 0)
                Positioned.fill(
                  child: Opacity(
                    opacity: _rightOpacity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.swipeRightBg.withValues(alpha: 0.88),
                        borderRadius: AppRadius.cardRadius,
                        border:
                            Border.all(color: AppColors.swipeRight, width: 2.5),
                      ),
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                      child: _SwipeLabel(
                        text: 'INTERESTED',
                        icon: Icons.check_rounded,
                        color: AppColors.swipeRight,
                      ),
                    ),
                  ),
                ),

              // ── PASS overlay (drag left) ─────────────────────────────────
              if (_offset.dx < 0)
                Positioned.fill(
                  child: Opacity(
                    opacity: _leftOpacity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.swipeLeftBg.withValues(alpha: 0.88),
                        borderRadius: AppRadius.cardRadius,
                        border:
                            Border.all(color: AppColors.swipeLeft, width: 2.5),
                      ),
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.fromLTRB(0, 40, 24, 0),
                      child: _SwipeLabel(
                        text: 'PASS',
                        icon: Icons.close_rounded,
                        color: AppColors.swipeLeft,
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
//  Swipe label (INTERESTED / PASS stamp)
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _SwipeLabel({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        borderRadius: AppRadius.lgRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
