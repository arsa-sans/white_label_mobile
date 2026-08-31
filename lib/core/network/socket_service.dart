import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

/// Singleton Socket.IO service for real-time communication with backend.
///
/// Connects to the WhiteLabel backend WebSocket server and listens for
/// gate scan events, enabling real-time notifications across devices.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  sio.Socket? _socket;
  bool _isConnected = false;
  final SecureStorageService _storage = SecureStorageService();

  /// Whether the socket is currently connected
  bool get isConnected => _isConnected;

  /// Callback for incoming gate scan results from other devices
  void Function(Map<String, dynamic> data)? onGateScanResult;

  /// Callback for sync completion events
  void Function(Map<String, dynamic> data)? onSyncCompleted;

  /// Initialize and connect to Socket.IO backend server.
  /// Uses the same base URL as the REST API (minus /api/v1).
  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    // Extract base server URL from API endpoint (remove /api/v1 suffix)
    final customBaseUrl = await _storage.getBaseUrl();
    final effectiveUrl = (customBaseUrl != null && customBaseUrl.trim().isNotEmpty)
        ? customBaseUrl.trim()
        : ApiEndpoints.baseUrl;
    final serverUrl = effectiveUrl.replaceAll('/api/v1', '');

    _socket = sio.io(
      serverUrl,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(10)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      // ignore: avoid_print
      print('[SocketService] Connected to backend WebSocket');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      // ignore: avoid_print
      print('[SocketService] Disconnected from WebSocket');
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
      // ignore: avoid_print
      print('[SocketService] Connection error: $err');
    });

    // Listen for gate scan results (from any device)
    _socket!.on('gate:scan_result', (data) {
      if (data is Map<String, dynamic>) {
        onGateScanResult?.call(data);
      } else if (data is Map) {
        onGateScanResult?.call(Map<String, dynamic>.from(data));
      }
    });

    // Listen for sync completion events
    _socket!.on('gate:sync_completed', (data) {
      if (data is Map<String, dynamic>) {
        onSyncCompleted?.call(data);
      } else if (data is Map) {
        onSyncCompleted?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  /// Join an event-specific room for targeted notifications
  void joinEventRoom(String eventId) {
    _socket?.emit('join_event_room', eventId);
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
