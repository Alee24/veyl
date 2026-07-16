import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../nearby_service.dart';
import '../../auth/auth_provider.dart';
import '../../../core/widgets/premium_button.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  bool _nearbyEnabled = false;
  List<NearbyPeer> _peers = [];
  List<Map<String, dynamic>> _messages = [];
  NearbyPeer? _activeChatPeer;
  
  final _messageController = TextEditingController();
  StreamSubscription? _peersSub;
  StreamSubscription? _msgSub;
  StreamSubscription? _handshakeSub;

  @override
  void initState() {
    super.initState();
    final service = ref.read(nearbyServiceProvider);
    
    _peersSub = service.onPeersChanged.listen((list) {
      if (mounted) setState(() => _peers = list);
    });

    _msgSub = service.onMessagesChanged.listen((list) {
      if (mounted) setState(() => _messages = list);
    });

    _handshakeSub = service.onHandshakeReceived.listen((peer) {
      if (mounted) _showIncomingHandshakeDialog(peer);
    });
  }

  @override
  void dispose() {
    _peersSub?.cancel();
    _msgSub?.cancel();
    _handshakeSub?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _toggleNearbyMode(bool value) async {
    final service = ref.read(nearbyServiceProvider);
    setState(() {
      _nearbyEnabled = value;
      if (!value) {
        _activeChatPeer = null;
        _peers.clear();
        _messages.clear();
      }
    });

    if (value) {
      await service.startOfflineMode();
    } else {
      await service.stopOfflineMode();
    }
  }

  void _showIncomingHandshakeDialog(NearbyPeer peer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Incoming Connect Request', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            '${peer.realName ?? "Anonymous"} (@${peer.realUsername ?? "unknown"}) wants to connect with you offline.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(nearbyServiceProvider).declineHandshake(peer);
                Navigator.pop(context);
              },
              child: const Text('Decline', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(nearbyServiceProvider).acceptHandshake(peer);
                Navigator.pop(context);
                setState(() => _activeChatPeer = peer);
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeChatPeer == null) return;

    ref.read(nearbyServiceProvider).sendOfflineMessage(_activeChatPeer!, text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nearby Offline Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_activeChatPeer != null) {
              setState(() => _activeChatPeer = null);
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Offline banner indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Internet Disconnected',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange),
                      ),
                      Text(
                        'You can still chat locally with nearby Veyl users.',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _nearbyEnabled,
                  activeColor: theme.colorScheme.secondary,
                  onChanged: _toggleNearbyMode,
                ),
              ],
            ),
          ),

          if (!_nearbyEnabled)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_tethering_off, size: 80, color: theme.dividerColor),
                    const SizedBox(height: 24),
                    const Text(
                      'Nearby Connect is Off',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Turn on Nearby mode to discover and chat securely with other users on the same Wi-Fi or hotspot connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 32),
                    PremiumButton(
                      onPressed: () => _toggleNearbyMode(true),
                      child: const Text('Enable Offline Connect'),
                    ),
                  ],
                ),
              ),
            )
          else if (_activeChatPeer != null)
            // Active offline chat session panel
            Expanded(
              child: Column(
                children: [
                  // Active peer details header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.4))),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                          child: Icon(Icons.person, color: theme.colorScheme.secondary),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _activeChatPeer!.realName ?? _activeChatPeer!.anonymousId,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Offline Session • ${_activeChatPeer!.anonymousId}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chat Message List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final profileAsync = ref.read(userProfileProvider);
                        final myUsername = profileAsync.value?['username'] ?? 'user';
                        final isMe = msg['sender'] == myUsername;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe 
                                  ? theme.colorScheme.secondary 
                                  : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              msg['content'],
                              style: TextStyle(
                                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Input box
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: const InputDecoration(
                              hintText: 'Type offline message...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(Icons.send, color: theme.colorScheme.secondary),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            // Discovered peers list
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Nearby Devices',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: _peers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SonarRadarWidget(),
                                const SizedBox(height: 24),
                                Text(
                                  'Scanning for offline users...',
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.grey[500],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _peers.length,
                            itemBuilder: (context, index) {
                              final peer = _peers[index];
                              return HoverPeerCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            peer.realName ?? peer.anonymousId,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'IP Address: ${peer.ipAddress}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (peer.isConnected) {
                                          setState(() => _activeChatPeer = peer);
                                        } else {
                                          ref.read(nearbyServiceProvider).sendHandshakeRequest(peer);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Connection handshake request sent.')),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: peer.isConnected ? Colors.green : theme.colorScheme.secondary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        peer.isConnected ? 'Chat' : 'Connect',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Veyl Design System Premium Sonar Pulsing Scan & Hover Widgets
// -------------------------------------------------------------

class SonarRadarWidget extends StatefulWidget {
  const SonarRadarWidget({super.key});

  @override
  State<SonarRadarWidget> createState() => _SonarRadarWidgetState();
}

class _SonarRadarWidgetState extends State<SonarRadarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(120, 120),
          painter: _SonarPainter(_controller.value, theme.colorScheme.secondary),
        );
      },
    );
  }
}

class _SonarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SonarPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i / 3.0) % 1.0;
      final radius = waveProgress * maxRadius;
      final opacity = 1.0 - waveProgress;

      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);

      final fillPaint = Paint()
        ..color = color.withOpacity(opacity * 0.05)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);
    }

    // Core pulsing dot
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6.0, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HoverPeerCard extends StatefulWidget {
  final Widget child;

  const HoverPeerCard({super.key, required this.child});

  @override
  State<HoverPeerCard> createState() => _HoverPeerCardState();
}

class _HoverPeerCardState extends State<HoverPeerCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered 
                ? (isDark ? const Color(0xFF1E293B) : Colors.grey[100])
                : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? theme.colorScheme.secondary.withOpacity(0.4)
                  : (isDark ? Colors.white10 : theme.dividerColor.withOpacity(0.5)),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
