import 'dart:async';
import 'dart:math' as math;

import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/observability/performance_service.dart';
import 'package:client/core/observability/trace_name_registry.dart';
import 'package:client/core/analytics/events/message_events.dart';
import 'package:client/core/analytics/events/recovery_events.dart';
import 'package:client/modules/messaging/data/mappers/message_mapper.dart';
import 'package:client/modules/messaging/data/models/conversation_model.dart';
import 'package:client/modules/messaging/data/models/message_model.dart';
import 'package:client/modules/messaging/data/services/chat_socket_service.dart';
import 'package:client/modules/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'messaging_store.g.dart';

class MessagingStore extends _MessagingStore with _$MessagingStore {
  MessagingStore({
    required super.repository,
    required super.socketService,
  });
}

abstract class _MessagingStore with Store {
  _MessagingStore({
    required this.repository,
    required this.socketService,
  });

  final MessagingRepository repository;
  final ChatSocketService socketService;

  /// Incremented on resetPrivateData. In-flight futures check this
  /// before writing results (LEAKSHIELD §7 pattern).
  int _generation = 0;

  StreamSubscription<ChatSocketEvent>? _socketSub;

  // ── Observables ────────────────────────────────────────────────────────────

  /// bookingId → resolved ConversationModel (populated after listConversations)
  @observable
  ObservableMap<String, ConversationModel> convsByBookingId = ObservableMap();

  /// Total unread across all conversations — drives the Messages tab badge
  @observable
  int totalUnread = 0;

  /// conversationId → list of messages (oldest at index 0, newest at end)
  @observable
  ObservableMap<int, ObservableList<MessageModel>> messagesByConvId =
      ObservableMap();

  /// conversationId → oldest message id loaded (null = not loaded yet)
  @observable
  ObservableMap<int, int?> oldestIdByConvId = ObservableMap();

  /// conversationId → true when there are older messages to fetch
  @observable
  ObservableMap<int, bool> hasMoreByConvId = ObservableMap();

  @observable
  bool isLoadingConversations = false;

  /// conversationId → currently-loading flag
  @observable
  ObservableMap<int, bool> isLoadingByConvId = ObservableMap();

  // ── Session lifecycle ──────────────────────────────────────────────────────

  /// Call after login. Connects the socket, subscribes to events, and loads
  /// the initial conversation list.
  @action
  Future<void> initForSession() async {
    _socketSub?.cancel();
    _socketSub = socketService.events.listen(_onSocketEvent);
    await socketService.connect();
    await loadConversations();
  }

  /// Call on logout. Clears all private data and disconnects the socket.
  @action
  void resetPrivateData() {
    _generation++;
    _socketSub?.cancel();
    _socketSub = null;
    socketService.disconnect();
    convsByBookingId.clear();
    messagesByConvId.clear();
    oldestIdByConvId.clear();
    hasMoreByConvId.clear();
    isLoadingByConvId.clear();
    totalUnread = 0;
    isLoadingConversations = false;
  }

  // ── Conversation list ──────────────────────────────────────────────────────

  @action
  Future<void> loadConversations() async {
    isLoadingConversations = true;
    final gen = _generation;
    try {
      final list = await repository.listConversations();
      if (_generation != gen) return;
      convsByBookingId.clear();
      for (final c in list) {
        convsByBookingId[c.bookingId] = c;
      }
      _recalcTotalUnread();
    } catch (e) {
      debugPrint('[MessagingStore] loadConversations error: $e');
    } finally {
      if (_generation == gen) isLoadingConversations = false;
    }
  }

  /// Resolves the conversation for a booking on demand (called when user opens
  /// a chat screen for a booking not yet in convsByBookingId).
  /// The conversation for [bookingId], or null when the backend says there is
  /// not one yet.
  ///
  /// **Null means absent, and nothing else.** This used to catch everything and
  /// return null, so a 403, a 500, a 502 and a dead socket were all reported to
  /// the customer as:
  ///
  ///   "This conversation is not available yet. It opens once a provider
  ///    accepts the booking."
  ///
  /// — the screen's copy for the one case null is supposed to mean. During an
  /// outage every customer opening a chat that already existed was told their
  /// provider had not accepted yet, which is a fact about their booking that
  /// the app had not learned and that was not true.
  ///
  /// The data source already draws the line correctly: 404 becomes null, and
  /// everything else rethrows. This is the layer that was erasing it. The chat
  /// screen has carried a `catch` for exactly this since it was written; it
  /// could simply never fire.
  Future<ConversationModel?> resolveConversation(String bookingId) async {
    if (convsByBookingId.containsKey(bookingId)) {
      return convsByBookingId[bookingId];
    }
    final conv = await repository.resolveForBooking(bookingId);
    if (conv != null) {
      _setConversation(conv);
    }
    return conv;
  }

  // ── Message loading ────────────────────────────────────────────────────────

