import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/red_panda_logo.dart';
import '../../../core/widgets/surfaces.dart';
import '../view_models/home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel = HomeViewModel(
    auth: context.read(),
    progress: context.read(),
    content: context.read(),
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _confirmSignOut() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log out?', style: AppTheme.display(size: 22)),
        content: Text('Your scores are saved. You can log in again any time.', style: AppTheme.body()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (yes == true) await _viewModel.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: ContentWidth(
                maxWidth: 820,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeSlideIn(child: _TopBar(viewModel: _viewModel, onSignOut: _confirmSignOut)),
                    const SizedBox(height: 20),
                    FadeSlideIn(delay: const Duration(milliseconds: 100), child: _HeroCard(viewModel: _viewModel)),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 180),
                      child: Semantics(
                        header: true,
                        child: Text('What would you like to do?', style: AppTheme.display(size: 22)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final assess = _FeatureCard(
                          title: 'Assess',
                          subtitle: 'Test your reading skills with a surprise story',
                          badge: 'Timed',
                          icon: Icons.timer_rounded,
                          colors: const [AppColors.assessStart, AppColors.assessEnd],
                          onTap: () => context.push(Routes.assess),
                        );
                        final materials = _FeatureCard(
                          title: 'Materials',
                          subtitle: 'Practice with fun stories at your own pace',
                          badge: '${_viewModel.levelCount} levels',
                          icon: Icons.auto_stories_rounded,
                          colors: const [AppColors.materialsStart, AppColors.materialsEnd],
                          onTap: () => context.push(Routes.materials),
                        );
                        if (constraints.maxWidth >= 600) {
                          return FadeSlideIn(
                            delay: const Duration(milliseconds: 260),
                            child: Row(
                              children: [
                                Expanded(child: assess),
                                const SizedBox(width: 16),
                                Expanded(child: materials),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: [
                            FadeSlideIn(delay: const Duration(milliseconds: 260), child: assess),
                            const SizedBox(height: 16),
                            FadeSlideIn(delay: const Duration(milliseconds: 340), child: materials),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 420),
                      child: _ProgressLink(viewModel: _viewModel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.viewModel, required this.onSignOut});

  final HomeViewModel viewModel;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'My progress',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push(Routes.progress),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryTint,
              child: ExcludeSemantics(
                child: Text(viewModel.initial, style: AppTheme.display(size: 22, color: AppColors.primaryDeep)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(viewModel.greeting, style: AppTheme.body(size: 14, color: AppColors.inkSoft)),
              Text(
                'Hi, ${viewModel.firstName}!',
                style: AppTheme.display(size: 26),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Log out',
          style: IconButton.styleFrom(backgroundColor: AppColors.surface, minimumSize: const Size(48, 48)),
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded, color: AppColors.ink),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8B8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Let's grow your reading superpowers!",
                  style: AppTheme.display(size: 21, color: const Color(0xFF5A3A00)),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(icon: Icons.star_rounded, iconColor: AppColors.sunshineDeep, label: '${viewModel.totalStars} stars'),
                    _StatChip(icon: Icons.menu_book_rounded, iconColor: AppColors.leaf, label: '${viewModel.storiesRead} stories'),
                    if (viewModel.lastAssessment case final last?)
                      _StatChip(
                        icon: Icons.timer_rounded,
                        iconColor: AppColors.primary,
                        label: 'Last test ${last.correct}/${last.total}',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Floating(child: RedPandaLogo(size: 104, semanticLabel: null)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.iconColor, required this.label});

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.body(size: 13, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        excludeSemantics: true,
        child: Material(
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              height: 168,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    bottom: -40,
                    child: Icon(icon, size: 170, color: Colors.white.withValues(alpha: 0.13)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(icon, color: Colors.white, size: 28),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(badge, style: AppTheme.body(size: 12, color: colors.first, weight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: AppTheme.display(size: 30, color: Colors.white)),
                                  Text(subtitle, style: AppTheme.body(size: 14, color: Colors.white, height: 1.3)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.arrow_forward_rounded, color: AppColors.ink),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressLink extends StatelessWidget {
  const _ProgressLink({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(Routes.progress),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outline, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.leafTint, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.insights_rounded, color: AppColors.leafDeep),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My progress', style: AppTheme.display(size: 18, weight: FontWeight.w600)),
                    Text(
                      '${viewModel.assessmentsTaken} tests  |  ${viewModel.storiesRead} stories read',
                      style: AppTheme.body(size: 13, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
