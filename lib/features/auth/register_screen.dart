import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signUp(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) {
        context.go('/confirm', extra: _emailCtrl.text.trim());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
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
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return 'At least 8 characters';
                        }
                        if (!v.contains(RegExp(r'[A-Z]'))) {
                          return 'Must contain an uppercase letter';
                        }
                        if (!v.contains(RegExp(r'[0-9]'))) {
                          return 'Must contain a number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signUp(),
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v != _passwordCtrl.text ? 'Passwords do not match' : null,
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
                      onPressed: _loading ? null : _signUp,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Account'),
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