  /// Open a conversation: resolve it if needed, load the first page of messages,
  /// and join the Socket.IO room.
  @action
  Future<ConversationModel?> openConversation(String bookingId) async {
    final gen = _generation;
    var conv = convsByBookingId[bookingId];
    conv ??= await resolveConversation(bookingId);
    if (conv == null || _generation != gen) return conv;

    final convId = conv.id;
    socketService.joinRoom(convId);

    final alreadyLoaded = messagesByConvId.containsKey(convId);
    if (!alreadyLoaded) {
      await loadMessages(convId, refresh: true);
    }
    return conv;
  }

  /// Call when the user leaves the chat screen.
  void closeConversation(int conversationId) {
    socketService.leaveRoom(conversationId);
  }

  @action
  Future<void> loadMessages(int conversationId, {bool refresh = false}) async {
    if (isLoadingByConvId[conversationId] == true) return;
    isLoadingByConvId[conversationId] = true;
    final gen = _generation;
    try {
      final messages = await _perf(
          TraceNames.conversationLoad,
          () async => repository.getMessages(
                conversationId: conversationId,
                limit: 40,
                before: refresh ? null : oldestIdByConvId[conversationId],
              ));
      if (_generation != gen) return;

      final list = messagesByConvId.putIfAbsent(
        conversationId,
        () => ObservableList<MessageModel>(),
      );

      if (refresh) {
        list.clear();
        oldestIdByConvId[conversationId] = null;
      }

      // Backend returns newest-first; we reverse so index 0 = oldest.
      final reversed = messages.reversed.toList();
      list.insertAll(0, reversed);

      // Track the oldest message id for subsequent page loads.
      if (messages.isNotEmpty) {
        final oldest =
            messages.reduce((a, b) => (a.id ?? 0) < (b.id ?? 0) ? a : b);
        oldestIdByConvId[conversationId] = oldest.id;
      }
      hasMoreByConvId[conversationId] = messages.length >= 40;
    } catch (e) {
      debugPrint('[MessagingStore] loadMessages error: $e');
    } finally {
      if (_generation == gen) isLoadingByConvId[conversationId] = false;
    }
  }

  Future<void> loadMoreMessages(int conversationId) {
    return loadMessages(conversationId);
  }

  // ── Sending ────────────────────────────────────────────────────────────────

  @action
  Future<void> sendMessage({
    required int conversationId,
    required String body,
  }) async {
    final clientMsgId = _generateClientMsgId();
    final gen = _generation;

    // Optimistic: add a pending message immediately.
    final pending = MessageModel(
      conversationId: conversationId,
      senderRole: 3, // customer role
      type: MessageType.text,
      body: body,
      createdAt: DateTime.now(),
      clientMsgId: clientMsgId,
      sendStatus: MessageSendStatus.pending,
    );
    _insertMessage(conversationId, pending);
    _track(const MessageSendStartedEvent(contentType: 'text'));

    try {
      final confirmed = await repository.sendMessage(
        conversationId: conversationId,
        body: body,
        clientMsgId: clientMsgId,
      );
      if (_generation != gen) return;
      // Replace optimistic message with confirmed server message.
      _replaceByClientMsgId(conversationId, clientMsgId, confirmed);
      _track(const MessageSendSucceededEvent(contentType: 'text'));
    } catch (e) {
      if (_generation != gen) return;
      debugPrint('[MessagingStore] sendMessage error: $e');
      _markFailed(conversationId, clientMsgId);
      _track(const MessageSendFailedEvent(
          contentType: 'text', failureCode: 'api_error'));
    }
  }

  @action
  Future<void> retryMessage({
    required int conversationId,
    required String clientMsgId,
    required String body,
  }) async {
    final gen = _generation;
    _markPending(conversationId, clientMsgId);
    _track(const MessageRetrySelectedEvent());
    try {
      final confirmed = await repository.sendMessage(
        conversationId: conversationId,
        body: body,
        clientMsgId: clientMsgId,
      );
      if (_generation != gen) return;
      _replaceByClientMsgId(conversationId, clientMsgId, confirmed);
      _track(const MessageSendSucceededEvent(contentType: 'text'));
    } catch (e) {
      if (_generation != gen) return;
      _markFailed(conversationId, clientMsgId);
      _track(const MessageSendFailedEvent(
          contentType: 'text', failureCode: 'api_error'));
    }
  }

  // ── Read receipts ──────────────────────────────────────────────────────────

  @action
  Future<void> markRead(int conversationId) async {
    final list = messagesByConvId[conversationId];
    if (list == null || list.isEmpty) return;
    final lastConfirmed = list.lastWhere(
      (m) => m.id != null && m.sendStatus == MessageSendStatus.sent,
      orElse: () => list.last,
    );
    final msgId = lastConfirmed.id;
    if (msgId == null) return;

    try {
      await repository.markRead(
        conversationId: conversationId,
        lastReadMessageId: msgId,
      );
      // Reset unread count for this conversation locally.
      _updateConversationUnread(conversationId, 0);
      _track(const ConversationMarkedReadEvent());
    } catch (e) {
      debugPrint('[MessagingStore] markRead error: $e');
    }
  }

