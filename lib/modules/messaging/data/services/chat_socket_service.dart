import 'dart:async';

import 'package:client/core/session/session_token_store.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Callback invoked after every successful reconnect so callers can fetch
/// messages missed during the disconnection window.
///
/// [rejoinedRooms] contains every conversationId whose room was re-joined.
typedef OnSocketReconnect = void Function(Set<int> rejoinedRooms);

/// Events emitted by the server over the /chat Socket.IO namespace.
sealed class ChatSocketEvent {}

class MessageNewEvent extends ChatSocketEvent {
  final int conversationId;
  final Map<String, dynamic> message;
  MessageNewEvent(this.conversationId, this.message);
}

class MessageUpdatedEvent extends ChatSocketEvent {
  final int conversationId;
  final Map<String, dynamic> message;
  MessageUpdatedEvent(this.conversationId, this.message);
}

class MessageReadEvent extends ChatSocketEvent {
  final int conversationId;
  final String userUid;
  final int lastReadMessageId;
  MessageReadEvent(this.conversationId, this.userUid, this.lastReadMessageId);
}

class TypingEvent extends ChatSocketEvent {
  final int conversationId;
  final String userUid;
  final bool isTyping;
  TypingEvent(this.conversationId, this.userUid, this.isTyping);
}

class ConversationClosedEvent extends ChatSocketEvent {
  final int conversationId;
  ConversationClosedEvent(this.conversationId);
}

class ConversationAccessRevokedEvent extends ChatSocketEvent {
  final int conversationId;
  ConversationAccessRevokedEvent(this.conversationId);
}

class SocketConnectedEvent extends ChatSocketEvent {}

class SocketDisconnectedEvent extends ChatSocketEvent {}

/// Manages the single Socket.IO connection to the /chat namespace.
///
/// Lifecycle:
///   - connect()    → called on first chat screen open or after login
///   - joinRoom()   → called when user opens a specific conversation
///   - leaveRoom()  → called when user leaves the conversation screen
///   - dispose()    → called on logout or app termination
///
/// The [events] stream is broadcast — multiple listeners are supported.
/// Events are strongly typed via [ChatSocketEvent] sealed class.
class ChatSocketService {
  ChatSocketService({
    required String baseUrl,
    this.onReconnect,
  }) : _baseUrl = baseUrl;

  final String _baseUrl;

  /// Called after every successful reconnect with the set of re-joined rooms.
  /// Wire this in [MessagingStore] to fetch missed messages via REST.
  final OnSocketReconnect? onReconnect;

  io.Socket? _socket;
  final _eventController = StreamController<ChatSocketEvent>.broadcast();
  final Set<int> _joinedRooms = {};
  bool _disposed = false;

  Stream<ChatSocketEvent> get events => _eventController.stream;
  bool get isConnected => _socket?.connected ?? false;

  // ── Connection lifecycle ─────────────────────────────────────────────────

  Future<void> connect() async {
    if (_disposed || isConnected) return;
    // Token material comes from SessionTokenStore, not the Hive record: after
    // the secure-storage migration the record's token field is empty, and
    // reading it here would silently stop the chat socket from connecting.
    final token = (await SessionTokenStore().read()).accessToken;
    if (token.isEmpty) return;

    _socket = io.io(
      '$_baseUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setReconnectionAttempts(double.infinity.toInt())
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(30000)
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _emit(SocketConnectedEvent());
        // Re-join all rooms on reconnect.
        final rooms = Set<int>.of(_joinedRooms);
        for (final id in rooms) {
          _joinRoomOnSocket(id);
        }
        // Notify caller to fetch messages missed during the disconnection window.
        if (rooms.isNotEmpty) onReconnect?.call(rooms);
      })
      ..onDisconnect((_) => _emit(SocketDisconnectedEvent()))
      ..onConnectError((e) {
        debugPrint('[ChatSocket] connect error: $e');
      })
      ..on('message:new', (data) {
        final d = _asMap(data);
        final convId = _convId(d);
        if (convId != null) _emit(MessageNewEvent(convId, d));
      })
      ..on('message:updated', (data) {
        final d = _asMap(data);
        final convId = _convId(d);
        if (convId != null) _emit(MessageUpdatedEvent(convId, d));
      })
      ..on('message:read', (data) {
        final d = _asMap(data);
        final convId = _convId(d);
        final uid = d['userUid'] as String?;
        final msgId = (d['lastReadMessageId'] as num?)?.toInt();
        if (convId != null && uid != null && msgId != null) {
          _emit(MessageReadEvent(convId, uid, msgId));
        }
      })
      ..on('typing', (data) {
        final d = _asMap(data);
        final convId = _convId(d);
        final uid = d['userUid'] as String?;
        final isTyping = d['isTyping'] as bool? ?? false;
        if (convId != null && uid != null) {
          _emit(TypingEvent(convId, uid, isTyping));
        }
      })
      ..on('conversation:closed', (data) {
        final d = _asMap(data);
        final convId = _convId(d);
        if (convId != null) _emit(ConversationClosedEvent(convId));
      })
      ..on('conversation:access-revoked', (data) {
        final d = _asMap(data);
        final convId = _convId(d);
        if (convId != null) {
          _joinedRooms.remove(convId);
          _emit(ConversationAccessRevokedEvent(convId));
        }
      });
  }

  // ── Room management ───────────────────────────────────────────────────────

  void joinRoom(int conversationId) {
    _joinedRooms.add(conversationId);
    if (isConnected) _joinRoomOnSocket(conversationId);
  }

  void leaveRoom(int conversationId) {
    _joinedRooms.remove(conversationId);
    _socket?.emit('conversation:leave', {'conversationId': conversationId});
  }

  // ── Typing indicator ─────────────────────────────────────────────────────

  void sendTyping({required int conversationId, required bool isTyping}) {
    if (!isConnected) return;
    _socket?.emit('message:typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  // ── Logout / Session reset ────────────────────────────────────────────────

  /// Call on logout. Disconnects the socket and clears per-session state.
  /// The event stream stays open so the singleton can reconnect later.
  void disconnect() {
    _joinedRooms.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ── App termination ───────────────────────────────────────────────────────

  /// Call only on app shutdown — closes the stream permanently.
  void dispose() {
    _disposed = true;
    disconnect();
    if (!_eventController.isClosed) {
      _eventController.close();
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  void _joinRoomOnSocket(int conversationId) {
    _socket?.emitWithAck(
        'conversation:join', {'conversationId': conversationId}, ack: (data) {
      if (data is Map && data['ok'] != true) {
        debugPrint('[ChatSocket] room join denied for $conversationId: $data');
        _joinedRooms.remove(conversationId);
      }
    });
  }

  void _emit(ChatSocketEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  static int? _convId(Map<String, dynamic> d) {
    final raw = d['conversationId'] ?? d['conversation_id'];
    return (raw as num?)?.toInt();
  }
}
