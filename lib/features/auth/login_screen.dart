import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    _setLoading(true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _signInSocial(AuthProvider provider) async {
    _setLoading(true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signInWithSocial(provider);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    if (mounted) setState(() => _loading = v);
  }

  void _setError(String? v) {
    if (mounted) setState(() => _error = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'GlazeVault',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For the love of glaze.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || !v.contains('@') ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.length < 8
                          ? 'Password must be at least 8 characters'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: scheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _signIn,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 24),
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed:
                          _loading ? null : () => _signInSocial(AuthProvider.google),
                      icon: const Icon(Icons.login),
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed:
                          _loading ? null : () => _signInSocial(AuthProvider.facebook),
                      icon: const Icon(Icons.facebook),
                      label: const Text('Continue with Facebook'),
                    ),
                    const SizedBox(height: 32),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Create one'),
                      ),
                    ]),
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
