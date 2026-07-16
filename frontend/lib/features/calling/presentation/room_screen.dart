import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../auth/auth_provider.dart';
import '../call_service.dart';
import '../room_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _roomData;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _initializeAndJoin();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _initializeAndJoin() async {
    try {
      final authState = ref.read(authStateProvider);
      
      // Auto guest login if unauthenticated
      if (!authState) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        await ref.read(authProvider).guestLogin();
      }

      // Fetch Room Details
      final room = await ref.read(roomServiceProvider).getRoom(widget.roomId);
      setState(() {
        _roomData = room;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final currentUserId = profileAsync.value?['userId'] ?? '';
    final currentUsername = profileAsync.value?['username'] ?? 'Guest';

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F111A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF5D3FD3)),
              SizedBox(height: 16),
              Text(
                'Connecting to breakout room...',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F111A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'Could Not Join Room',
                  style: TextStyle(color: theme.colorScheme.onBackground, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final room = _roomData!;
    final presenter = room['presenter'] ?? {};
    final presenterId = room['presenterId'] ?? '';
    final isPresenter = presenterId == currentUserId;
    
    final presenterName = presenter['displayName'] ?? presenter['username'] ?? 'Presenter';
    final presenterAvatar = presenter['profilePhotoUrl'] != null && presenter['profilePhotoUrl'].isNotEmpty
        ? '${getBaseUrl()}${presenter['profilePhotoUrl']}'
        : 'https://i.pravatar.cc/150?u=${presenter['username'] ?? 'presenter'}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          room['name'] ?? 'Breakout Room',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Presenter Radar/Visual Indicator
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Radar Pulsating Rings
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: List.generate(3, (index) {
                            final progress = (_radarController.value + index / 3) % 1.0;
                            return Container(
                              width: 120 + progress * 160,
                              height: 120 + progress * 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF5D3FD3).withOpacity(1.0 - progress),
                                  width: 2,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    // Presenter Avatar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5D3FD3),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundImage: NetworkImage(presenterAvatar),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D3FD3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('PRESENTER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Host Information
            Text(
              isPresenter ? 'You are the Host' : '$presenterName is presenting',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              room['type'] == 'TEMPORARY' ? 'Breakout Room (Temporary)' : 'Permanent Channel',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            
            const SizedBox(height: 48),

            // Room Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161825),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPresenter ? Icons.settings_voice : Icons.headset,
                      color: const Color(0xFF5D3FD3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPresenter ? 'Presenter Controls' : 'Listener Mode Only',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isPresenter 
                              ? 'Your voice will be broadcast live to all guests.' 
                              : 'You are joined as a listener. Microphones are muted.',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Connect Live Call Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3FD3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 8,
                  shadowColor: const Color(0xFF5D3FD3).withOpacity(0.4),
                ),
                child: Text(
                  isPresenter ? 'Start Broadcast' : 'Listen Live',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  if (isPresenter) {
                    // Presenter joins with audio and video enabled
                    await ref.read(callServiceProvider).joinVideoCall(
                      widget.roomId,
                      currentUsername,
                      presenterAvatar,
                    );
                  } else {
                    // Guests join in audio-muted listener mode (can only listen to the presenter)
                    final cleanRoom = widget.roomId.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
                    final urlString = 'https://meet.jit.si/veyl-$cleanRoom#userInfo.displayName="$currentUsername"&config.startWithAudioMuted=true&config.startWithVideoMuted=true';
                    final Uri url = Uri.parse(urlString);
                    
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not join the stream')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
