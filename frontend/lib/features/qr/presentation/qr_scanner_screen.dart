import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../chat/chat_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _isHandlingScan = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isHandlingScan) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() => _isHandlingScan = true);
      final String code = barcodes.first.rawValue!.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ QR Code Scanned! Opening Veyl...'),
          duration: Duration(seconds: 2),
        ),
      );

      // 1. Temporary Claim Invite Links: e.g., "https://veyl.kkdes.co.ke/app.html#/claim/TOKEN"
      if (code.contains('/claim/')) {
        final parts = code.split('/claim/');
        if (parts.length > 1) {
          final token = parts.last.split('?').first.split('#').first;
          if (mounted) {
            context.go('/claim/$token');
            return;
          }
        }
      }

      // 2. Podcast & Breakout Rooms: e.g., "https://veyl.kkdes.co.ke/app.html#/room/ROOM_ID"
      if (code.contains('/room/')) {
        final parts = code.split('/room/');
        if (parts.length > 1) {
          final roomId = parts.last.split('?').first.split('#').first;
          if (mounted) {
            context.go('/room/$roomId');
            return;
          }
        }
      }

      // 3. User Profile Links: e.g. "https://veyl.kkdes.co.ke/app.html#/user/sarah"
      if (code.contains('/user/')) {
        final parts = code.split('/user/');
        if (parts.length > 1) {
          final username = parts.last.split('?').first.split('#').first;
          if (mounted) {
            context.go('/user/$username');
            return;
          }
        }
      }

      // 4. Raw Username or Profile Link: e.g. "https://veyl.kkdes.co.ke/sarah" or "@sarah"
      String contactUsername = code;
      if (contactUsername.contains('://')) {
        try {
          final uri = Uri.parse(contactUsername);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            contactUsername = pathSegments.last;
          }
        } catch (_) {}
      }

      if (contactUsername.startsWith('@')) {
        contactUsername = contactUsername.substring(1);
      }

      if (contactUsername.isNotEmpty) {
        if (mounted) {
          context.go('/user/$contactUsername');
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
