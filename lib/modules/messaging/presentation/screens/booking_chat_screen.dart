import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/responsive/servana_responsive.dart';
import 'package:client/modules/job_order/domain/repositories/jo_repo.dart';
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
      setState(() {
        _resolving = false;
        _errorMessage = 'Could not load messages. Pull down to try again.';
      });
    }
  }

  Future<void> _loadProviderName() async {
    try {
      final repo = dpLocator<JonOrderRepository>();
      final employees = await repo.getJobOrderEmployees(widget.jobOrderId);
      if (!mounted || employees.isEmpty) return;
      final name = employees.first.fullname.trim();
      if (name.isNotEmpty) setState(() => _providerLabel = name);
    } catch (_) {}
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
              final connected = _store.messagesByConvId[_conversationId] != null;
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
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
    final align =
        isMe ? Alignment.centerRight : Alignment.centerLeft;
    final senderLabel = isMe ? 'Client' : providerLabel;

    final statusIcon = _statusIcon(message.sendStatus, isMe);

    return Semantics(
      label:
          '$senderLabel at ${timeFormat.format(message.createdAt)}: $body'
          '${message.isPending ? ", sending" : ""}${message.isFailed ? ", failed to send" : ""}',
      child: Align(
        alignment: align,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          constraints: BoxConstraints(maxWidth: bubbleMax),
          decoration: BoxDecoration(
            color: bubbleColor.withOpacity(message.isPending ? .6 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
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
                  color: isDeleted
                      ? textColor.withOpacity(.5)
                      : textColor,
                  fontStyle:
                      isDeleted ? FontStyle.italic : FontStyle.normal,
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
                GestureDetector(
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
