import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isHandlingScan = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isHandlingScan) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() => _isHandlingScan = true);
      final String code = barcodes.first.rawValue!;
      
      // Navigate to user profile based on QR code data
      // e.g., if code is veyl://profile/ABC123XYZ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned: $code')),
      );
      
      // Delay to avoid multiple scans
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isHandlingScan = false);
        context.pop();
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
