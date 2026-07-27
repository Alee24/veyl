import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  /// Plays a futuristic chime sound and triggers haptic vibration for incoming messages
  static Future<void> playMessageAlert(BuildContext? context, {required String title, required String body}) async {
    try {
      await _audioPlayer.stop();
      try {
        await _audioPlayer.play(AssetSource('audio/futuristic_notification.wav'));
      } catch (_) {
        await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2874/2874-84.wav'));
      }
    } catch (e) {
      debugPrint('Failed to play notification chime: $e');
    }

    // 2. Trigger Haptic Vibration
    try {
      HapticFeedback.vibrate();
    } catch (_) {}

    // 3. Show floating toast notification if context is provided
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
