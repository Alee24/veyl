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
    _checkPermissionsThenStart();
  }

  void _checkPermissionsThenStart() async {
    final callService = ref.read(callServiceProvider);
    final isVideo = widget.roomName.startsWith('video_');
    
    // Request appropriate permissions based on call type
    final hasPermission = isVideo
        ? await callService.requestCallPermissions(context)
        : await callService.requestMicPermission(context);

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isVideo 
                ? 'Camera and microphone access required to make video calls.'
                : 'Microphone access required to make voice calls.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        context.pop();
      }
      return;
    }
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

    // 2. Play Futuristic Calling / Ringback sound
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      try {
        await _audioPlayer.play(AssetSource('audio/futuristic_outgoing.wav'));
      } catch (_) {
        await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/903/903-84.wav'));
      }
    } catch (e) {
      debugPrint('Failed to play calling ringback sound: $e');
    }

    // 3. Listen to Socket events
    _acceptedSubscription = socketService.onCallAccepted.listen((data) async {
      if (data['calleeId'] == widget.calleeId && mounted) {
        _stopCallingSound();
        final isVideo = widget.roomName.startsWith('video');
        
        context.pushReplacement(
          '/active_call',
          extra: {
            'peerId': widget.calleeId,
            'peerName': widget.calleeName,
            'peerUsername': widget.calleeUsername,
            'isVideo': isVideo,
            'isCaller': true,
          },
        );
      }
    });

    _declinedSubscription = socketService.onCallDeclined.listen((data) {
      if (data['calleeId'] == widget.calleeId && mounted) {
        _stopCallingSound();
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Call was declined')),
          );
        }
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

    final isVideo = widget.roomName.startsWith('video_');

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  isVideo ? 'Calling (Video)...' : 'Calling (Voice)...',
                  style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
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
