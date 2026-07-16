import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../../chat/socket_service.dart';
import '../call_service.dart';
import '../../auth/auth_provider.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  final String callerId;
  final String callerName;
  final String callerUsername;
  final String roomName;

  const IncomingCallScreen({
    super.key,
    required this.callerId,
    required this.callerName,
    required this.callerUsername,
    required this.roomName,
  });

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  late AudioPlayer _audioPlayer;
  Timer? _vibrationTimer;
  StreamSubscription? _cancelledSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _requestNotificationPermission();
    _startRingingAndVibration();

    // Listen for call cancellation from the caller
    final socketService = ref.read(socketServiceProvider);
    _cancelledSubscription = socketService.onCallCancelled.listen((data) {
      if (data['callerId'] == widget.callerId && mounted) {
        _stopRingingAndVibration();
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missed call')),
        );
      }
    });
  }

  void _requestNotificationPermission() async {
    await Permission.notification.request();
  }

  void _startRingingAndVibration() async {
    // 1. Loop Ringtone Sound from a reliable public Mixkit URL
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2568/2568-84.wav'));
    } catch (e) {
      debugPrint('Failed to play ringtone: $e');
    }

    // 2. Loop Vibration
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      HapticFeedback.vibrate();
    });
  }

  void _stopRingingAndVibration() {
    _vibrationTimer?.cancel();
    _audioPlayer.stop();
  }

  @override
  void dispose() {
    _stopRingingAndVibration();
    _audioPlayer.dispose();
    _cancelledSubscription?.cancel();
    super.dispose();
  }

  void _declineCall() {
    ref.read(socketServiceProvider).declineCall(widget.callerId);
    _stopRingingAndVibration();
    context.pop();
  }

  void _acceptCall() async {
    // Request camera + mic permissions before joining
    final callService = ref.read(callServiceProvider);
    final hasPermission = await callService.requestCallPermissions(context);
    if (!hasPermission) return; // Stop if denied

    ref.read(socketServiceProvider).acceptCall(widget.callerId);
    _stopRingingAndVibration();
    
    // Launch Jitsi Meet video call
    final profileAsync = ref.read(userProfileProvider);
    final myDisplayName = profileAsync.value?['displayName'] ?? 'User';
    
    if (mounted) context.pop(); // Close incoming call screen
    
    await callService.joinVideoCall(
      widget.roomName,
      myDisplayName,
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarUrl = 'https://i.pravatar.cc/300?u=${widget.callerUsername}';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFB),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            
            // Pulsing Caller Avatar
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2), width: 4),
                ),
                child: CircleAvatar(
                  radius: 64,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Caller Info
            Text(
              widget.callerName,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '@${widget.callerUsername}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ring_volume, color: theme.colorScheme.secondary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Incoming Voice Call...',
                  style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            
            const Spacer(flex: 3),

            // Call Action Buttons (Accept / Decline)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline Button
                _buildActionCircle(
                  icon: Icons.call_end,
                  color: Colors.redAccent,
                  label: 'Decline',
                  onTap: _declineCall,
                ),
                // Accept Button
                _buildActionCircle(
                  icon: Icons.call,
                  color: Colors.greenAccent.shade700,
                  label: 'Accept',
                  onTap: _acceptCall,
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
