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
      final String code = barcodes.first.rawValue!;
      
      // Check if temporary invite link
      if (code.contains('/claim/')) {
        final parts = code.split('/claim/');
        if (parts.length > 1) {
          final token = parts.last;
          if (mounted) {
            context.go('/claim/$token');
            return;
          }
        }
      }

      // Parse username from scanned URL: e.g., "https://veyl.kkdes.co.ke/sarah" -> "sarah"
      String contactUsername = code.trim();
      if (contactUsername.contains('://')) {
        try {
          final uri = Uri.parse(contactUsername);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            contactUsername = pathSegments.last;
          }
        } catch (_) {
          // Fallback to raw scanned code if parsing fails
        }
      }

      // Strip leading "@" if present
      if (contactUsername.startsWith('@')) {
        contactUsername = contactUsername.substring(1);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Starting chat with @$contactUsername...')),
      );

      try {
        final chatId = await ref.read(chatProvider).createChatByUsername(contactUsername);
        if (mounted) {
          ref.invalidate(userChatsProvider); // Refresh chat list
          context.go('/chat/$chatId');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found or chat initialization failed')),
          );
          // Wait before allowing another scan
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() => _isHandlingScan = false);
          }
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
