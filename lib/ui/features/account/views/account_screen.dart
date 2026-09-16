import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../routing/app_router.dart';
import '../../../core/app_links.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../core/widgets/surfaces.dart';
import '../../auth/views/auth_widgets.dart';
import '../view_models/account_view_model.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AccountViewModel _viewModel = AccountViewModel(auth: context.read());

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openPrivacyPolicy() async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(AppLinks.privacyPolicy),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not open the privacy policy: $e');
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open ${AppLinks.privacyPolicy} in your browser.')),
      );
    }
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

  /// The router's auth redirect shows the login screen once the account is
  /// gone, so there is nothing to do here afterwards.
  Future<void> _confirmDelete() => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DeleteAccountDialog(viewModel: _viewModel),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Account')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: ContentWidth(
            maxWidth: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(child: _ProfileCard(viewModel: _viewModel)),
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _WhatWeKeep(isCloud: _viewModel.isCloud),
                ),
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: Column(
                    children: [
                      _LinkRow(
                        icon: Icons.insights_rounded,
                        color: AppColors.leafDeep,
                        tint: AppColors.leafTint,
                        title: 'My progress',
                        subtitle: 'Every score you have saved',
                        onTap: () => context.push(Routes.progress),
                      ),
                      const SizedBox(height: 10),
                      _LinkRow(
                        icon: Icons.shield_rounded,
                        color: AppColors.primaryDeep,
                        tint: AppColors.primaryTint,
                        title: 'Privacy policy',
                        subtitle: 'What we collect and why',
                        onTap: _openPrivacyPolicy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: ChunkyButton(
                    label: 'Log out',
                    icon: Icons.logout_rounded,
                    variant: ChunkyVariant.secondary,
                    onPressed: _confirmSignOut,
                  ),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 260),
                  child: _DangerZone(onDelete: _confirmDelete),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.viewModel});

  final AccountViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryTint,
            child: ExcludeSemantics(
              child: Text(viewModel.initial, style: AppTheme.display(size: 26, color: AppColors.primaryDeep)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(viewModel.displayName, style: AppTheme.display(size: 22), overflow: TextOverflow.ellipsis),
                Text(
                  viewModel.email,
                  style: AppTheme.body(size: 14, color: AppColors.inkSoft),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatWeKeep extends StatelessWidget {
  const _WhatWeKeep({required this.isCloud});

  final bool isCloud;

  @override
  Widget build(BuildContext context) {
    final lines = [
      'Your name and email address',
      'Every score, star and reading time you save',
      isCloud
          ? 'Stored with Google Firebase so you can log in from any device'
          : 'Stored on this device only, because you are in offline demo mode',
    ];
    return SoftCard(
      color: AppColors.surfaceMuted,
      borderColor: AppColors.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text('What RED keeps', style: AppTheme.display(size: 18))),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle_rounded, size: 17, color: AppColors.leafDeep),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(line, style: AppTheme.body(size: 14))),
                ],
              ),
            ),
          const SizedBox(height: 2),
          Text(
            'RED shows no adverts and sells nothing to anyone.',
            style: AppTheme.body(size: 13, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.color,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
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
                  decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTheme.display(size: 18, weight: FontWeight.w600)),
                      Text(subtitle, style: AppTheme.body(size: 13, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.wrongTint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('Delete my account', style: AppTheme.display(size: 18, color: AppColors.wrong)),
          ),
          const SizedBox(height: 6),
          Text(
            'This removes your account, your name and email, and every score '
            'you have saved. It cannot be undone.',
            style: AppTheme.body(size: 14),
          ),
          const SizedBox(height: 14),
          ChunkyButton(
            label: 'Delete my account',
            icon: Icons.delete_forever_rounded,
            color: AppColors.wrong,
            edgeColor: const Color(0xFF8E1F1F),
            foregroundColor: Colors.white,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Asks for the password before deleting, so that a phone left logged in
/// cannot be wiped by someone walking past.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.viewModel});

  final AccountViewModel viewModel;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isDeleting = true;
      _error = null;
    });

    final deleted = await widget.viewModel.deleteAccount(_password.text);
    if (!mounted) return;
    if (deleted) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isDeleting = false;
      _error = widget.viewModel.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete for ever?', style: AppTheme.display(size: 22)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your account and every score you have saved will be deleted. '
              'We cannot bring them back.',
              style: AppTheme.body(size: 14),
            ),
            const SizedBox(height: 16),
            ErrorBanner(message: _error),
            PasswordField(
              controller: _password,
              label: 'Type your password to confirm',
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Please type your password.' : null,
              onSubmitted: (_) => _isDeleting ? null : _delete(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
          child: const Text('Keep my account'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.wrong),
          onPressed: _isDeleting ? null : _delete,
          child: _isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Text('Delete for ever'),
        ),
      ],
    );
  }
}
