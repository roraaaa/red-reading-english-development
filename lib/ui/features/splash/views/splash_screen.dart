import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/red_panda_logo.dart';
import '../../../core/widgets/wordmark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minimumTime = Duration(milliseconds: 1900);

  late final AuthRepository _auth = context.read<AuthRepository>();
  bool _timeUp = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_minimumTime, () {
      _timeUp = true;
      _continueIfReady();
    });
    _auth.addListener(_continueIfReady);
  }

  void _continueIfReady() {
    if (!mounted || !_timeUp || !_auth.isInitialized) return;
    _auth.removeListener(_continueIfReady);
    context.go(_auth.isSignedIn ? Routes.home : Routes.login);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _auth.removeListener(_continueIfReady);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PopIn(child: Floating(child: RedPandaLogo(size: 170))),
            const SizedBox(height: 12),
            const FadeSlideIn(delay: Duration(milliseconds: 350), child: RedWordmark(size: 60)),
            const SizedBox(height: 36),
            FadeSlideIn(
              delay: const Duration(milliseconds: 700),
              child: SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primaryTint,
                    semanticsLabel: 'Loading',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
