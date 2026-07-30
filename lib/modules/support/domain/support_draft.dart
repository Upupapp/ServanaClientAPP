import 'package:client/modules/support/domain/support_ticket_category.dart';

class SupportDraft {
  final String draftId;
  final SupportTicketCategory category;
  final String? bookingId;
  final String? bookingLabel;
  final String subject;
  final String description;
  final Map<String, String> structuredAnswers;
  final DateTime savedAt;

  const SupportDraft({
    required this.draftId,
    required this.category,
    this.bookingId,
    this.bookingLabel,
    required this.subject,
    required this.description,
    required this.structuredAnswers,
    required this.savedAt,
  });

  SupportDraft copyWith({
    SupportTicketCategory? category,
    String? bookingId,
    String? bookingLabel,
    String? subject,
    String? description,
    Map<String, String>? structuredAnswers,
  }) =>
      SupportDraft(
        draftId: draftId,
        category: category ?? this.category,
        bookingId: bookingId ?? this.bookingId,
        bookingLabel: bookingLabel ?? this.bookingLabel,
        subject: subject ?? this.subject,
        description: description ?? this.description,
        structuredAnswers: structuredAnswers ?? this.structuredAnswers,
        savedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'draftId': draftId,
        'category': category.apiKey,
        'bookingId': bookingId,
        'bookingLabel': bookingLabel,
        'subject': subject,
        'description': description,
        'structuredAnswers': structuredAnswers,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SupportDraft.fromJson(Map<String, dynamic> m) => SupportDraft(
        draftId: m['draftId'] as String,
        category: SupportTicketCategory.fromString(m['category'] as String?),
        bookingId: m['bookingId'] as String?,
        bookingLabel: m['bookingLabel'] as String?,
        subject: (m['subject'] as String?) ?? '',
        description: (m['description'] as String?) ?? '',
        structuredAnswers: Map<String, String>.from(
          (m['structuredAnswers'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, v?.toString() ?? ''),
          ),
        ),
        savedAt:
            DateTime.tryParse(m['savedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}
