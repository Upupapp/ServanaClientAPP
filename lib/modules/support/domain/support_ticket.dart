import 'package:client/modules/support/domain/support_ticket_category.dart';
import 'package:client/modules/support/domain/support_ticket_status.dart';

class SupportTicket {
  final String ticketKey;
  final SupportTicketCategory category;
  final SupportTicketStatus status;
  final String title;
  final String safeSummary;
  final String? bookingId;
  final int unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool canReply;
  final bool canClose;
  final bool canReopen;
  final List<SupportReply> replies;

  const SupportTicket({
    required this.ticketKey,
    required this.category,
    required this.status,
    required this.title,
    required this.safeSummary,
    this.bookingId,
    this.unreadCount = 0,
    this.createdAt,
    this.updatedAt,
    this.canReply = false,
    this.canClose = false,
    this.canReopen = false,
    this.replies = const [],
  });

  SupportTicket copyWith({
    SupportTicketStatus? status,
    int? unreadCount,
    bool? canReply,
    bool? canClose,
    bool? canReopen,
    List<SupportReply>? replies,
    DateTime? updatedAt,
  }) =>
      SupportTicket(
        ticketKey: ticketKey,
        category: category,
        status: status ?? this.status,
        title: title,
        safeSummary: safeSummary,
        bookingId: bookingId,
        unreadCount: unreadCount ?? this.unreadCount,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        canReply: canReply ?? this.canReply,
        canClose: canClose ?? this.canClose,
        canReopen: canReopen ?? this.canReopen,
        replies: replies ?? this.replies,
      );

  String get shortRef => ticketKey.length > 8
      ? ticketKey.substring(0, 8).toUpperCase()
      : ticketKey.toUpperCase();
}

// ─────────────────────────────────────────────────────────────────────────────

enum SupportReplyAuthor { customer, support, system, unknown }

class SupportReply {
  final String replyId;
  final String ticketKey;
  final SupportReplyAuthor author;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  // Optimistic/local state
  final bool isPending;
  final bool isFailed;
  final String? clientReplyId;

  const SupportReply({
    required this.replyId,
    required this.ticketKey,
    required this.author,
    required this.body,
    this.isRead = false,
    this.createdAt,
    this.isPending = false,
    this.isFailed = false,
    this.clientReplyId,
  });

  SupportReply copyWith({bool? isPending, bool? isFailed, String? replyId}) =>
      SupportReply(
        replyId: replyId ?? this.replyId,
        ticketKey: ticketKey,
        author: author,
        body: body,
        isRead: isRead,
        createdAt: createdAt,
        isPending: isPending ?? this.isPending,
        isFailed: isFailed ?? this.isFailed,
        clientReplyId: clientReplyId,
      );

  static SupportReplyAuthor _authorFrom(String? s) {
    switch (s) {
      case 'customer':
        return SupportReplyAuthor.customer;
      case 'support':
        return SupportReplyAuthor.support;
      case 'system':
        return SupportReplyAuthor.system;
      default:
        return SupportReplyAuthor.unknown;
    }
  }

  factory SupportReply.fromMap(Map<String, dynamic> m, String ticketKey) =>
      SupportReply(
        replyId: m['id']?.toString() ?? '',
        ticketKey: ticketKey,
        author: _authorFrom(m['senderType'] as String?),
        body: (m['safeBody'] as String?) ?? '',
        isRead: (m['isRead'] as bool?) ?? false,
        createdAt: m['createdAt'] != null
            ? DateTime.tryParse(m['createdAt'].toString())
            : null,
      );

  factory SupportReply.optimistic({
    required String ticketKey,
    required String body,
    required String clientReplyId,
  }) =>
      SupportReply(
        replyId: '',
        ticketKey: ticketKey,
        author: SupportReplyAuthor.customer,
        body: body,
        isPending: true,
        clientReplyId: clientReplyId,
        createdAt: DateTime.now(),
      );
}