  // ── Socket event handler ──────────────────────────────────────────────────

  void _onSocketEvent(ChatSocketEvent event) {
    switch (event) {
      case MessageNewEvent(:final conversationId, :final message):
        final model =
            MessageMapper.fromJson(message, conversationId: conversationId);
        // If a pending message with the same clientMsgId exists, replace it.
        final clientId = model.clientMsgId;
        if (clientId != null) {
          final replaced =
              _replaceByClientMsgId(conversationId, clientId, model);
          if (replaced) break;
        }
        _insertMessage(conversationId, model);
        // Increment unread count for conversations not currently open.
        _updateConversationUnread(
          conversationId,
          (convsByBookingId.values
                      .where((c) => c.id == conversationId)
                      .firstOrNull
                      ?.unreadCount ??
                  0) +
              1,
        );

      case MessageUpdatedEvent(:final conversationId, :final message):
        final model =
            MessageMapper.fromJson(message, conversationId: conversationId);
        _replaceById(conversationId, model);

      case MessageReadEvent(:final conversationId):
        _updateConversationUnread(conversationId, 0);

      case SocketConnectedEvent():
        _syncAfterReconnect();

      case SocketDisconnectedEvent():
      case TypingEvent():
      case ConversationClosedEvent():
        break;
      case ConversationAccessRevokedEvent(:final conversationId):
        messagesByConvId.remove(conversationId);
        oldestIdByConvId.remove(conversationId);
        hasMoreByConvId.remove(conversationId);
        final bookingKeys = convsByBookingId.entries
            .where((entry) => entry.value.id == conversationId)
            .map((entry) => entry.key)
            .toList(growable: false);
        for (final key in bookingKeys) {
          convsByBookingId.remove(key);
        }
        _recalcTotalUnread();
    }
  }

  /// Re-syncs messages and conversation list after a socket reconnect.
  /// Guards against the initial connect (when convsByBookingId is still empty)
  /// so it does not duplicate the load that [initForSession] already performs.
  void _syncAfterReconnect() {
    if (convsByBookingId.isEmpty) return;
    _track(const RecoverySocketReconnectedEvent());
    for (final convId in messagesByConvId.keys.toList()) {
      loadMessages(convId, refresh: true);
    }
    loadConversations();
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  @action
  void _setConversation(ConversationModel conv) {
    convsByBookingId[conv.bookingId] = conv;
    _recalcTotalUnread();
  }

  @action
  void _insertMessage(int conversationId, MessageModel message) {
    final list = messagesByConvId.putIfAbsent(
      conversationId,
      () => ObservableList<MessageModel>(),
    );
    list.add(message);
  }

  @action
  bool _replaceByClientMsgId(
    int conversationId,
    String clientMsgId,
    MessageModel replacement,
  ) {
    final list = messagesByConvId[conversationId];
    if (list == null) return false;
    final idx = list.indexWhere((m) => m.clientMsgId == clientMsgId);
    if (idx < 0) return false;
    list[idx] = replacement;
    return true;
  }

  @action
  void _replaceById(int conversationId, MessageModel replacement) {
    final list = messagesByConvId[conversationId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == replacement.id);
    if (idx >= 0) {
      list[idx] = replacement;
    }
  }

  @action
  void _markFailed(int conversationId, String clientMsgId) {
    final list = messagesByConvId[conversationId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.clientMsgId == clientMsgId);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(sendStatus: MessageSendStatus.failed);
    }
  }

  @action
  void _markPending(int conversationId, String clientMsgId) {
    final list = messagesByConvId[conversationId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.clientMsgId == clientMsgId);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(sendStatus: MessageSendStatus.pending);
    }
  }

  @action
  void _updateConversationUnread(int conversationId, int count) {
    final entry = convsByBookingId.entries
        .where((e) => e.value.id == conversationId)
        .firstOrNull;
    if (entry == null) return;
    convsByBookingId[entry.key] = entry.value.copyWith(unreadCount: count);
    _recalcTotalUnread();
  }

  @action
  void _recalcTotalUnread() {
    totalUnread =
        convsByBookingId.values.fold(0, (sum, c) => sum + c.unreadCount);
  }

  // ── Analytics ──────────────────────────────────────────────────────────────

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static final _rng = math.Random();

  static String _generateClientMsgId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = _rng.nextInt(0xFFFFFF);
    // The backend requires 16+ characters. Padding avoids rare short random
    // values turning an otherwise valid send into a deterministic 422.
    return '${ts.toRadixString(16)}-${rand.toRadixString(16).padLeft(8, '0')}';
  }

  Future<T> _perf<T>(String name, Future<T> Function() fn) async {
    if (!dpLocator.isRegistered<PerformanceService>()) return fn();
    return dpLocator<PerformanceService>().traced(name, fn);
  }
}
