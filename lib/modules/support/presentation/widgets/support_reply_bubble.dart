import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/support/domain/support_ticket.dart';
import 'package:flutter/material.dart';

class SupportReplyBubble extends StatelessWidget {
  const SupportReplyBubble({
    super.key,
    required this.reply,
    this.onRetry,
    this.onDeleteFailed,
  });

  final SupportReply reply;
  final VoidCallback? onRetry;
  final VoidCallback? onDeleteFailed;

  bool get _isCustomer => reply.author == SupportReplyAuthor.customer;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    return Semantics(
      label: '${_isCustomer ? "You" : "Servana Support"}: ${reply.body}${reply.isPending ? ", sending" : ""}${reply.isFailed ? ", failed to send" : ""}',
      child: Align(
        alignment: _isCustomer ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: _isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!_isCustomer)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                  child: Text(
                    'Servana Support',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.primaryColorDark,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _bubbleColor(),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(_isCustomer ? 16 : 4),
                    bottomRight: Radius.circular(_isCustomer ? 4 : 16),
                  ),
                  border: reply.isFailed
                      ? Border.all(color: ColorPalette.danger.withOpacity(.4))
                      : null,
                ),
                child: Text(
                  reply.body,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 14,
                    color: _isCustomer ? Colors.white : ColorPalette.secondaryText,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (reply.createdAt != null)
                    Text(
                      _formatTime(reply.createdAt!),
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 10,
                        color: ColorPalette.accentText.withOpacity(.6),
                      ),
                    ),
                  if (reply.isPending) ...[
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 10, height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: ColorPalette.accentText.withOpacity(.5),
                      ),
                    ),
                  ],
                  if (reply.isFailed) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.error_outline_rounded, size: 12, color: ColorPalette.danger),
                    const SizedBox(width: 2),
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 11,
                          color: ColorPalette.primaryColorDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onDeleteFailed,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: ColorPalette.danger,
                      ),
                      child: Text(
                        'Discard',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 11,
                          color: ColorPalette.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _bubbleColor() {
    if (reply.isFailed) return ColorPalette.danger.withOpacity(.08);
    if (reply.isPending) return ColorPalette.primaryColorDark.withOpacity(.6);
    if (_isCustomer) return ColorPalette.primaryColorDark;
    return ColorPalette.secondaryBackground;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
