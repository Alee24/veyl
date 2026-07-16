import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../chat/chat_provider.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/ambient_background.dart';

class ClaimLinkScreen extends ConsumerStatefulWidget {
  final String token;
  const ClaimLinkScreen({super.key, required this.token});

  @override
  ConsumerState<ClaimLinkScreen> createState() => _ClaimLinkScreenState();
}

class _ClaimLinkScreenState extends ConsumerState<ClaimLinkScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _linkDetails;

  final _pinController = TextEditingController();
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyToken() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/links/verify/${widget.token}');
      setState(() {
        _linkDetails = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('404')
            ? 'This invitation has expired or is invalid.'
            : 'Failed to verify invite link: $e';
        _isLoading = false;
      });
    }
  }

  void _claimToken() async {
    final hasPin = _linkDetails?['password'] != null;
    final pin = _pinController.text.trim();

    if (hasPin && pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the PIN code for this invite.')),
      );
      return;
    }

    setState(() => _isClaiming = true);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/links/claim/${widget.token}',
        data: {
          if (hasPin) 'password': pin,
        },
      );

      final chatId = response.data['chatId'];
      ref.invalidate(userChatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session started successfully!')),
        );
        context.go('/chat/$chatId');
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().contains('403')
            ? 'Invalid PIN code.'
            : 'Failed to claim invitation link: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errText)),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const AmbientBackground(
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: AmbientBackground(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.link_off_outlined, size: 80, color: theme.colorScheme.error),
                const SizedBox(height: 24),
                Text(
                  'Invitation Expired',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 48),
                PremiumButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final owner = _linkDetails?['owner'] ?? {};
    final String inviterName = owner['displayName'] ?? owner['username'] ?? 'Alex';
    final String linkName = _linkDetails?['name'] ?? 'Temporary Invite';
    final List<dynamic> allowedActions = _linkDetails?['allowedActions'] ?? [];
    final bool requirePin = _linkDetails?['password'] != null;

    final String expiresAtStr = _linkDetails?['expiresAt'] != null
        ? DateTime.parse(_linkDetails?['expiresAt']).toLocal().toString().substring(11, 16)
        : 'Never';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Temporary Invite', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: AmbientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Inviter Info header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00F2FE),
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${owner['username']}'),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                '$inviterName invited you',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'via "$linkName"',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Allowed Actions list
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : theme.dividerColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allowed Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Chat row
                    _buildActionRow(
                      icon: Icons.chat_bubble_outline,
                      label: 'Direct Messaging',
                      isAllowed: allowedActions.contains('chat'),
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    
                    // Call row
                    _buildActionRow(
                      icon: Icons.call_outlined,
                      label: 'Voice Calling',
                      isAllowed: allowedActions.contains('voice_call'),
                      theme: theme,
                    ),
                    
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Expires today at', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text(
                          expiresAtStr,
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // PIN Code entry if required
              if (requirePin) ...[
                Text(
                  'This invite is PIN code protected. Enter PIN to join:',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22, 
                    letterSpacing: 8, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: const InputDecoration(
                    hintText: '••••',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),
              ],

              PremiumButton(
                onPressed: _isClaiming ? null : _claimToken,
                child: _isClaiming
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Start Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required bool isAllowed,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          color: isAllowed ? theme.colorScheme.secondary : Colors.grey.shade400,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isAllowed ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
              decoration: isAllowed ? TextDecoration.none : TextDecoration.lineThrough,
            ),
          ),
        ),
        Icon(
          isAllowed ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: isAllowed ? Colors.green : Colors.grey.shade400,
          size: 18,
        ),
      ],
    );
  }
}
