class ProviderReviewResponse {
  const ProviderReviewResponse({
    required this.responseId,
    required this.body,
    required this.moderationStatus,
    this.createdAt,
  });

  final String responseId;
  final String body;
  final String moderationStatus;
  final DateTime? createdAt;

  factory ProviderReviewResponse.fromMap(Map<String, dynamic> m) =>
      ProviderReviewResponse(
        responseId:       m['responseId'] as String? ?? '',
        body:             m['body'] as String? ?? '',
        moderationStatus: m['moderationStatus'] as String? ?? 'NOT_REQUIRED',
        createdAt:        m['createdAt'] != null
                              ? DateTime.tryParse(m['createdAt'].toString())
                              : null,
      );
}
