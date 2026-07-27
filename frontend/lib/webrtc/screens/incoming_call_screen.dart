import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/chat/socket_service.dart';
import '../../features/calling/call_service.dart';

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

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  Timer? _vibrationTimer;
  StreamSubscription? _cancelledSubscription;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _requestPermissionsAndRing();

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

  void _requestPermissionsAndRing() async {
    await Permission.notification.request();
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      try {
        await _audioPlayer.play(AssetSource('audio/futuristic_ringtone.wav'));
      } catch (_) {
        await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-84.wav'));
      }
    } catch (e) {
      debugPrint('Error playing ringtone: $e');
    }

    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
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
    _pulseController.dispose();
    _cancelledSubscription?.cancel();
    super.dispose();
  }

  void _declineCall() {
    ref.read(socketServiceProvider).declineCall(widget.callerId);
    _stopRingingAndVibration();
    context.pop();
  }

  void _acceptCall() async {
    final callService = ref.read(callServiceProvider);
    final isVideo = widget.roomName.startsWith('video');

    final hasPermission = isVideo 
        ? await callService.requestCallPermissions(context)
        : await callService.requestMicPermission(context);
    if (!hasPermission) return;

    ref.read(socketServiceProvider).acceptCall(widget.callerId);
    _stopRingingAndVibration();

    if (mounted) {
      context.pushReplacement(
        '/active_call',
        extra: {
          'peerId': widget.callerId,
          'peerName': widget.callerName,
          'peerUsername': widget.callerUsername,
          'isVideo': isVideo,
          'isCaller': false,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.roomName.startsWith('video');
    final avatarUrl = 'https://i.pravatar.cc/300?u=${widget.callerUsername}';

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient with Blur
          Positioned.fill(
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F172A)),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
              child: Container(
                color: Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Pulsing Avatar Ring
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 140 + (_pulseController.value * 40),
                            height: 140 + (_pulseController.value * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF6366F1).withOpacity(1.0 - _pulseController.value),
                                width: 3,
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 64,
                          backgroundImage: NetworkImage(avatarUrl),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Caller Info
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '@${widget.callerUsername}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isVideo ? Icons.videocam : Icons.phone_in_talk, color: const Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isVideo ? 'Incoming HD Video Call...' : 'Incoming HD Voice Call...',
                      style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const Spacer(flex: 3),

                // Action Buttons (Glassmorphic)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Decline
                      GestureDetector(
                        onTap: _declineCall,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                            ),
                            const SizedBox(height: 12),
                            const Text('Decline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      // Accept
                      GestureDetector(
                        onTap: _acceptCall,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.shade700,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.shade700.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.call, color: Colors.white, size: 32),
                            ),
                            const SizedBox(height: 12),
                            const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
