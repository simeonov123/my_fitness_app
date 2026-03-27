import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/training_session_realtime_event.dart';
import 'auth_service.dart';
import 'dev_endpoints.dart';

class TrainingSessionRealtimeService {
  final AuthService _auth = AuthService();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _controller =
      StreamController<TrainingSessionRealtimeEvent>.broadcast();

  Stream<TrainingSessionRealtimeEvent> get stream => _controller.stream;

  Future<void> connect({
    String? token,
    required int sessionId,
  }) async {
    await disconnect();

    final resolvedToken = token ?? await _auth.getValidAccessToken();
    if (resolvedToken == null) {
      throw Exception('Not authenticated – please log in again.');
    }

    final base = _wsBaseUrl;
    final uri = Uri.parse(
      '$base/ws/training-sessions/$sessionId?token=${Uri.encodeQueryComponent(resolvedToken)}',
    );

    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _subscription = channel.stream.listen(
      (dynamic message) {
        if (message is! String) return;
        final decoded = jsonDecode(message) as Map<String, dynamic>;
        _controller.add(TrainingSessionRealtimeEvent.fromJson(decoded));
      },
      onError: (_) {},
      onDone: () {},
      cancelOnError: false,
    );
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  static String get _wsBaseUrl {
    if (apiBaseUrl.startsWith('https://')) {
      return apiBaseUrl.replaceFirst('https://', 'wss://');
    }
    return apiBaseUrl.replaceFirst('http://', 'ws://');
  }
}
