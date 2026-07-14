import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

final callServiceProvider = Provider((ref) => CallService());

class CallService {
  final Uuid _uuid = const Uuid();

  Future<void> joinVideoCall(String roomName, String displayName, String avatarUrl) async {
    final String cleanRoom = roomName.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
    final String urlString = 'https://meet.jit.si/veyl-$cleanRoom#userInfo.displayName="$displayName"';
    final Uri url = Uri.parse(urlString);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $urlString';
    }
  }

  Future<void> showIncomingCall(String callerName, String avatarUrl, String roomId) async {
    await joinVideoCall(roomId, "Guest User", avatarUrl);
  }
}
