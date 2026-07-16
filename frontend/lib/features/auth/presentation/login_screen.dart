import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_provider.dart';
import '../../../core/widgets/veyl_logo.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/premium_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  void _guestLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider).guestLogin();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guest Login failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                
                // Veyl Logo with startup animation
                const Center(
                  child: VeylLogoWidget(size: 110.0),
                ),
                const SizedBox(height: 28),
                
                Text(
                  'VEYL',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                    color: isDark ? Colors.white : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chat, call, and meet without sharing your identity.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                
                const Spacer(flex: 2),

                // Feature items (minimalist)
                _buildFeatureItem(
                  context,
                  Icons.person_outline,
                  'Anonymous Username',
                  'No phone number or email required.',
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  context,
                  Icons.qr_code_scanner_outlined,
                  'Instant Connection',
                  'Connect via secure QR codes or usernames.',
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  context,
                  Icons.shield_outlined,
                  'E2E Encrypted',
                  'Zero-knowledge storage keeps messages private.',
                ),

                const Spacer(flex: 3),

                // Actions
                PremiumButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Create Account'),
                ),
                const SizedBox(height: 16),
                
                // Secondary Sign In Button
                PremiumButton(
                  isOutline: true,
                  onPressed: () => _showSignInBottomSheet(context),
                  child: const Text('Sign In'),
                ),
                
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _guestLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Continue as Guest',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey[600],
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSignInBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    
    // Recovery Fields
    final recoverUsernameController = TextEditingController();
    final recoveryKeyController = TextEditingController();
    final newPasswordController = TextEditingController();

    bool isPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool showRecoveryMode = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161E2E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark ? Colors.white10 : theme.dividerColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: !showRecoveryMode
                      ? Column(
                          key: const ValueKey('signin'),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white24 : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Sign In to VEYL',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Username Input
                            TextField(
                              controller: usernameController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: const InputDecoration(
                                hintText: '@username',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Input
                            TextField(
                              controller: passwordController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              obscureText: !isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () => setModalState(() => isPasswordVisible = !isPasswordVisible),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    showRecoveryMode = true;
                                  });
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            PremiumButton(
                              onPressed: () async {
                                final auth = ref.read(authProvider);
                                try {
                                  await auth.login(usernameController.text, passwordController.text);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    context.go('/home');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                    );
                                  }
                                }
                              },
                              child: const Text('Sign In'),
                            ),
                            const SizedBox(height: 12),
                          ],
                        )
                      : Column(
                          key: const ValueKey('recovery'),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white24 : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Recover VEYL Account',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter your username and the 16-character recovery key to set a new password.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            
                            // Recover Username Input
                            TextField(
                              controller: recoverUsernameController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: const InputDecoration(
                                hintText: '@username',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Recovery Key Input
                            TextField(
                              controller: recoveryKeyController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: const InputDecoration(
                                hintText: 'XXXX-XXXX-XXXX-XXXX',
                                prefixIcon: Icon(Icons.vpn_key_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // New Password Input
                            TextField(
                              controller: newPasswordController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              obscureText: !isNewPasswordVisible,
                              decoration: InputDecoration(
                                hintText: 'New Password (Min. 8 characters)',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () => setModalState(() => isNewPasswordVisible = !isNewPasswordVisible),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            PremiumButton(
                              onPressed: () async {
                                final auth = ref.read(authProvider);
                                final username = recoverUsernameController.text.trim();
                                final key = recoveryKeyController.text.trim();
                                final newPass = newPasswordController.text;

                                if (username.isEmpty || key.isEmpty || newPass.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill in all fields.')),
                                  );
                                  return;
                                }

                                if (newPass.length < 8) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Password must be at least 8 characters.')),
                                  );
                                  return;
                                }

                                try {
                                  await auth.recoverPassword(
                                    username: username,
                                    recoveryKey: key,
                                    newPassword: newPass,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password recovered successfully. Sign in with your new password.')),
                                    );
                                    setModalState(() {
                                      showRecoveryMode = false;
                                      usernameController.text = username;
                                    });
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                    );
                                  }
                                }
                              },
                              child: const Text('Reset Password'),
                            ),
                            const SizedBox(height: 12),
                            
                            // Back to Sign In Link
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    showRecoveryMode = false;
                                  });
                                },
                                child: Text(
                                  'Back to Sign In',
                                  style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : theme.colorScheme.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white10 : theme.dividerColor.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Icon(icon, color: theme.colorScheme.secondary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
