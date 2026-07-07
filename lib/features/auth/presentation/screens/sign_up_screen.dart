import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/l10n.dart';
import '../auth_controller.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_header.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Splits the single "Full name" into Magento's required firstname/lastname
  /// (last token is the surname; a single token fills both).
  ({String first, String last}) _splitName() {
    final parts = _fullName.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return (first: '', last: '');
    if (parts.length == 1) return (first: parts.first, last: parts.first);
    return (
      first: parts.sublist(0, parts.length - 1).join(' '),
      last: parts.last,
    );
  }

  Future<void> _submit() async {
    if (!_agreedToTerms) return;
    if (!_formKey.currentState!.validate()) return;
    final name = _splitName();
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            firstName: name.first,
            lastName: name.last,
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) context.go(AppRoutes.home);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).authSignInError)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 80,
        title: const BrandLogo(height: 52),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  icon: Icons.person_outline,
                  title: l10n.authSignUpTitle,
                  subtitle: l10n.authSignUpSubtitle,
                ),
                const SizedBox(height: 24),
                AuthField(
                  controller: _fullName,
                  icon: Icons.person_outline,
                  hint: l10n.fieldFullName,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(context, v),
                ),
                const SizedBox(height: 16),
                AuthField(
                  controller: _email,
                  icon: Icons.mail_outline,
                  hint: l10n.authEmailHint,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => Validators.email(context, v),
                ),
                const SizedBox(height: 16),
                AuthField(
                  controller: _password,
                  icon: Icons.lock_outline,
                  hint: l10n.fieldPassword,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.inkFaint,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => Validators.password(context, v),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                // Terms agreement — gates the Create Account button (Figma).
                InkWell(
                  onTap: () =>
                      setState(() => _agreedToTerms = !_agreedToTerms),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) =>
                            setState(() => _agreedToTerms = v ?? false),
                      ),
                      Expanded(
                        child: Text(
                          l10n.authAgreeTerms,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: (_busy || !_agreedToTerms) ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.authSignUpTitle),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.authHaveAccount),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(l10n.authSignInTitle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
