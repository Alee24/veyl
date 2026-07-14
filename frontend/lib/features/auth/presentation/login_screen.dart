import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_provider.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guest Login failed')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Dark background matching design
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purpleAccent, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.shield, size: 40, color: Colors.white), // Placeholder logo
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to\nVEYL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chat, call and meet without\nsharing your phone number.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const Spacer(flex: 1),
              
              // Feature list
              _buildFeatureItem(Icons.person_outline, 'Create your username', 'No phone number required'),
              const SizedBox(height: 16),
              _buildFeatureItem(Icons.qr_code, 'Share your link or QR', 'People can contact you instantly'),
              const SizedBox(height: 16),
              _buildFeatureItem(Icons.chat_bubble_outline, 'Chat, Call, Meet', 'All in one secure place'),
              
              const Spacer(flex: 2),
              
              // Buttons
              ElevatedButton(
                onPressed: () => context.push('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3FD3), // Primary purple
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Create Username', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Sign In', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/home'),
                  child: const Text(
                        'Continue as Guest',
                        style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                      ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF5D3FD3), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
