import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionInitializer {
  /// Requests core calling and notification permissions on app startup.
  static Future<void> requestAppPermissions(BuildContext context) async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
    ].request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    final notifGranted = statuses[Permission.notification]?.isGranted ?? false;

    if (!cameraGranted || !micGranted || !notifGranted) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF161E2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF6366F1), size: 24),
                SizedBox(width: 10),
                Text(
                  'Permissions Required',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: const Text(
              'Veyl requires Camera, Microphone, and Notification permissions to receive and place encrypted Voice & Video calls in real-time.\n\nPlease enable them in Settings.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Later', style: TextStyle(color: Colors.grey)),
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
    }
  }
}
