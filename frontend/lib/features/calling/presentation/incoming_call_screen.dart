import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14141B),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('9:41', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Icon(Icons.signal_cellular_alt, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      const Icon(Icons.wifi, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      const Icon(Icons.battery_full, color: Colors.white, size: 16),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage('https://i.pravatar.cc/300?u=1'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sarah Johnson',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Incoming Voice Call',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const Spacer(flex: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Icon(Icons.alarm, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    const Text('Remind Me', style: TextStyle(color: Colors.white)),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.message, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    const Text('Message', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCallButton(Icons.call_end, Colors.red, () => context.pop()),
                _buildCallButton(Icons.call, Colors.green, () => context.pushReplacement('/video_call')),
              ],
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text('Decline', style: TextStyle(color: Colors.white, fontSize: 16)),
                const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}
