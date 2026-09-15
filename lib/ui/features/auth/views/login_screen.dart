import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../core/widgets/red_panda_logo.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/wordmark.dart';
import '../view_models/auth_form_view_model.dart';
import 'auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthFormViewModel _viewModel = AuthFormViewModel(auth: context.read<AuthRepository>());
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _viewModel.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    _viewModel.signIn(email: _email.text, password: _password.text);
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text);
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Forgot your password?', style: AppTheme.display(size: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Type your email and we will send a link to make a new password.', style: AppTheme.body(size: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_rounded)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Send link')),
        ],
      ),
    );
    controller.dispose();
    if (email == null || !mounted) return;
    final message = await _viewModel.sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Column(
          children: [
            const SizedBox(height: 12),
            const FadeSlideIn(child: Floating(child: RedPandaLogo(size: 128))),
            const FadeSlideIn(delay: Duration(milliseconds: 120), child: RedWordmark(size: 48)),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: SoftCard(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Welcome back!', style: AppTheme.display(size: 28), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(
                          'Log in to keep reading',
                          style: AppTheme.body(color: AppColors.inkSoft),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        ErrorBanner(message: _viewModel.errorMessage),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: AuthFormViewModel.validateEmail,
                          onChanged: (_) => _viewModel.clearError(),
                          style: AppTheme.body(),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        PasswordField(
                          controller: _password,
                          label: 'Password',
                          validator: (v) => (v == null || v.isEmpty) ? 'Please type your password.' : null,
                          onSubmitted: (_) => _submit(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _viewModel.isSubmitting ? null : _forgotPassword,
                            child: Text(
                              'Forgot password?',
                              style: AppTheme.body(size: 14, color: AppColors.primaryDeep, weight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ChunkyButton(
                          label: 'Log in',
                          icon: Icons.login_rounded,
                          isLoading: _viewModel.isSubmitting,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 320),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('New to RED?', style: AppTheme.body(color: AppColors.inkSoft)),
                  TextButton(
                    onPressed: () => context.push(Routes.signUp),
                    child: Text(
                      'Create an account',
                      style: AppTheme.body(color: AppColors.primaryDeep, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            if (_viewModel.isDemoMode) ...[
              const SizedBox(height: 12),
              const DemoModeNote(),
            ],
          ],
        ),
      ),
    );
  }
}
