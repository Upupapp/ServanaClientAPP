import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/responsive/servana_responsive.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/job_order/domain/repositories/jo_repo.dart';
import 'package:client/modules/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:client/modules/messaging/presentation/bloc/messaging_events.dart';
import 'package:client/modules/messaging/presentation/bloc/messaging_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  final _timeFormat = DateFormat('h:mm a');
  bool _hasAssignedProvider = false;
  String _providerLabel = "Service Provider";

  @override
  void initState() {
    super.initState();
    _loadAssignedProvider();
    // Scroll to the latest message when the keyboard opens so the thread
    // isn't obscured by the resized viewport (§94: no keyboard overlap in Chat).
    _inputFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_inputFocusNode.hasFocus) {
      // Small delay lets the keyboard animation complete before measuring.
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    }
  }

  Future<void> _loadAssignedProvider() async {
    try {
      final repo = dpLocator<JonOrderRepository>();
      final employees = await repo.getJobOrderEmployees(widget.jobOrderId);
      if (!mounted || employees.isEmpty) return;
      final name = employees.first.fullname.trim();
      setState(() {
        _hasAssignedProvider = true;
        _providerLabel = name.isNotEmpty ? name : "Service Provider";
      });
    } catch (_) {
      // Keep defaults when mock data isn't ready.
    }
  }

  @override
  void dispose() {
    _inputFocusNode.removeListener(_onFocusChange);
    _inputFocusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => dpLocator<MessagingBloc>()
        ..add(LoadBookingThreadEvent(widget.jobOrderId)),
      child: Builder(
        builder: (context) {
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
                widget.title ?? "Message Provider",
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w800,
                  color: ColorPalette.secondaryText,
                ),
              ),
            ),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: ColorPalette.secondaryBackground,
                  child: Text(
                    "In this chat: Admin •"
                    "${_hasAssignedProvider ? " $_providerLabel •" : ""} Client",
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: ColorPalette.secondaryText.withOpacity(.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: BlocConsumer<MessagingBloc, MessagingState>(
                    listener: (context, state) {
                      if (state is MessagingLoaded) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });
                      }
                    },
                    builder: (context, state) {
                      if (state is MessagingLoading ||
                          state is MessagingInitial) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is MessagingError) {
                        return Center(
                          child: Text(
                            "Failed to load messages",
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              color: ColorPalette.secondaryText.withOpacity(.7),
                            ),
                          ),
                        );
                      }
                      final loaded = state as MessagingLoaded;
                      final messages = loaded.messages;
                      // Compute once per rebuild — 78% of screen, clamped to
                      // [240, 320] dp so narrow phones and wide tablets both
                      // get readable bubbles (§80: responsive chat bubble width).
                      final bubbleMax =
                          ServanaResponsive.chatBubbleMaxWidth(context);
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          final isMe = m.isFromCustomer;
                          final bubbleColor = isMe
                              ? ColorPalette.primaryColor
                              : ColorPalette.secondaryColor;
                          final textColor = isMe
                              ? ColorPalette.primaryText
                              : ColorPalette.secondaryText;
                          final align = isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft;
                          return Align(
                            alignment: align,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              constraints: BoxConstraints(maxWidth: bubbleMax),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMe ? "Client" : _providerLabel,
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
                                    m.text,
                                    style: TextStyle(
                                      fontFamily: FontPalette.primaryFontFamily,
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _timeFormat.format(m.createdAt),
                                    style: TextStyle(
                                      fontFamily: FontPalette.primaryFontFamily,
                                      color: textColor.withOpacity(.75),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: ColorPalette.secondaryBackground,
                      boxShadow: [
                        BoxShadow(
                          color: ColorPalette.shadow(.06),
                          blurRadius: 12,
                          offset: const Offset(0, -6),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _inputFocusNode,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: "Message…",
                              hintStyle: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                color:
                                    ColorPalette.secondaryText.withOpacity(.5),
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
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            final text = _controller.text.trim();
                            if (text.isEmpty) return;
                            _controller.clear();
                            context.read<MessagingBloc>().add(
                                  SendBookingMessageEvent(
                                    jobOrderId: widget.jobOrderId,
                                    text: text,
                                  ),
                                );
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: ColorPalette.primaryColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.send_rounded,
                              color: ColorPalette.primaryButtonTextColor,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
