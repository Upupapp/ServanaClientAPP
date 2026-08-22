// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MessagingStore on _MessagingStore, Store {
  late final _$convsByBookingIdAtom =
      Atom(name: '_MessagingStore.convsByBookingId', context: context);

  @override
  ObservableMap<String, ConversationModel> get convsByBookingId {
    _$convsByBookingIdAtom.reportRead();
    return super.convsByBookingId;
  }

  @override
  set convsByBookingId(ObservableMap<String, ConversationModel> value) {
    _$convsByBookingIdAtom.reportWrite(value, super.convsByBookingId, () {
      super.convsByBookingId = value;
    });
  }

  late final _$totalUnreadAtom =
      Atom(name: '_MessagingStore.totalUnread', context: context);

  @override
  int get totalUnread {
    _$totalUnreadAtom.reportRead();
    return super.totalUnread;
  }

  @override
  set totalUnread(int value) {
    _$totalUnreadAtom.reportWrite(value, super.totalUnread, () {
      super.totalUnread = value;
    });
  }

  late final _$messagesByConvIdAtom =
      Atom(name: '_MessagingStore.messagesByConvId', context: context);

  @override
  ObservableMap<int, ObservableList<MessageModel>> get messagesByConvId {
    _$messagesByConvIdAtom.reportRead();
    return super.messagesByConvId;
  }

  @override
  set messagesByConvId(ObservableMap<int, ObservableList<MessageModel>> value) {
    _$messagesByConvIdAtom.reportWrite(value, super.messagesByConvId, () {
      super.messagesByConvId = value;
    });
  }

  late final _$oldestIdByConvIdAtom =
      Atom(name: '_MessagingStore.oldestIdByConvId', context: context);

  @override
  ObservableMap<int, int?> get oldestIdByConvId {
    _$oldestIdByConvIdAtom.reportRead();
    return super.oldestIdByConvId;
  }

  @override
  set oldestIdByConvId(ObservableMap<int, int?> value) {
    _$oldestIdByConvIdAtom.reportWrite(value, super.oldestIdByConvId, () {
      super.oldestIdByConvId = value;
    });
  }

  late final _$hasMoreByConvIdAtom =
      Atom(name: '_MessagingStore.hasMoreByConvId', context: context);

  @override
  ObservableMap<int, bool> get hasMoreByConvId {
    _$hasMoreByConvIdAtom.reportRead();
    return super.hasMoreByConvId;
  }

  @override
  set hasMoreByConvId(ObservableMap<int, bool> value) {
    _$hasMoreByConvIdAtom.reportWrite(value, super.hasMoreByConvId, () {
      super.hasMoreByConvId = value;
    });
  }

  late final _$isLoadingConversationsAtom =
      Atom(name: '_MessagingStore.isLoadingConversations', context: context);

  @override
  bool get isLoadingConversations {
    _$isLoadingConversationsAtom.reportRead();
    return super.isLoadingConversations;
  }

  @override
  set isLoadingConversations(bool value) {
    _$isLoadingConversationsAtom
        .reportWrite(value, super.isLoadingConversations, () {
      super.isLoadingConversations = value;
    });
  }

  late final _$isLoadingByConvIdAtom =
      Atom(name: '_MessagingStore.isLoadingByConvId', context: context);

  @override
  ObservableMap<int, bool> get isLoadingByConvId {
    _$isLoadingByConvIdAtom.reportRead();
    return super.isLoadingByConvId;
  }

  @override
  set isLoadingByConvId(ObservableMap<int, bool> value) {
    _$isLoadingByConvIdAtom.reportWrite(value, super.isLoadingByConvId, () {
      super.isLoadingByConvId = value;
    });
  }

  late final _$initForSessionAsyncAction =
      AsyncAction('_MessagingStore.initForSession', context: context);

  @override
  Future<void> initForSession() {
    return _$initForSessionAsyncAction.run(() => super.initForSession());
  }

  late final _$loadConversationsAsyncAction =
      AsyncAction('_MessagingStore.loadConversations', context: context);

  @override
  Future<void> loadConversations() {
    return _$loadConversationsAsyncAction.run(() => super.loadConversations());
  }

  late final _$openConversationAsyncAction =
      AsyncAction('_MessagingStore.openConversation', context: context);

  @override
  Future<ConversationModel?> openConversation(String bookingId) {
    return _$openConversationAsyncAction
        .run(() => super.openConversation(bookingId));
  }

  late final _$loadMessagesAsyncAction =
      AsyncAction('_MessagingStore.loadMessages', context: context);

  @override
  Future<void> loadMessages(int conversationId, {bool refresh = false}) {
    return _$loadMessagesAsyncAction
        .run(() => super.loadMessages(conversationId, refresh: refresh));
  }

  late final _$sendMessageAsyncAction =
      AsyncAction('_MessagingStore.sendMessage', context: context);

  @override
  Future<void> sendMessage(
      {required int conversationId, required String body}) {
    return _$sendMessageAsyncAction.run(
        () => super.sendMessage(conversationId: conversationId, body: body));
  }

  late final _$sendAttachmentAsyncAction =
      AsyncAction('_MessagingStore.sendAttachment', context: context);

  @override
  Future<void> sendAttachment(
      {required int conversationId,
      required String dataUri,
      required String fileName,
      required String mimeType,
      String caption = ''}) {
    return _$sendAttachmentAsyncAction.run(() => super.sendAttachment(
        conversationId: conversationId,
        dataUri: dataUri,
        fileName: fileName,
        mimeType: mimeType,
        caption: caption));
  }

  late final _$retryMessageAsyncAction =
      AsyncAction('_MessagingStore.retryMessage', context: context);

  @override
  Future<void> retryMessage(
      {required int conversationId,
      required String clientMsgId,
      required String body}) {
    return _$retryMessageAsyncAction.run(() => super.retryMessage(
        conversationId: conversationId, clientMsgId: clientMsgId, body: body));
  }

  late final _$markReadAsyncAction =
      AsyncAction('_MessagingStore.markRead', context: context);

  @override
  Future<void> markRead(int conversationId) {
    return _$markReadAsyncAction.run(() => super.markRead(conversationId));
  }

  late final _$_MessagingStoreActionController =
      ActionController(name: '_MessagingStore', context: context);

  @override
  void resetPrivateData() {
    final _$actionInfo = _$_MessagingStoreActionController.startAction(
        name: '_MessagingStore.resetPrivateData');
    try {
      return super.resetPrivateData();
    } finally {
      _$_MessagingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setConversation(ConversationModel conv) {
    final _$actionInfo = _$_MessagingStoreActionController.startAction(
        name: '_MessagingStore._setConversation');
    try {
      return super._setConversation(conv);
    } finally {
      _$_MessagingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _insertMessage(int conversationId, MessageModel message) {
    final _$actionInfo = _$_MessagingStoreActionController.startAction(
        name: '_MessagingStore._insertMessage');
    try {
      return super._insertMessage(conversationId, message);
    } finally {
      _$_MessagingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool _replaceByClientMsgId(
      int conversationId, String clientMsgId, MessageModel replacement) {
    final _$actionInfo = _$_MessagingStoreActionController.startAction(
        name: '_MessagingStore._replaceByClientMsgId');
    try {
      return super
          ._replaceByClientMsgId(conversationId, clientMsgId, replacement);
    } finally {
      _$_MessagingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _replaceById(int conversationId, MessageModel replacement) {
    final _$actionInfo = _$_MessagingStoreActionController.startAction(
        name: '_MessagingStore._replaceById');
    try {
      return super._replaceById(conversationId, replacement);
    } finally {
      _$_MessagingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _markFailed(int conversationId, String clientMsgId) {
    final _$actionInfo = _$_MessagingStoreActionController.startAction(
        name: '_MessagingStore._markFailed');
    try {
      return super._markFailed(conversationId, clientMsgId);
    } finally {
      _$_MessagingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _markPending(int conversationId, String clientMsgId) {
    final _$actionInfo = _$_MessagingStoreActionController.startAction(
        name: '_MessagingStore._markPending');
    try {
      return super._markPending(conversationId, clientMsgId);
    } finally {
      _$_MessagingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _updateConversationUnread(int conversationId, int count) {
    final _$actionInfo = _$_MessagingStoreActionController.startAction(
        name: '_MessagingStore._updateConversationUnread');
    try {
      return super._updateConversationUnread(conversationId, count);
    } finally {
      _$_MessagingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _recalcTotalUnread() {
    final _$actionInfo = _$_MessagingStoreActionController.startAction(
        name: '_MessagingStore._recalcTotalUnread');
    try {
      return super._recalcTotalUnread();
    } finally {
      _$_MessagingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
convsByBookingId: ${convsByBookingId},
totalUnread: ${totalUnread},
messagesByConvId: ${messagesByConvId},
oldestIdByConvId: ${oldestIdByConvId},
hasMoreByConvId: ${hasMoreByConvId},
isLoadingConversations: ${isLoadingConversations},
isLoadingByConvId: ${isLoadingByConvId}
    ''';
  }
}
