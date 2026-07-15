import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _passwordsMatch =>
      _passwordController.text == _confirmPasswordController.text;

  bool get _passwordStrong => _passwordController.text.length >= 8;

  String _generateRecoveryKey() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excludes confusing O, 0, I, 1
    final rand = Random.secure();
    String chunk() => List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return '${chunk()}-${chunk()}-${chunk()}-${chunk()}';
  }

  void _showRecoveryKeyDialog(String recoveryKey, String username, String password) {
    bool hasCopied = false;
    bool hasConfirmed = false;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF161825),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return WillPopScope(
              onWillPop: () async => false, // Prevent dismissing by back button
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Text(
                          '🔐 Zero-Identity Recovery Kit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Veyl does not store your email or phone number. If you lose your password, this recovery key is the ONLY way to access your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      
                      // Recovery Key Display Box
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF5D3FD3), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SelectableText(
                              recoveryKey,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                hasCopied ? Icons.check_circle : Icons.copy,
                                color: hasCopied ? Colors.green : Colors.white70,
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: recoveryKey));
                                setModalState(() {
                                  hasCopied = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Checkbox Confirmation
                      CheckboxListTile(
                        value: hasConfirmed,
                        onChanged: (val) {
                          setModalState(() {
                            hasConfirmed = val ?? false;
                          });
                        },
                        title: const Text(
                          'I have copied and safely stored my recovery key. Veyl cannot recover my account without it.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: const Color(0xFF5D3FD3),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      
                      // Create Account Button
                      ElevatedButton(
                        onPressed: (hasCopied && hasConfirmed)
                            ? () async {
                                Navigator.pop(context); // Close bottom sheet
                                _performRegistration(recoveryKey, username, password);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D3FD3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  void _performRegistration(String recoveryKey, String username, String password) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider).register(
        username: username,
        password: password,
        recoveryKey: recoveryKey,
      );
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _errorMessage =
                  'Registration failed. Please check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _register() {
    setState(() {
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    if (username.length < 3) {
      setState(() => _errorMessage = 'Username must be at least 3 characters.');
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      setState(
        () =>
            _errorMessage =
                'Username can only contain letters, numbers, dots and underscores.',
      );
      return;
    }

    if (!_passwordStrong) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    // Generate recovery key and prompt user to copy it BEFORE performing register API call
    final recoveryKey = _generateRecoveryKey();
    _showRecoveryKeyDialog(recoveryKey, username, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Username',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Build an anonymous identity. No phone number or email required.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Username Input
              const Text(
                'Username',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.black),
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => setState(() => _errorMessage = null),
                decoration: InputDecoration(
                  prefixText: '@ ',
                  prefixStyle: const TextStyle(
                    color: Color(0xFF5D3FD3),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: 'username',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF5D3FD3),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password Input
              const Text(
                'Password',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(color: Colors.black),
                onChanged: (_) => setState(() => _errorMessage = null),
                decoration: InputDecoration(
                  hintText: 'Min. 8 characters',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed:
                        () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF5D3FD3),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Password strength indicators
              Row(
                children: [
                  Icon(
                    _passwordStrong ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: _passwordStrong ? Colors.green : Colors.grey[400],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'At least 8 characters',
                    style: TextStyle(
                      color: _passwordStrong ? Colors.green : Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Confirm Password
              const Text(
                'Confirm Password',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                style: const TextStyle(color: Colors.black),
                onChanged: (_) => setState(() => _errorMessage = null),
                decoration: InputDecoration(
                  hintText: 'Re-enter your password',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed:
                        () => setState(
                          () =>
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible,
                        ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: _confirmPasswordController.text.isNotEmpty
                        ? (_passwordsMatch
                              ? BorderSide(color: Colors.green.shade300)
                              : const BorderSide(color: Colors.red))
                        : BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF5D3FD3),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3FD3),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : const Text(
                          'Generate Recovery Kit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Veyl does not require or collect any personally identifying details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
