import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../chat/socket_service.dart';
import '../call_service.dart';
import '../../auth/auth_provider.dart';

class OutgoingCallScreen extends ConsumerStatefulWidget {
  final String calleeId;
  final String calleeName;
  final String calleeUsername;
  final String roomName;

  const OutgoingCallScreen({
    super.key,
    required this.calleeId,
    required this.calleeName,
    required this.calleeUsername,
    required this.roomName,
  });

  @override
  ConsumerState<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends ConsumerState<OutgoingCallScreen> {
  late AudioPlayer _audioPlayer;
  StreamSubscription? _acceptedSubscription;
  StreamSubscription? _declinedSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _startCallingProgress();
  }

  void _startCallingProgress() async {
    final socketService = ref.read(socketServiceProvider);
    final profileAsync = ref.read(userProfileProvider);
    final myDisplayName = profileAsync.value?['displayName'] ?? 'User';
    final myUsername = profileAsync.value?['username'] ?? 'User';

    // 1. Emit call initiation event
    socketService.makeCall(
      targetUserId: widget.calleeId,
      roomName: widget.roomName,
      callerName: myDisplayName,
      callerUsername: myUsername,
    );

    // 2. Play Calling / Ringback sound (Mixkit double ring)
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/903/903-84.wav'));
    } catch (e) {
      debugPrint('Failed to play calling ringback sound: $e');
    }

    // 3. Listen to Socket events
    _acceptedSubscription = socketService.onCallAccepted.listen((data) async {
      if (data['calleeId'] == widget.calleeId && mounted) {
        _stopCallingSound();
        context.pop(); // Close outgoing screen
        
        // Launch Jitsi Meet call
        await ref.read(callServiceProvider).joinVideoCall(
          widget.roomName,
          myDisplayName,
          '',
        );
      }
    });

    _declinedSubscription = socketService.onCallDeclined.listen((data) {
      if (data['calleeId'] == widget.calleeId && mounted) {
        _stopCallingSound();
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call declined')),
        );
      }
    });
  }

  void _stopCallingSound() {
    _audioPlayer.stop();
  }

  @override
  void dispose() {
    _stopCallingSound();
    _audioPlayer.dispose();
    _acceptedSubscription?.cancel();
    _declinedSubscription?.cancel();
    super.dispose();
  }

  void _cancelCall() {
    ref.read(socketServiceProvider).cancelCall(widget.calleeId);
    _stopCallingSound();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarUrl = 'https://i.pravatar.cc/300?u=${widget.calleeUsername}';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFB),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Pulsing Avatar
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.15), width: 4),
                ),
                child: CircleAvatar(
                  radius: 64,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Callee Info
            Text(
              widget.calleeName,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '@${widget.calleeUsername}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Calling...',
                  style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const Spacer(flex: 3),

            // Hang Up Button
            GestureDetector(
              onTap: _cancelCall,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
