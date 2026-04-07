import 'dart:async';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:csms/main.dart';
import 'package:csms/core/theme/app_colors.dart';

class LoadingOverlayHelper {
  static Route? _loadingRoute;
  static Timer? _timeoutTimer;
  static DateTime? _lastShowTime;

  static void show(BuildContext context) {
    final now = DateTime.now();
    // Guard against rapid re-showing (debounce)
    if (_loadingRoute != null) return;
    if (_lastShowTime != null &&
        now.difference(_lastShowTime!) < const Duration(milliseconds: 200)) {
      return;
    }

    _lastShowTime = now;
    _loadingRoute = PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, _, __) =>
          const PopScope(canPop: false, child: LoadingOverlay()),
    );

    Navigator.of(context, rootNavigator: true).push(_loadingRoute!);

    // Start a safety timeout to prevent permanent loading screens
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 25), () {
      hide();
    });
  }

  static void hide() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    if (_loadingRoute != null) {
      final route = _loadingRoute!;
      _loadingRoute = null;
      try {
        final navigator = MyApp.navigatorKey.currentState;
        if (navigator != null && route.navigator != null) {
          navigator.removeRoute(route);
        }
      } catch (_) {
        // Safe to ignore if route already detached
      }
    }
  }
}

/// A reusable animated loading spinner that does not use Lottie.
class AppLoadingSpinner extends StatefulWidget {
  final double size;
  final Color? color;
  const AppLoadingSpinner({super.key, this.size = 40, this.color});

  @override
  State<AppLoadingSpinner> createState() => _AppLoadingSpinnerState();
}

class _AppLoadingSpinnerState extends State<AppLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Transform.rotate(
        angle: _controller.value * 2 * pi,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: widget.size * 0.08,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final double? size;
  final bool useBox;
  const LoadingOverlay({super.key, this.size, this.useBox = true});

  @override
  Widget build(BuildContext context) {
    final spinner = AppLoadingSpinner(size: size ?? 44);

    if (!useBox) {
      return Center(child: spinner);
    }

    return Center(
      child: Container(
        width: (size ?? 44) + 32,
        height: (size ?? 44) + 32,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: spinner,
      ),
    );
  }
}
