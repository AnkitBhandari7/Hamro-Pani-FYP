import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketTrackingService {
  final String serverUrl;
  io.Socket? _socket;

  SocketTrackingService({required this.serverUrl});

  bool get isConnected => _socket?.connected == true;

  void connect() {
    _socket ??= io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() // we call connect manually
          .build(),
    );

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void joinTrip(String tripId) {
    _socket?.emit('tracking:join', {'tripId': tripId});
  }

  /// Driver sends location updates
  void sendUpdate({
    required String tripId,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
  }) {
    _socket?.emit('tracking:update', {
      'tripId': tripId,
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speed': speed,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Customer listens for driver location
  void onPosition(void Function(Map<String, dynamic> data) handler) {
    _socket?.on('tracking:position', (payload) {
      if (payload is Map) {
        handler(payload.map((k, v) => MapEntry(k.toString(), v)));
      }
    });
  }

  void onConnect(void Function() handler) {
    _socket?.onConnect((_) => handler());
  }

  void onDisconnect(void Function() handler) {
    _socket?.onDisconnect((_) => handler());
  }

  void onError(void Function(dynamic err) handler) {
    _socket?.onError((err) => handler(err));
  }
}