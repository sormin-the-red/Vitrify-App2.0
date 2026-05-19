import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';

class ConfirmScreen extends ConsumerStatefulWidget {
  final String email;

  const ConfirmScreen({super.key, required this.email});

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_codeCtrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your email');
      return;
    }
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .confirmSignUp(widget.email, _codeCtrl.text.trim());
      // Router redirect will handle navigation once auth state updates
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
        title: const Text('Verify Email'),
        leading: BackButton(onPressed: () => context.go('/register')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'Check your email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit confirmation code to\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _confirm(),
                    style: Theme.of(context).textTheme.headlineSmall,
                    decoration: const InputDecoration(
                      labelText: 'Confirmation Code',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
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
                    onPressed: _loading ? null : _confirm,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm'),
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
