import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import your controller (adjust the path if necessary based on your folder structure)
import '../controllers/login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controllers to grab the text from the inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the login state so the UI rebuilds when isLoading changes
    final state = ref.watch(loginControllerProvider);

    // Listen for error messages and show a SnackBar
    ref.listen(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        if (next.errorMessage == "PROFILE_MISSING") {
          // Handle your specific missing profile logic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No Burgess profile found for this email.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                      const SizedBox(height: 48),

                      // --- FORM FIELDS ---
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        // Disable input while loading
                        enabled: !state.isLoading,
                      ),
                      const SizedBox(height: 24),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        enabled: !state.isLoading,
                      ),
                      const SizedBox(height: 32),

                      // --- ACTIONS ---
                      ElevatedButton(
                        // Disable the button if loading
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                final email = _emailController.text.trim();
                                final password = _passwordController.text;

                                if (email.isEmpty || password.isEmpty) return;

                                // Call the submit method on your controller
                                await ref
                                    .read(loginControllerProvider.notifier)
                                    .submit(email, password);
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
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: state.isLoading
                            ? null
                            : () {
                                context.push('/forgot-password');
                              },
                        child: const Text('Forgot Password?'),
                      ),

                      const Divider(height: 48),

                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Don\'t have an account?'),
                          TextButton(
                            onPressed: state.isLoading
                                ? null
                                : () {
                                    context.push('/register');
                                  },
                            child: const Text('Register here.'),
                          ),
                        ],
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

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    await ref.read(loginControllerProvider.notifier).submit(email, password);
  }
}
