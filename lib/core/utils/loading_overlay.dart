import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingOverlayHelper {
  static OverlayEntry? _overlayEntry;
  static Timer? _timeoutTimer;

  static void show(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: const LoadingOverlay(),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Start a safety timeout to prevent permanent loading screens
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 25), () {
      hide();
    });
  }

  static void hide() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (_overlayEntry == null) return;
    try {
      _overlayEntry?.remove();
    } catch (_) {
      // Ignore if already removed or detached
    } finally {
      _overlayEntry = null;
    }
  }
}

class LoadingOverlay extends StatelessWidget {
  final double? size;
  final bool useBox;
  const LoadingOverlay({super.key, this.size, this.useBox = true});

  @override
  Widget build(BuildContext context) {
    if (!useBox) {
      return Center(
        child: Lottie.asset(
          'assets/animations/loading.json',
          width: size ?? 70,
          height: size ?? 70,
          fit: BoxFit.contain,
        ),
      );
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Lottie.asset(
            'assets/animations/loading.json',
            width: size ?? 70,
            height: size ?? 70,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
