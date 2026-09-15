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
import '../view_models/auth_form_view_model.dart';
import 'auth_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late final AuthFormViewModel _viewModel = AuthFormViewModel(auth: context.read<AuthRepository>());
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _viewModel.dispose();
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    _viewModel.signUp(name: _name.text, email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Column(
          children: [
            FadeSlideIn(
              child: Row(
                children: [
                  const RedPandaLogo(size: 76, semanticLabel: null),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text('Join RED!', style: AppTheme.display(size: 30)),
                        ),
                        Text(
                          'A grown-up can help with this part.',
                          style: AppTheme.body(size: 14, color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: SoftCard(
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ErrorBanner(message: _viewModel.errorMessage),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validator: AuthFormViewModel.validateName,
                          style: AppTheme.body(),
                          decoration: const InputDecoration(
                            labelText: 'Your name',
                            prefixIcon: Icon(Icons.face_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
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
                            helperText: "A parent's or teacher's email is fine",
                            prefixIcon: Icon(Icons.mail_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        PasswordField(
                          controller: _password,
                          label: 'Password',
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: AuthFormViewModel.validatePassword,
                        ),
                        const SizedBox(height: 14),
                        PasswordField(
                          controller: _confirm,
                          label: 'Confirm password',
                          autofillHints: const [AutofillHints.newPassword],
                          validator: (v) => v != _password.text ? 'The passwords do not match.' : null,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 22),
                        ChunkyButton(
                          label: 'Create account',
                          icon: Icons.rocket_launch_rounded,
                          isLoading: _viewModel.isSubmitting,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Already have an account?', style: AppTheme.body(color: AppColors.inkSoft)),
                TextButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go(Routes.login),
                  child: Text('Log in', style: AppTheme.body(color: AppColors.primaryDeep, weight: FontWeight.w700)),
                ),
              ],
            ),
            if (_viewModel.isDemoMode) ...[
              const SizedBox(height: 8),
              const DemoModeNote(),
            ],
          ],
        ),
      ),
    );
  }
}
