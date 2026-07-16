import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

final callServiceProvider = Provider((ref) => CallService());

class CallService {

  /// Requests camera and microphone permissions.
  /// Returns true if both are granted (or already granted).
  /// Shows a settings dialog if permanently denied.
  Future<bool> requestCallPermissions(BuildContext context) async {
    // Check current status first
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    // If already granted, proceed immediately
    if (cameraStatus.isGranted && micStatus.isGranted) return true;

    // Request both together
    final results = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraGranted = results[Permission.camera]?.isGranted ?? false;
    final micGranted = results[Permission.microphone]?.isGranted ?? false;

    if (cameraGranted && micGranted) return true;

    // Handle permanent denial — guide user to Settings
    final cameraPerm = results[Permission.camera];
    final micPerm = results[Permission.microphone];
    if (cameraPerm?.isPermanentlyDenied == true || micPerm?.isPermanentlyDenied == true) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF161E2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.videocam_off, color: Colors.redAccent, size: 24),
                SizedBox(width: 10),
                Text('Permissions Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: const Text(
              'Veyl needs camera and microphone access to make calls.\n\nPlease go to Settings → Apps → Veyl → Permissions and enable Camera and Microphone.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await openAppSettings();
                },
                child: const Text('Open Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return false;
    }

    // Soft denial — show explanation
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera and microphone access is required to make calls.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4),
        ),
      );
    }
    return false;
  }

  /// Requests microphone-only permission (for voice-only calls).
  Future<bool> requestMicPermission(BuildContext context) async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final result = await Permission.microphone.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied && context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mic_off, color: Colors.redAccent, size: 24),
              SizedBox(width: 10),
              Text('Microphone Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Veyl needs microphone access to make voice calls. Enable it in Settings → Apps → Veyl → Permissions.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await openAppSettings();
              },
              child: const Text('Open Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for voice calls.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    return false;
  }

  /// Joins a Jitsi Meet video/voice call via URL launch.
  /// [videoEnabled] — true for video call, false for voice only.
  Future<void> joinVideoCall(
    String roomName,
    String displayName,
    String avatarUrl, {
    bool videoEnabled = true,
  }) async {
    final String cleanRoom = roomName.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
    final encodedName = Uri.encodeComponent(displayName);

    // Build Jitsi URL with config overrides
    final buffer = StringBuffer('https://meet.jit.si/veyl-$cleanRoom');
    buffer.write('#userInfo.displayName="$encodedName"');
    if (!videoEnabled) {
      buffer.write('&config.startWithVideoMuted=true');
    }
    buffer.write('&config.prejoinPageEnabled=false');
    buffer.write('&config.disableDeepLinking=true');

    final Uri url = Uri.parse(buffer.toString());

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not open the video call. Please make sure a browser is installed.');
    }
  }

  /// Voice-only call — same as joinVideoCall with video muted.
  Future<void> joinVoiceCall(String roomName, String displayName) async {
    await joinVideoCall(roomName, displayName, '', videoEnabled: false);
  }
}
