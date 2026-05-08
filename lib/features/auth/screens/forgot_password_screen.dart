import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/login_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);

    // Error listener keeps the exact same logic as the Login Screen
    ref.listen(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 48.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- BRANDING BANNER ---
                      Image.asset(
                        'assets/images/goLogo_Banner.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),

                      // --- INSTRUCTIONS ---
                      Text(
                        'Reset Your Password',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your email address and we will send you a link to reset your password.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // --- FORM FIELDS ---
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        enabled: !state.isLoading,
                      ),
                      const SizedBox(height: 32),

                      // --- ACTIONS ---
                      ElevatedButton(
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                final email = _emailController.text.trim();
                                if (email.isEmpty) return;

                                // 1. Fire off the reset request
                                await ref
                                    .read(loginControllerProvider.notifier)
                                    .resetPassword(email);

                                // 2. Guard against navigating if widget is disposed
                                if (!context.mounted) return;

                                // 3. If there are no errors, show a success message and go back
                                final currentState = ref.read(
                                  loginControllerProvider,
                                );
                                if (currentState.errorMessage == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password reset link sent!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  context.pop(); // Return to Login Screen
                                }
                              },
                        child: state.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Send Reset Link'),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: state.isLoading
                            ? null
                            : () {
                                // Standard stack pop to return to Login Screen
                                context.pop();
                              },
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
