import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:client/core/media/upload_preparation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:client/modules/bookings/domain/booking_provider_profile.dart';
import 'package:client/common/services/error_message_mapper.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/responsive/servana_responsive.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/events/message_events.dart';
import 'package:client/modules/messaging/data/models/message_model.dart';
import 'package:client/modules/messaging/presentation/stores/messaging_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';

class BookingChatScreen extends StatefulWidget {
  static String routeName = "BookingChat";
  static String route = "/BookingChat/:jobOrderId";

  const BookingChatScreen({
    super.key,
    required this.jobOrderId,
    this.title,
  });

  final String jobOrderId;
  final String? title;

  @override
  State<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends State<BookingChatScreen> {
  final _store = dpLocator<MessagingStore>();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  final _timeFormat = DateFormat('h:mm a');

  int? _conversationId;

  /// True while a photo is being read, compressed and uploaded. Distinct from
  /// the store's per-message pending state: this covers the work that happens
  /// BEFORE a message exists to be pending.
  bool _attaching = false;
  String _providerLabel = 'Service Provider';
  bool _resolving = true;
  String? _errorMessage;

  /// Reaction subscription — scrolls to bottom when new messages arrive.
  ReactionDisposer? _listReaction;

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(_onFocusChange);
    _open();
  }

  Future<void> _open() async {
    setState(() {
      _resolving = true;
      _errorMessage = null;
    });

    // Load provider name in parallel with conversation resolution.
    _loadProviderName();

    try {
      final conv = await _store.openConversation(widget.jobOrderId);
      if (!mounted) return;
      if (conv == null) {
        setState(() {
          _resolving = false;
          _errorMessage =
              'This conversation is not available yet. It opens once a provider accepts the booking.';
        });
        return;
      }

      setState(() {
        _conversationId = conv.id;
        _resolving = false;
      });

      _track(const ConversationOpenedEvent(
        bookingStatusCategory: 'unknown',
        entrySource: 'chat_screen',
      ));

      // Mark as read on open.
      _store.markRead(conv.id);

      // Scroll to bottom after first render.
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      // React to new messages: scroll to bottom when list grows.
      final list = _store.messagesByConvId[conv.id];
      if (list != null) {
        _listReaction = reaction(
          (_) => list.length,
          (_) => WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Classified rather than flattened. Until the store stopped swallowing
      // them, none of these could reach this branch at all: every failure came
      // back as null and was reported as "it opens once a provider accepts the
      // booking", which is a claim about the booking, not about the request.
      setState(() {
        _resolving = false;
        _errorMessage = ErrorMessageMapper.forConversation(
          e.toString(),
          statusCode: e is ServanaApiException ? e.statusCode : null,
        );
      });
    }
  }

  /// The provider's name for the header, the empty state and the bubbles.
  ///
  /// Read from `GET /api/booking/:id/provider` — the endpoint the booking
  /// detail screen already uses. It used to come from
  /// `JonOrderRepository.getJobOrderEmployees`, which is
  /// `HttpBackend.getJobOrderEmployees`, which returns `[]` unconditionally in
  /// every release build. So this always fell through and the chat said
  /// "Service Provider" for a provider the booking screen could name.
  ///
  /// Still best-effort: a chat that works with an unnamed provider is better
  /// than one that refuses to open because a name lookup failed.
  Future<void> _loadProviderName() async {
    final bookingId = int.tryParse(widget.jobOrderId);
    if (bookingId == null) return;
    try {
      final response =
          await dpLocator<ServanaApiClient>().getBookingProvider(bookingId);
      final provider = BookingProviderProfile.fromResponse(response);
      final name = provider.name;
      if (!mounted || name == null || name.isEmpty) return;
      setState(() => _providerLabel = name);
    } catch (_) {
      // Leave the generic label. Naming the failure here would put an error
      // about a header on top of a conversation that opened perfectly well.
    }
  }

  void _onFocusChange() {
    if (_inputFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    }
  }

  @override
  void dispose() {
    _listReaction?.call();
    _inputFocusNode.removeListener(_onFocusChange);
    _inputFocusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    if (_conversationId != null) {
      _store.closeConversation(_conversationId!);
    }
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  /// Picks a photo, shrinks it, and sends it.
  ///
  /// Bounded twice on purpose. `pickImage` caps what is ever read into memory;
  /// `UploadCompressor` decides what actually goes on the wire. The endpoint
  /// takes a **data URI in a JSON body**, so base64 costs 4 bytes for every 3
  /// and `express.json`'s 10 MB limit is reached by a 7.5 MB file — the
  /// `chatPhoto` budget targets 800 KB, well clear of it and of nginx's 12 MB.
  ///
  /// Compression runs on a background isolate: it is real CPU work and the
  /// customer is looking at a conversation while it happens.
  Future<void> _pickAttachment() async {
    final conversationId = _conversationId;
    if (conversationId == null || _attaching) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    setState(() => _attaching = true);
    try {
      final original = await File(picked.path).readAsBytes();
      final prepared = await compute(_compressChatPhoto, original);
      if (!mounted) return;

      switch (prepared) {
        case UploadReady(:final bytes, :final contentType):
          // The caption is whatever is already typed, and the field is cleared
          // only once the send has been handed over — so a failed send leaves
          // the customer's words where they left them.
          final caption = _controller.text.trim();
          _controller.clear();
          await _store.sendAttachment(
            conversationId: conversationId,
            dataUri: 'data:$contentType;base64,${base64Encode(bytes)}',
            fileName: picked.name,
            mimeType: contentType,
            caption: caption,
          );
          if (mounted) _scrollToBottom();
        case UploadTooLarge(:final message):
          _showAttachmentProblem(message);
        case UploadUnsupported(:final message):
          _showAttachmentProblem(message);
      }
    } catch (e) {
      if (mounted) {
        _showAttachmentProblem(
          ErrorMessageMapper.forConversation(
            e.toString(),
            statusCode: e is ServanaApiException ? e.statusCode : null,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _attaching = false);
    }
  }

  void _showAttachmentProblem(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _conversationId == null) return;
    _controller.clear();
    await _store.sendMessage(
      conversationId: _conversationId!,
      body: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorPalette.secondaryBackground,
        surfaceTintColor: ColorPalette.secondaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Go back',
          icon: Icon(Icons.chevron_left,
              color: ColorPalette.primaryColorDark, size: 32),
        ),
        title: Text(
          widget.title ?? 'Message Provider',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            color: ColorPalette.secondaryText,
          ),
        ),
        actions: [
          // Connection indicator
          Observer(
            builder: (_) {
              final connected =
                  _store.messagesByConvId[_conversationId] != null;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Tooltip(
                  message: connected ? 'Connected' : 'Connecting…',
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: connected ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _ParticipantsBanner(providerLabel: _providerLabel),
          Expanded(child: _buildBody()),
          SafeArea(
            top: false,
            child: _buildComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_resolving) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _open,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_conversationId != null) {
          await _store.loadMoreMessages(_conversationId!);
        }
      },
      child: Observer(
        builder: (context) {
          final convId = _conversationId;
          if (convId == null) return const SizedBox.shrink();

          final messages = _store.messagesByConvId[convId] ?? ObservableList();
          final isLoading = _store.isLoadingByConvId[convId] ?? false;
          final bubbleMax = ServanaResponsive.chatBubbleMaxWidth(context);

          if (messages.isEmpty && !isLoading) {
            return _EmptyChat(providerLabel: _providerLabel);
          }

          return ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final m = messages[i];
              return _MessageBubble(
                message: m,
                providerLabel: _providerLabel,
                timeFormat: _timeFormat,
                bubbleMax: bubbleMax,
                onRetry: m.isFailed && m.clientMsgId != null && m.body != null
                    ? () => _store.retryMessage(
                          conversationId: convId,
                          clientMsgId: m.clientMsgId!,
                          body: m.body!,
                        )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        boxShadow: [
          BoxShadow(
            color: ColorPalette.shadow(.06),
            blurRadius: 12,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attach. Disabled with the send button, for the same reason: there
          // is nothing to attach to until the conversation resolves.
          Semantics(
            button: true,
            label: 'Attach a photo',
            child: IconButton(
              onPressed: _conversationId != null && !_attaching
                  ? _pickAttachment
                  : null,
              icon: _attaching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.add_photo_alternate_outlined,
                      color: _conversationId != null
                          ? ColorPalette.primaryColorDark
                          : ColorPalette.accentText,
                    ),
              tooltip: 'Attach a photo',
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'Message input',
              textField: true,
              child: TextField(
                controller: _controller,
                focusNode: _inputFocusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.secondaryText.withOpacity(.5),
                    fontWeight: FontWeight.w600,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: ColorPalette.secondaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: 'Send message',
            child: InkWell(
              onTap: _conversationId != null ? _send : null,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _conversationId != null
                      ? ColorPalette.primaryColor
                      : ColorPalette.primaryColor.withOpacity(.4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: ColorPalette.primaryButtonTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ParticipantsBanner extends StatelessWidget {
  const _ParticipantsBanner({required this.providerLabel});
  final String providerLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: ColorPalette.secondaryBackground,
      child: Semantics(
        label: 'Chat participants: Admin, $providerLabel, Client',
        child: ExcludeSemantics(
          child: Text(
            'In this chat: Admin • $providerLabel • Client',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.secondaryText.withOpacity(.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.providerLabel});
  final String providerLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No messages yet.\nSay hello to $providerLabel!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            color: ColorPalette.secondaryText.withOpacity(.55),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: ColorPalette.secondaryText.withOpacity(.4), size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.secondaryText.withOpacity(.65),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  color: ColorPalette.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.providerLabel,
    required this.timeFormat,
    required this.bubbleMax,
    this.onRetry,
  });

  final MessageModel message;
  final String providerLabel;
  final DateFormat timeFormat;
  final double bubbleMax;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // System messages are displayed differently — centred, no bubble.
    if (message.isSystem) {
      return _SystemMessage(body: message.body ?? '');
    }

    final isMe = message.isFromCustomer;
    final isDeleted = message.isDeleted;
    final body = isDeleted ? '(deleted)' : (message.body ?? '');

    final bubbleColor =
        isMe ? ColorPalette.primaryColor : ColorPalette.secondaryColor;
    final textColor =
        isMe ? ColorPalette.primaryText : ColorPalette.secondaryText;
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final senderLabel = isMe ? 'Client' : providerLabel;

    final statusIcon = _statusIcon(message.sendStatus, isMe);

    return Semantics(
      label: '$senderLabel at ${timeFormat.format(message.createdAt)}: $body'
          '${message.isPending ? ", sending" : ""}${message.isFailed ? ", failed to send" : ""}',
      child: Align(
        alignment: align,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          constraints: BoxConstraints(maxWidth: bubbleMax),
          decoration: BoxDecoration(
            color: bubbleColor.withOpacity(message.isPending ? .6 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                senderLabel,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  color: textColor.withOpacity(.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  color: isDeleted ? textColor.withOpacity(.5) : textColor,
                  fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeFormat.format(message.createdAt),
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: textColor.withOpacity(.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (statusIcon != null) ...[
                    const SizedBox(width: 4),
                    statusIcon,
                  ],
                ],
              ),
              if (message.isFailed && onRetry != null)
                Semantics(
                  label: 'Retry sending message',
                  button: true,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onRetry,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Tap to retry',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: Colors.red.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget? _statusIcon(MessageSendStatus status, bool isMe) {
    if (!isMe) return null;
    switch (status) {
      case MessageSendStatus.pending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white.withOpacity(.7),
          ),
        );
      case MessageSendStatus.failed:
        return Icon(Icons.error_outline, size: 13, color: Colors.red.shade300);
      case MessageSendStatus.sent:
        return null;
    }
  }
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.body});
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ColorPalette.secondaryText.withOpacity(.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 12,
              color: ColorPalette.secondaryText.withOpacity(.65),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs on a background isolate, so it must be top-level.
UploadPreparation _compressChatPhoto(Uint8List bytes) =>
    UploadCompressor.prepareImage(bytes, budget: UploadBudget.chatPhoto);
