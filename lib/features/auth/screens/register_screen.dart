import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/login_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Profile Not Found',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please contact Burgess to set up your profile:\n'),
              Text('• ALABAMA: alabamainspect@burgess-inc.com / 256-809-0345'),
              SizedBox(height: 8),
              Text('• ARIZONA: azinspect@burgess-inc.com / 480-800-0762'),
              SizedBox(height: 8),
              Text('• AUSTIN: austininspect@burgess-inc.com / 512-828-0011'),
              SizedBox(height: 8),
              Text(
                '• COLORADO: coloradoinspect@burgess-inc.com / 303-300-4527',
              ),
              SizedBox(height: 8),
              Text('• DALLAS: dallasinspect@burgess-inc.com / 214-888-7260'),
              SizedBox(height: 8),
              Text('• FLORIDA: floridainspect@burgess-inc.com / 813-328-3603'),
              SizedBox(height: 8),
              Text('• GEORGIA: atlantainspect@burgess-inc.com / 470-977-5001'),
              SizedBox(height: 8),
              Text('• HOUSTON: houstoninspect@burgess-inc.com / 281-999-0888'),
              SizedBox(height: 8),
              Text(
                '• NORTH CAROLINA: raleighinspect@burgess-inc.com / 984-500-2997',
              ),
              SizedBox(height: 8),
              Text('• SAN ANTONIO: sainspect@burgess-inc.com / 210-558-9598'),
              SizedBox(height: 8),
              Text(
                '• TENNESSEE: nashvilleinspect@burgess-inc.com / 629-213-3998',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);

    ref.listen(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        // 🔥 Fix for double popping: clear any existing SnackBars first
        ScaffoldMessenger.of(context).clearSnackBars();

        final errorMsg = next.errorMessage!;

        // Check for either the specific SQL message or the controller flag
        if (errorMsg == "PROFILE_MISSING" ||
            errorMsg.contains("Email not found")) {
          _showContactDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
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
                      Image.asset(
                        'assets/images/goLogo_Banner.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'Create Superintendent Account',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        enabled: !state.isLoading,
                      ),
                      const SizedBox(height: 24),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        enabled: !state.isLoading,
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                final email = _emailController.text.trim();
                                final password = _passwordController.text;

                                if (email.isEmpty || password.isEmpty) return;

                                await ref
                                    .read(loginControllerProvider.notifier)
                                    .register(email, password);
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
                            : const Text('Register'),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: state.isLoading
                            ? null
                            : () {
                                context.pop();
                              },
                        child: const Text(
                          'Already have an account? Login here.',
                        ),
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
