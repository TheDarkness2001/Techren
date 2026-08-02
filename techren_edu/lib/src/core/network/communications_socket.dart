import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

typedef SocketPayloadHandler = void Function(dynamic data);

class CommunicationsSocket {
  CommunicationsSocket(this._storage);

  final SecureStorageService _storage;
  io.Socket? _socket;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) return;

    final api = Uri.parse(ApiConstants.baseUrl);
    final origin = '${api.scheme}://${api.host}${api.hasPort ? ':${api.port}' : ''}';

    _socket?.dispose();
    _socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      if (kDebugMode) debugPrint('Communications socket connected');
    });
    _socket!.onConnectError((e) {
      if (kDebugMode) debugPrint('Communications socket error: $e');
    });
  }

  void joinRoom(String conversationId) {
    _socket?.emit('join-room', conversationId);
  }

  void leaveRoom(String conversationId) {
    _socket?.emit('leave-room', conversationId);
  }

  void typing(String conversationId) {
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  void stopTyping(String conversationId) {
    _socket?.emit('stop-typing', {'conversationId': conversationId});
  }

  void joinPoll(String pollId) {
    _socket?.emit('join-poll', pollId);
  }

  void leavePoll(String pollId) {
    _socket?.emit('leave-poll', pollId);
  }

  void on(String event, SocketPayloadHandler handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [SocketPayloadHandler? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
