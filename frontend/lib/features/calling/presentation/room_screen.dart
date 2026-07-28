import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

import '../../../core/api_client.dart';
import '../../auth/auth_provider.dart';
import '../room_provider.dart';
import '../../chat/socket_service.dart';
import '../../../webrtc/services/peer_connection_manager.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _roomData;
  late AnimationController _pulseController;
  late TabController _tabController;
  late PeerConnectionManager _pcm;
  StreamSubscription? _roomEventSub;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMicMuted = false;
  bool _isVideoMuted = true;
  bool _isSpeakerMode = true; // true = Speaker, false = Listener
  bool _handRaised = false;
  bool _joinedCall = false;

  // Real-time Room State
  final List<Map<String, dynamic>> _attendees = [];
  final List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _tabController = TabController(length: 3, vsync: this);

    _pcm = PeerConnectionManager(
      onRemoteStream: (stream) {
        if (mounted) {
          setState(() {
            _remoteRenderer.srcObject = stream;
          });
        }
      },
    );

    _initRenderers();
    _initializeAndJoin();
    _setupSocketListeners();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _setupSocketListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = ref.read(socketServiceProvider);
      _roomEventSub = socketService.onRoomEvent.listen((event) {
        if (event['roomId'] == widget.roomId && mounted) {
          final type = event['type'];
          final user = event['user'] ?? {};
          final userName = user['displayName'] ?? user['username'] ?? 'Attendee';

          setState(() {
            if (type == 'JOIN') {
              if (!_attendees.any((a) => a['id'] == user['id'])) {
                _attendees.add(user);
              }
              _addActivity('✨ $userName joined the Live Room');
            } else if (type == 'LEAVE') {
              _attendees.removeWhere((a) => a['id'] == user['id']);
              _addActivity('👋 $userName left the Live Room');
            } else if (type == 'HAND_RAISE') {
              _addActivity('✋ $userName raised their hand');
            } else if (type == 'SPEAKING') {
              _addActivity('🎙️ $userName started speaking');
            }
          });
        }
      });
    });
  }

  void _addActivity(String message) {
    _activities.insert(0, {
      'message': message,
      'time': DateTime.now().toLocal().toString().substring(11, 16),
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tabController.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _pcm.closeConnection();
    _roomEventSub?.cancel();
    super.dispose();
  }

  void _initializeAndJoin() async {
    try {
      final authState = ref.read(authStateProvider);
      if (!authState) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        await ref.read(authProvider).guestLogin();
      }

      final room = await ref.read(roomServiceProvider).getRoom(widget.roomId);
      final profileAsync = ref.read(userProfileProvider);
      final me = profileAsync.value ?? {'displayName': 'Guest User', 'username': 'guest'};

      setState(() {
        _roomData = room;
        _isLoading = false;
        
        // Add Host & Current User to Attendees directory
        final host = room['presenter'] ?? {'displayName': 'Studio Host', 'username': 'host', 'isHost': true};
        _attendees.add(host);
        if (me['userId'] != host['userId']) {
          _attendees.add(me);
        }
        _addActivity('🎙️ Room broadcast started');
      });

      ref.read(socketServiceProvider).joinLiveRoom(widget.roomId, me);
    } catch (e) {
      final profileAsync = ref.read(userProfileProvider);
      final me = profileAsync.value ?? {'displayName': 'Guest User', 'username': 'guest'};

      setState(() {
        _roomData = {
          'id': widget.roomId,
          'name': 'My Lives Studio #' + (widget.roomId.length > 6 ? widget.roomId.substring(0, 6) : widget.roomId),
          'type': 'TEMPORARY',
          'presenter': {
            'displayName': 'Studio Host',
            'username': 'host',
            'isHost': true,
          }
        };
        _attendees.add(_roomData!['presenter']);
        _attendees.add(me);
        _isLoading = false;
        _errorMessage = null;
        _addActivity('🎙️ Studio session initialized');
      });
    }
  }

  Future<void> _connectPodcastCall({required bool asSpeaker}) async {
    final profileAsync = ref.read(userProfileProvider);
    final myName = profileAsync.value?['displayName'] ?? profileAsync.value?['username'] ?? 'User';

    setState(() {
      _isSpeakerMode = asSpeaker;
      _isMicMuted = !asSpeaker;
      _joinedCall = true;
      _addActivity(asSpeaker ? '🎙️ $myName joined as Speaker' : '🎧 $myName joined as Listener');
    });

    await _pcm.initializePeerConnection();

    if (_pcm.localStream != null) {
      _localRenderer.srcObject = _pcm.localStream;
    }

    if (asSpeaker) {
      _pcm.toggleMicrophone(!_isMicMuted);
    }
  }

  void _toggleMic() {
    final profileAsync = ref.read(userProfileProvider);
    final myName = profileAsync.value?['displayName'] ?? 'User';

    setState(() {
      _isMicMuted = !_isMicMuted;
      _addActivity(_isMicMuted ? '🔇 $myName muted microphone' : '🎙️ $myName unmuted microphone');
    });
    _pcm.toggleMicrophone(!_isMicMuted);
  }

  void _toggleVideo() {
    setState(() {
      _isVideoMuted = !_isVideoMuted;
    });
    _pcm.toggleCamera(!_isVideoMuted);
  }

  void _toggleRaiseHand() {
    final profileAsync = ref.read(userProfileProvider);
    final myName = profileAsync.value?['displayName'] ?? 'User';

    setState(() {
      _handRaised = !_handRaised;
      if (_handRaised) {
        _addActivity('✋ $myName raised hand to speak');
      }
    });

    ref.read(socketServiceProvider).emitRoomActivity(widget.roomId, {
      'type': 'HAND_RAISE',
      'user': profileAsync.value,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_handRaised ? '✋ Hand raised! Host notified.' : 'Hand lowered.'),
        backgroundColor: _handRaised ? const Color(0xFF6366F1) : Colors.grey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showShareDialog() {
    final String shareUrl = 'https://veyl.kkdes.co.ke/app.html#/room/${widget.roomId}';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'My Lives Invite & QR Code',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: shareUrl,
                  version: QrVersions.auto,
                  size: 160.0,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Room ID: ${widget.roomId}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Color(0xFF6366F1), size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.roomId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Room ID copied to clipboard!')),
                        );
                      },
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text('Share Live Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Share.share('Join my broadcast on My Lives (Veyl): $shareUrl');
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6366F1)),
              SizedBox(height: 16),
              Text(
                'Opening My Lives Studio...',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    final room = _roomData!;
    final presenter = room['presenter'] ?? {};
    final presenterName = presenter['displayName'] ?? presenter['username'] ?? 'Host Presenter';
    final presenterAvatar = presenter['profilePhotoUrl'] != null && presenter['profilePhotoUrl'].isNotEmpty
        ? (presenter['profilePhotoUrl'].startsWith('http')
            ? presenter['profilePhotoUrl']
            : '${getBaseUrl()}${presenter['profilePhotoUrl']}')
        : 'https://api.dicebear.com/7.x/bottts/png?seed=${presenter['username'] ?? 'host'}';

    final speakersCount = _attendees.where((a) => a['isHost'] == true || a['isSpeaker'] == true).length + 1;
    final totalAttendeesCount = _attendees.length;
    final listenersCount = (totalAttendeesCount - speakersCount).clamp(0, 9999);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room['name'] ?? 'My Lives Studio',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Row(
              children: [
                const CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  'LIVE • $totalAttendeesCount ATTENDEES ($speakersCount SPEAKERS)',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _showShareDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: [
            const Tab(text: '🎙️ Stage'),
            Tab(text: '👥 Attendees ($totalAttendeesCount)'),
            const Tab(text: '⚡ Activity'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Live Stats Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBadge(Icons.people_alt, '$totalAttendeesCount Total Attendees', const Color(0xFF6366F1)),
                  _buildStatBadge(Icons.mic, '$speakersCount Speakers', const Color(0xFF10B981)),
                  _buildStatBadge(Icons.headphones, '$listenersCount Listeners', Colors.amber),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Stage & Speaker Grid
                  _buildStageTab(presenterName, presenterAvatar),

                  // Tab 2: All Attendees List
                  _buildAttendeesTab(),

                  // Tab 3: Live Activity Stream
                  _buildActivityTab(),
                ],
              ),
            ),

            // Controls Bar
            if (!_joinedCall) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose How to Participate',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.mic, color: Colors.white, size: 18),
                            label: const Text('Join as Speaker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () => _connectPodcastCall(asSpeaker: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.headphones, color: Color(0xFF6366F1), size: 18),
                            label: const Text('Listen Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () => _connectPodcastCall(asSpeaker: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Active Call Controls Dock
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isMicMuted ? Icons.mic_off : Icons.mic,
                        color: _isMicMuted ? Colors.redAccent : const Color(0xFF10B981),
                        size: 26,
                      ),
                      onPressed: _toggleMic,
                      tooltip: 'Toggle Microphone',
                    ),
                    IconButton(
                      icon: Icon(
                        _isVideoMuted ? Icons.videocam_off : Icons.videocam,
                        color: _isVideoMuted ? Colors.grey : const Color(0xFF6366F1),
                        size: 26,
                      ),
                      onPressed: _toggleVideo,
                      tooltip: 'Toggle Camera',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.front_hand,
                        color: _handRaised ? Colors.amberAccent : Colors.white60,
                        size: 24,
                      ),
                      onPressed: _toggleRaiseHand,
                      tooltip: 'Raise Hand',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white, size: 24),
                      onPressed: _showShareDialog,
                      tooltip: 'Invite Link',
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.call_end, color: Colors.white, size: 22),
                        onPressed: () => context.pop(),
                        tooltip: 'Leave Room',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStageTab(String presenterName, String presenterAvatar) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (!_isVideoMuted && _remoteRenderer.srcObject != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
          )
        else
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(3, (index) {
                  final progress = (_pulseController.value + index / 3) % 1.0;
                  return Container(
                    width: 140 + progress * 160,
                    height: 140 + progress * 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(1.0 - progress),
                        width: 2.5,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundImage: NetworkImage(presenterAvatar),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'HOST: $presenterName',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendeesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendees.length,
      itemBuilder: (context, index) {
        final attendee = _attendees[index];
        final name = attendee['displayName'] ?? attendee['username'] ?? 'Attendee';
        final username = attendee['username'] ?? 'user';
        final isHost = attendee['isHost'] == true || index == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '@$username',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isHost ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isHost ? '👑 Host' : '🎧 Listener',
                  style: TextStyle(
                    color: isHost ? const Color(0xFF6366F1) : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityTab() {
    if (_activities.isEmpty) {
      return const Center(
        child: Text(
          'No activity recorded yet in this session',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final act = _activities[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  act['message'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              Text(
                act['time'] ?? '',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}
