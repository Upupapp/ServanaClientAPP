import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:flutter/material.dart';

class SupportReplyComposer extends StatefulWidget {
  const SupportReplyComposer({
    super.key,
    required this.onSend,
    this.isSending = false,
    this.enabled = true,
  });

  final Future<void> Function(String message) onSend;
  final bool isSending;
  final bool enabled;

  @override
  State<SupportReplyComposer> createState() => _SupportReplyComposerState();
}

class _SupportReplyComposerState extends State<SupportReplyComposer> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final v = _ctrl.text.trim().isNotEmpty;
      if (v != _hasText) setState(() => _hasText = v);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.isSending) return;
    _ctrl.clear();
    setState(() => _hasText = false);
    await widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: ColorPalette.primaryBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Type your reply',
                    child: TextField(
                      controller: _ctrl,
                      enabled: widget.enabled && !widget.isSending,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 14,
                        color: ColorPalette.secondaryText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Reply to Servana Support…',
                        hintStyle: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 14,
                          color: ColorPalette.accentText.withOpacity(.5),
                        ),
                        filled: true,
                        fillColor: ColorPalette.secondaryBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: ColorPalette.border(.3), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: ColorPalette.border(.3), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: ColorPalette.primaryColorDark, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'Send reply',
                  enabled: _hasText && !widget.isSending,
                  child: AnimatedOpacity(
                    opacity: _hasText && !widget.isSending ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 150),
                    child: GestureDetector(
                      onTap: _hasText && !widget.isSending ? _send : null,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ColorPalette.primaryColorDark,
                          shape: BoxShape.circle,
                        ),
                        child: widget.isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
