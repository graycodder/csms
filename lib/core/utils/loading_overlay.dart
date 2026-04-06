import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:csms/main.dart';

class LoadingOverlayHelper {
  static Route? _loadingRoute;
  static Timer? _timeoutTimer;

  static void show(BuildContext context) {
    if (_loadingRoute != null) return;

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
      try {
        MyApp.navigatorKey.currentState?.removeRoute(_loadingRoute!);
      } catch (_) {
        // Safe to ignore, route already detached.
      } finally {
        _loadingRoute = null;
      }
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
