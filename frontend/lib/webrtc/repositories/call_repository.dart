import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../models/call_session.dart';

final activeCallSessionProvider = StateProvider<CallSession?>((ref) => null);

final callHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/calling/history');
  return response.data as List<dynamic>;
});

final callRepositoryProvider = Provider((ref) => CallRepository(ref));

class CallRepository {
  final Ref _ref;
  CallRepository(this._ref);

  void setActiveSession(CallSession session) {
    _ref.read(activeCallSessionProvider.notifier).state = session;
  }

  void updateState(CallState state) {
    final current = _ref.read(activeCallSessionProvider);
    if (current != null) {
      _ref.read(activeCallSessionProvider.notifier).state = current.copyWith(state: state);
    }
  }

  void endSession() {
    _ref.read(activeCallSessionProvider.notifier).state = null;
  }
}
